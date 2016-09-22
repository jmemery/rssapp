//
//  SectionHeaderView.swift
//  RssReader
//
//  Created by Simon Ng on 29/10/2015.
//  Copyright © 2015 AppCoda Limited. All rights reserved.
//

import UIKit

protocol SectionHeaderViewDelegate {
    func didSelectSectionHeaderView(cell:SectionHeaderView)
}

class SectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet var titleButton:UIButton!
    
    var delegate:SectionHeaderViewDelegate?
    var sectionID:Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
    
    @IBAction func titleButtonTapped(sender: UIButton) {
        delegate?.didSelectSectionHeaderView(self)
    }
    
}
