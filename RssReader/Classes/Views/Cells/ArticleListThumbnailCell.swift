//
//  ArticleListThumbnailCell.swift
//  RssReader
//
//  Created by Simon Ng on 4/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

class ArticleListThumbnailCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView:UIImageView!
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var authorLabel:UILabel!
    @IBOutlet weak var thumbnailImageViewConstraintHeight: NSLayoutConstraint!
    @IBOutlet weak var thumbnailImageViewConstraintWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
            titleLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 18.0)
            authorLabel.font = UIFont(name: ConfigurationManager.defaultCellFont(), size: 10.0)
        }
    }
}
