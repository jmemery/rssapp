//
//  ArticleListDescriptionCell.swift
//  RssReader
//
//  Created by Simon Ng on 4/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

class ArticleListDescriptionCell: UITableViewCell {
    @IBOutlet weak var titleLabel:UILabel! 
    @IBOutlet weak var descriptionLabel:UILabel! 
    @IBOutlet weak var authorLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configure()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.updateConstraintsIfNeeded()
        self.contentView.layoutIfNeeded()
    }
    
    func configure() -> Void {
        titleLabel.lineBreakMode = .ByWordWrapping
        descriptionLabel.lineBreakMode = .ByWordWrapping
        
        if ConfigurationManager.defaultCellFont() != "default" {
            titleLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 29.0)
            authorLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 10.0)
            descriptionLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 20.0)
        }
    }

}

