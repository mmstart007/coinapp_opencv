//
//  CoinRecogViewController.swift
//  CoinApp
//
//  Created by Maxim on 10/19/16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit

class CoinRecogViewController: UIViewController, CoinDetailViewControllerDelegate {

    @IBOutlet var cameraPreview: UIView!
    
    var coinSession: CoinDetectSession? = nil
    
    fileprivate var observer1: AnyObject? = nil
    fileprivate var observer2: AnyObject? = nil
    fileprivate var observer3: AnyObject? = nil
    fileprivate var observer4: AnyObject? = nil
    fileprivate var observer5: AnyObject? = nil
    fileprivate var observer6: AnyObject? = nil
    
    var viewIsVisibleFirstTime = true
    
    var coinTypeTemplates: Array<CoinTypeTemplate>? = nil
    
    var recognizedCoinType: Int = -1
    var processedCoinImage: UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addObservers()
        
        coinSession = CoinDetectSession()
        coinSession!.setDebug(false)
        coinSession!.setPreviewSize(size: self.view.bounds.size)
        
        coinTypeTemplates = CoinTypeTemplate.readCoinTypeTemplates()
        coinSession!.setCoinTypeTemplates(coinTypeTemplates!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewIsVisibleFirstTime == true {
            viewIsVisibleFirstTime = false
            return
        }
        
        self.addObservers()
        
        if self.coinSession!.sessionIsConfigured() {
            self.coinSession?.startSession()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.removeObservers()
        
        if self.coinSession!.sessionIsConfigured() {
            self.coinSession?.stopSession()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setPreviewLayoutAndStartSession() -> Void {
        let previewLayer = coinSession!.getPreviewLayer()
        previewLayer.frame = cameraPreview.layer.bounds
        cameraPreview.layer.addSublayer(previewLayer)
        coinSession!.setPreviewVideoOrientation(.portrait)
        coinSession!.startSession()
    }
    
    func addObservers() -> Void {
        observer1 = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: CoinDetectSession.kNotification_SessionInitialized), object: nil, queue: nil) {
            (notif: Notification!) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.setPreviewLayoutAndStartSession()
            })
        }
        observer2 = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: CoinDetectSession.kNotification_CoinAppeared), object: nil, queue: nil) {
            (notif: Notification!) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processedCoinImage = notif.userInfo![CoinDetectSession.kProcessedImageKey] as? UIImage
                self.recognizedCoinType = (notif.userInfo![CoinDetectSession.kCoinTypeKey] as! NSNumber).intValue
                self.performSegue(withIdentifier: "CoinRecogToCoinDetail", sender: nil)
            })
        }
        observer3 = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: CoinDetectSession.kNotification_CoinDisappeared), object: nil, queue: nil) {
            (notif: Notification!) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                print("Coin disappeared!")
            })
        }
        observer4 = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { (notif: Notification!) -> Void in
            if self.coinSession!.sessionIsConfigured() {
                self.coinSession!.stopSession()
            }
        }
        observer5 = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) { (notif: Notification!) -> Void in
            if self.coinSession!.sessionIsConfigured() {
                self.coinSession!.startSession()
            }
        }
        observer6 = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: CoinDetectSession.kNotification_CameraNotAllowed), object: nil, queue: nil) {
            (notif: Notification!) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                let alertController = UIAlertController(title: "CoinApp", message: "This application does not have permission to use camera. Please update your privacy settings.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            })
        }
    }

    func removeObservers() -> Void {
        NotificationCenter.default.removeObserver(observer1!)
        NotificationCenter.default.removeObserver(observer2!)
        NotificationCenter.default.removeObserver(observer3!)
        NotificationCenter.default.removeObserver(observer4!)
        NotificationCenter.default.removeObserver(observer5!)
        NotificationCenter.default.removeObserver(observer6!)
    }
    
    @IBAction func handlePreviewTap(_ sender: UITapGestureRecognizer) {
        if coinSession!.sessionIsRunning() == false {
            return
        }
        print("handlePreviewTap")
        let touchPoint = sender.location(in: sender.view)
        coinSession!.focusAndExposeAtPoint(touchPoint)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CoinRecogToCoinDetail" {
            let detailVC: CoinDetailViewController = segue.destination as! CoinDetailViewController
            detailVC.coinTypeName = coinTypeNameForTypeIndex(index: recognizedCoinType)
            detailVC.coinSnippet = processedCoinImage
            detailVC.delegate = self
        }
    }
    
    func coinTypeNameForTypeIndex(index: Int) -> String {
        if coinTypeTemplates == nil {
            return ""
        }
        if (index >= (coinTypeTemplates?.count)!) {
            return ""
        }
        let template: CoinTypeTemplate = coinTypeTemplates![index]
        return template.coinTypeName
    }
    
    func detailDismissed() -> Void {
        self.dismiss(animated: true, completion: nil)
    }
    
}

