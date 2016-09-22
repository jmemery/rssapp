//
//  ArticleDataSource.swift
//  RssReader
//
//  Created by AppCoda on 25.11.14.
//  Copyright (c) 2014 AppCoda Limited. All rights reserved.
//

import UIKit

typealias ConfigureArticleCellClosure = (articleCell: ArticleViewCell, article: Article, indexPath: NSIndexPath) -> ()

class ArticleDataSource: NSObject, UITableViewDataSource {

    var articles = [Article]()
    
    var configureCellClosure: ConfigureArticleCellClosure!
    
    init(configureCellClosure: ConfigureArticleCellClosure!) {
        super.init()
        self.configureCellClosure = configureCellClosure
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    private let cellReuseIdentifier = "ArticleViewCell"
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier)
        
        if cell == nil {
            cell = ArticleViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellReuseIdentifier)
        }
        
        let articleCell = cell as? ArticleViewCell;
        let article = articles[indexPath.row]
        
        self.configureCellClosure(articleCell: articleCell!, article: article, indexPath: indexPath)
        
        return cell!;
    }
    
    subscript(index: Int) -> Article {
        return articles[index]
    }
}