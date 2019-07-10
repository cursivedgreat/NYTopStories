//
//  ListViewController.swift
//  NYTopStories
//
//  Created by Avinash on 09/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import UIKit
import SDWebImage

/// Class that list all the article from a section from NyTimes.
class ListViewController: UITableViewController {
    private let listCell = "listCell"
    private let viewModel = ViewModel()
    private var sections = [[String: [Results]]] (){
        didSet{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Section Selector
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Change Section", comment: "Change Section"), style: .plain, target: self, action: #selector(changeSection(_:)))
        
        //Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshFromApi), for: .valueChanged)
        
        //Automatic cell height configuration
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        //Load initial section
        loadData()
        
    }
    
    func loadData() {
        if UserDefaults.standard.bool(forKey: APP_LAUNCHED_BEFORE) {
            do {
                try viewModel.loadCachedResponse { result in
                    self.handle(result: result)
                    self.refreshFromApi()
                }
            } catch {
                print("Error \(error)")
            }
        } else {
            self.refreshFromApi()
        }
        
    }
    /// Api to refresh selected section.
    /// Also pull to refresh callback
    @objc func refreshFromApi() {
        self.refreshControl?.beginRefreshing()
        self.viewModel.refreshSection { result in
            self.handle(result: result)
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    /// Method to handle Result from Api/Database call
    ///
    /// - Parameter aResult: Result Object
    func handle(result aResult: Result<ApiResponse, ApiError>) {
        DispatchQueue.main.async {
            switch aResult {
            case .success(let response):
                self.sections = self.viewModel.format(apiResponse: response)
                DispatchQueue.main.async {
                    self.title = response.section?.uppercased()
                }
            case .failure(let error):
                print("Error \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Array(sections[section].values)[0].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: listCell, for: indexPath) as? ListCell else {
            return UITableViewCell()
        }
        let result = Array(sections[indexPath.section].values)[0][indexPath.row]
        cell.storyLabel.text = result.title
        cell.authorLabel.text = result.byline
        DispatchQueue.global().async {
            cell.previewImageView.sd_setImage(with: result.multimedia?.first?.url, placeholderImage: nil, options: .retryFailed, completed: nil)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].keys.first
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = Array(sections[indexPath.section].values)[0][indexPath.row]
        openDetailView(forResult: result)
    }
    
    /// Opens the Detail view for selected article
    ///
    /// - Parameter result: selected article Object
    func openDetailView(forResult result: Results) {
        if let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
            controller.result = result
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    //MARK: - Change Section
    
    /// Api to change the section of Article from New York Times
    ///
    /// - Parameter button: Bar button
    @objc func changeSection(_ button: UIBarButtonItem) {
        let selector = SectionSelectorController(style: .plain)
        selector.modalPresentationStyle = .popover
        
        if let popOver = selector.popoverPresentationController {
            popOver.barButtonItem = button
            popOver.delegate = self
        }
        self.present(selector, animated: true, completion: nil)
        selector.preferredContentSize = CGSize(width: 150, height: 100)
        selector.select { [weak self] selectedSection in
            self?.viewModel.selectedSection = selectedSection
            self?.refreshFromApi()
        }
    }
}

extension ListViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
