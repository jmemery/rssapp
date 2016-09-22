//
//  ArticleBaseViewCell.swift
//  RssReader
//
//  Created by Simon Ng on 5/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

class ArticleMetaViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!

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
        authorLabel.lineBreakMode = .ByWordWrapping
        
        if ConfigurationManager.defaultCellFont() != "default" {
            titleLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 30.0)
            authorLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 15.0)
        }
    }

}
