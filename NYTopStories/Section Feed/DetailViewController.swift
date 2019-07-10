//
//  ViewController.swift
//  NYTopStories
//
//  Created by Avinash on 08/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import UIKit
import SafariServices

class DetailViewController: UIViewController {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var abstractLabel: UILabel!
    @IBOutlet weak var publishDateLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    var result = Results()
    
    override func viewDidLoad() {
        self.title = result.section
        titleLabel.text = "\t" + (result.title ?? "")
        abstractLabel.text = "\t" + (result.abstract ?? "")
        publishDateLabel.text = "Publish on: " + (result.getPublishedDate() ?? "")
        authorLabel.text = result.byline
        DispatchQueue.global().async {
            let url = self.result.multimedia?.filter { $0.format == "mediumThreeByTwo210"}.first?.url
            self.coverImageView?.sd_setImage(with: url, placeholderImage: nil, options: .retryFailed, completed: nil)
        }
        
    }
    /// Opens up the article in Safari View Controller
    ///
    /// - Parameter sender: UIButton
    @IBAction func readStroyButtonPressed(_ sender: UIButton) {
        if let url = result.url {
            let svc = SFSafariViewController(url: url)
            self.present(svc, animated: true, completion: nil)
        }
    }
}

