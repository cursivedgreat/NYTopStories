//
//  ListCell.swift
//  NYTopStories
//
//  Created by Avinash on 09/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var storyLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
