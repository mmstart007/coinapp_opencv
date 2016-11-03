//
//  CoinTypeTemplate.swift
//  CoinApp
//
//  Created by Maxim on 10/19/16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit

struct CoinTypeTemplate {

    var coinTypeName: String = ""
    var coinTypeShortName: String = ""
    var templateImage: String = ""
    var rotateCount: Int = 1
    var featuredX: Float = 0
    var featuredY: Float = 0
    var featuredW: Float = 0
    var featuredH: Float = 0
    
    static func readCoinTypeTemplates() -> Array<CoinTypeTemplate> {
        var arrayCoinTypeTemplates = Array<CoinTypeTemplate>()
        
        var coinTypesDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "CoinTypes", ofType: "plist") {
            coinTypesDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = coinTypesDict {
            let arrayCoinTypeObjects: Array<NSDictionary> = dict.object(forKey: "Templates") as! Array<NSDictionary>
            for coinTypeObject: NSDictionary in arrayCoinTypeObjects {
                var coinTemplate: CoinTypeTemplate = CoinTypeTemplate()
                coinTemplate.coinTypeName = coinTypeObject.object(forKey: "CoinTypeName") as! String
                coinTemplate.coinTypeShortName = coinTypeObject.object(forKey: "CoinTypeShortName") as! String
                coinTemplate.templateImage = coinTypeObject.object(forKey: "TemplateImage") as! String
                coinTemplate.rotateCount = (coinTypeObject.object(forKey: "RotateCount") as! NSNumber).intValue
                coinTemplate.featuredX = (coinTypeObject.object(forKey: "FeaturedX") as! NSNumber).floatValue
                coinTemplate.featuredY = (coinTypeObject.object(forKey: "FeaturedY") as! NSNumber).floatValue
                coinTemplate.featuredW = (coinTypeObject.object(forKey: "FeaturedW") as! NSNumber).floatValue
                coinTemplate.featuredH = (coinTypeObject.object(forKey: "FeaturedH") as! NSNumber).floatValue
                arrayCoinTypeTemplates.append(coinTemplate)
            }
        }
        
        return arrayCoinTypeTemplates
    }
    
}
