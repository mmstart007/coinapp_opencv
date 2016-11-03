//
//  CoinDetailViewController.swift
//  CoinApp
//
//  Created by Maxim on 10/21/16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit

protocol CoinDetailViewControllerDelegate {
    func detailDismissed() -> Void
}

class CoinDetailViewController: UIViewController {
    
    @IBOutlet var labelCoinType: UILabel!
    @IBOutlet var imageCoinSnippet: UIImageView!
    
    var coinTypeName: String? = nil
    var coinSnippet: UIImage? = nil
    
    var delegate: CoinDetailViewControllerDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelCoinType.text = coinTypeName
        imageCoinSnippet.image = coinSnippet
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onBack(_ sender: AnyObject) {
        delegate?.detailDismissed()
    }
    
}
