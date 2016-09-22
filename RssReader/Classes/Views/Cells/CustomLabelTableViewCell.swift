//
//  CustomLabelTableViewCell.swift
//  RssReader
//
//  Created by Simon Ng on 4/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

class CustomLabelTableViewCell: UITableViewCell {
    @IBOutlet weak var label:UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure() -> Void {
        if ConfigurationManager.defaultCellFont() != "default" {
            label.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 31.0)
        }
    }

}
