//
//  CoinDetectSession.swift
//  CoinApp
//
//  Created by Maxim on 10/19/16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import Foundation
import AVFoundation

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}

class CoinDetectSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    static let kNotification_SessionInitialized = "Notification_SessionInitialized"
    static let kNotification_CameraNotAllowed = "Notification_CameraNotAllowed"
    static let kNotification_DebugSession = "Notification_DebugSession"
    static let kNotification_CoinAppeared = "Notification_CoinAppeared"
    static let kNotification_CoinDisappeared = "Notification_CoinDisappeared"
    
    static let kProcessedImageKey: NSString = "ProcessedImage"
    static let kMatchedBoxKey: NSString = "MatchedBox"
    static let kCoinTypeKey: NSString = "CoinType"
    
    fileprivate var isConfigured: Bool! = false
    fileprivate var isDebug: Bool! = false
    
    fileprivate var session: AVCaptureSession!
    fileprivate var sessionQueue: DispatchQueue!
    fileprivate var processQueue: DispatchQueue!
    fileprivate var videoDeviceInput: AVCaptureDeviceInput!
    fileprivate var videoDeviceOutput: AVCaptureVideoDataOutput!
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!
    fileprivate var runtimeErrorHandlingObserver: AnyObject?
    
    fileprivate var videoOrientation: AVCaptureVideoOrientation! = .portrait
    // Default to iPhone 5 screen size
    fileprivate var previewSize: CGSize! = CGSize(width: 320, height: 568)
    
    fileprivate var lastFrameAcceptedTime: Double! = 0
    fileprivate var frameRate: Double! = 16.0
    
    fileprivate var coinTypeTemplates: Array<CoinTypeTemplate>? = nil
    fileprivate let coeffThreshold: Double = 20000000.0
    fileprivate var isCoinExist: Bool = false
    
    class func deviceWithMediaType(_ mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: mediaType as String)
        var captureDevice: AVCaptureDevice? = nil
        
        for object:Any in devices! {
            let device = object as! AVCaptureDevice
            if (device.position == position) {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    override init() {
        super.init();
        
        isConfigured = false
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPreset640x480
        
        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        sessionQueue = DispatchQueue(label: "CameraSessionController Session", attributes: [])
        processQueue = DispatchQueue(label: "CameraSessionController Session", attributes: [])
        
        authorizeCamera();
        
        sessionQueue.async(execute: {
            self.session.beginConfiguration()
            if self.addVideoInput() == false {
                self.session.commitConfiguration()
                return
            }
            self.addVideoOutput()
            self.session.commitConfiguration()
            
            self.isConfigured = true
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: CoinDetectSession.kNotification_SessionInitialized), object: nil)
        })
    }
    
    func destroySession() -> Void {
        if session.isRunning {
            self.stopSession()
        }
        for element in session.outputs {
            session.removeOutput(element as! AVCaptureOutput)
        }
        for element in session.inputs {
            session.removeInput(element as! AVCaptureInput)
        }
    }
    
    func authorizeCamera() {
        // Check the authorization status
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { granted in
                if !granted {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: CoinDetectSession.kNotification_CameraNotAllowed), object: nil)
                }
                self.sessionQueue.resume()
            })
            break;
            
        default:
            NotificationCenter.default.post(name: Notification.Name(rawValue: CoinDetectSession.kNotification_CameraNotAllowed), object: nil)
        }
    }
    
    func addVideoInput() -> Bool {
        // Add video input
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if #available(iOS 10.0, *) {
                if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back) {
                    defaultVideoDevice = dualCameraDevice
                }
                else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                    defaultVideoDevice = backCameraDevice
                }
                else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                    defaultVideoDevice = frontCameraDevice
                }
            } else {
                defaultVideoDevice = CoinDetectSession.deviceWithMediaType(AVMediaTypeVideo as NSString, position: .back)
            }
            
            videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            }
            else {
                print("Could not add video device input to the session")
                return false
            }
        }
        catch {
            print("Could not create video device input: \(error)")
            return false
        }
        
        return true
    }
    
    func addVideoOutput() {
        
        videoDeviceOutput = AVCaptureVideoDataOutput()
        videoDeviceOutput.videoSettings = NSDictionary(object: Int(kCVPixelFormatType_32BGRA), forKey:kCVPixelBufferPixelFormatTypeKey as String as String as NSCopying) as! [AnyHashable: Any]
        
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        videoDeviceOutput.setSampleBufferDelegate(self, queue: processQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
    }
    
    func startSession() {
        sessionQueue.async(execute: {
            let weakSelf: CoinDetectSession? = self
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.sessionQueue, queue: nil, using: {
                (note: Notification!) -> Void in
                
                let strongSelf: CoinDetectSession = weakSelf!
                
                strongSelf.sessionQueue.async(execute: {
                    strongSelf.session.startRunning()
                })
            })
            
            self.session.startRunning()
        })
    }
    
    func stopSession() {
        sessionQueue.async(execute: {
            self.session.stopRunning()
            NotificationCenter.default.removeObserver(self.runtimeErrorHandlingObserver!)
        })
    }
    
    func focusAndExposeAtPoint(_ point: CGPoint) {
        let devicePoint = self.previewLayer.captureDevicePointOfInterest(for: point)
        sessionQueue.async { [unowned self] in
            if let device = self.videoDeviceInput.device {
                do {
                    try device.lockForConfiguration()
                    
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                        device.focusPointOfInterest = devicePoint
                        device.focusMode = .autoFocus
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                        device.exposurePointOfInterest = devicePoint
                        device.exposureMode = .autoExpose
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = true
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if sampleBuffer == nil {
            return
        }
        let currMillis = Date().timeIntervalSince1970 * 1000
        let millisPerFrame = 1000.0 / frameRate
        if (currMillis - lastFrameAcceptedTime) < millisPerFrame {
            return
        }
        if (videoDeviceInput.device.isAdjustingFocus == true ||
            videoDeviceInput.device.isAdjustingExposure == true) {
            return
        }
        
        lastFrameAcceptedTime = currMillis
        
        self.processFrame(sampleBuffer)
    }
    
    func sessionIsConfigured() -> Bool {
        return isConfigured
    }
    
    func sessionIsRunning() -> Bool {
        return (self.isConfigured && self.session.isRunning)
    }
    
    func setPreviewVideoOrientation(_ orientation: AVCaptureVideoOrientation!) -> Void {
        videoOrientation = orientation
        if isConfigured == false {
            return
        }
        if previewLayer.connection.isVideoOrientationSupported == true {
            previewLayer.connection.videoOrientation = orientation
        }
    }
    
    func setPreviewSize(size: CGSize) -> Void {
        previewSize = size
        if (previewSize.width <= 0 || previewSize.height <= 0) {
            previewSize = CGSize(width: 320, height: 568)
        }
    }
    
    func setFrameRate(_ rate: Double) -> Void {
        if rate < 1 {
            frameRate = 16.0
        } else {
            frameRate = rate
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        return previewLayer
    }
    
    func getVideoDimension() -> CGSize {
        if isConfigured == false {
            return CGSize(width: 0, height: 0)
        }
        
        let port: AVCaptureInputPort = videoDeviceInput.ports[0] as! AVCaptureInputPort
        let formatDescription: CMFormatDescription = port.formatDescription
        let dimensions: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        
        return CGSize(width: Double(dimensions.width), height: Double(dimensions.height))
    }
    
    func setDebug(_ debug: Bool!) -> Void {
        isDebug = debug
    }
    
    func setCoinTypeTemplates(_ coinTemplates: Array<CoinTypeTemplate>) -> Void {
        coinTypeTemplates = coinTemplates
        if (coinTypeTemplates != nil) {
            var templates = Array<[String : AnyObject]>()
            for template in coinTypeTemplates! {
                var templateDict = [String : AnyObject]()
                templateDict["FileName"] = template.templateImage as AnyObject?
                templateDict["RotateCount"] = NSNumber(value: template.rotateCount) as AnyObject?
                templateDict["FeaturedX"] = NSNumber(value: template.featuredX) as AnyObject?
                templateDict["FeaturedY"] = NSNumber(value: template.featuredY) as AnyObject?
                templateDict["FeaturedW"] = NSNumber(value: template.featuredW) as AnyObject?
                templateDict["FeaturedH"] = NSNumber(value: template.featuredH) as AnyObject?
                templates.append(templateDict)
            }
            OpenCVWrapper.setTemplates(templates)
        } else {
            OpenCVWrapper.setTemplates(nil)
        }
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer!) -> Void {
        // Check if the template is there
        if coinTypeTemplates == nil || coinTypeTemplates?.count <= 0 {
            return
        }
        // Fix orientation issue
        var image = imageFromSampleBuffer(sampleBuffer)
        if videoOrientation == AVCaptureVideoOrientation.landscapeLeft {
            image = image.rotate(by: CGFloat(M_PI))
        } else if (videoOrientation == AVCaptureVideoOrientation.portrait) {
            image = image.rotate(by: CGFloat(M_PI) / 2.0)
        } else if (videoOrientation == AVCaptureVideoOrientation.portraitUpsideDown) {
            image = image.rotate(by: CGFloat(M_PI) * 3.0 / 2.0)
        }
        
        // Get interested region
        let scaleX = previewSize.width / image.size.width;
        let scaleY = previewSize.height / image.size.height;
        let scale = scaleX > scaleY ? scaleX : scaleY;
        let cropSW = floor((previewSize.width < previewSize.height ? previewSize.width : previewSize.height) * 2.0 / 3.0)
        let cropVW = cropSW / scale;
        let rcCrop: CGRect = CGRect(x: (image.size.width - cropVW) / 2.0,
                                    y: (image.size.height - cropVW) / 2.0,
                                    width: cropVW, height: cropVW)
        // Crop image to the interested region
        image = image.crop(rcCrop)
        image = OpenCVWrapper.sharpenImage(image)
        image = OpenCVWrapper.sharpenImage(image)
        image = OpenCVWrapper.sharpenImage(image)
        
        var coinExist: Bool = false
        var coinType: Int = -1
        var coinRegion: CGRect = .zero
        var coinRecognizedImage: UIImage? = nil
        
        var debugDict: [AnyHashable: Any] = [AnyHashable: Any]()
        
        let circleInfo = OpenCVWrapper.detectCircle(image)
        if circleInfo != nil {
            let cx: CGFloat = CGFloat((circleInfo?["X"] as! NSNumber).floatValue)
            let cy: CGFloat = CGFloat((circleInfo?["Y"] as! NSNumber).floatValue)
            let rad: CGFloat = CGFloat((circleInfo?["R"] as! NSNumber).floatValue)
            let circleX = (cx - rad) < 0 ? 0 : (cx - rad);
            let circleY = (cy - rad) < 0 ? 0 : (cy - rad);
            let circleImageRect: CGRect = CGRect(x: circleX, y: circleY, width: rad * 2.0, height: rad * 2.0)
            var circleImage = image.crop(circleImageRect)
            coinRecognizedImage = circleImage
//            circleImage = circleImage?.scaled(to: CGSize(width: 160.0, height: 160.0))
            circleImage = circleImage?.scaled(to: CGSize(width: 320.0, height: 320.0))
            circleImage = circleImage?.applyMask()
            
            let matchResultDict = OpenCVWrapper.doTemplateMatch(circleImage)
            if matchResultDict != nil {
                let coeffNum = matchResultDict?["COEFF"] as! NSNumber
                let coeff = coeffNum.doubleValue
                let templateIndexNum = matchResultDict?["TYPE_INDEX"] as! NSNumber
                let templateIndex = templateIndexNum.intValue
                let matchedRectVal = matchResultDict?["RECT"] as! NSValue
                let matchedRect = matchedRectVal.cgRectValue
                
                if (templateIndex > -1 && coeff > DBL_MIN &&
                    matchedRect.size.width > 0 && matchedRect.size.height > 0) {
                
                    print("COEFF = \(coeff)")
                    if coeff > coeffThreshold {
                        coinRegion = CGRect(x: rcCrop.origin.x + circleX,
                                            y: rcCrop.origin.y + circleY,
                                            width: rad * 2.0, height: rad * 2.0)
                        coinExist = true
                        coinType = templateIndex		
                    }
                }
            }
        }
        
        debugDict[CoinDetectSession.kMatchedBoxKey] = NSValue(cgRect: coinRegion)
        
        if isDebug == true {
            NotificationCenter.default.post(name: Notification.Name(rawValue: CoinDetectSession.kNotification_DebugSession), object: nil, userInfo: debugDict as [AnyHashable: Any])
        }
        
        if coinExist != isCoinExist {
            if coinExist == true {
                var resultDict: [AnyHashable: Any] = [AnyHashable: Any]()
                resultDict[CoinDetectSession.kMatchedBoxKey] = NSValue(cgRect: coinRegion)
                resultDict[CoinDetectSession.kProcessedImageKey] = coinRecognizedImage
                resultDict[CoinDetectSession.kCoinTypeKey] = NSNumber(integerLiteral: coinType)
                NotificationCenter.default.post(name: Notification.Name(rawValue: CoinDetectSession.kNotification_CoinAppeared), object: nil, userInfo: resultDict as [AnyHashable: Any])
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: CoinDetectSession.kNotification_CoinDisappeared), object: nil)
            }
            isCoinExist = coinExist
        }
        if isCoinExist {
            print(isCoinExist, coinType)
        }
    }
    
    func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer!) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: (CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue))
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo:bitmapInfo.rawValue)
        let quartzImage = context?.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let image = UIImage(cgImage: quartzImage!)
        
        return image
    }
    
}
