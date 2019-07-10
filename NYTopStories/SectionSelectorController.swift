//
//  SectionSelectorController.swift
//  NYTopStories
//
//  Created by Avinash on 10/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import UIKit

/// Section selector popover class.
class SectionSelectorController: UITableViewController {

    private let reuseIdentifier = "reuseIdentifier"
    typealias Completion = (_ section: String) -> Void
    
    let options = AllowedSectionType.allCases.map{$0.rawValue}
    var completion: Completion?
    
    override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.preferredContentSize = tableView.contentSize
    }
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = options[indexPath.row].capitalized

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSection = options[indexPath.row]
        completion?(selectedSection)
        self.dismiss(animated: true, completion: nil)
    }
    
    func select(withCompletion aCompletion: @escaping Completion) {
        completion = aCompletion
    }
    
    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }
 }
