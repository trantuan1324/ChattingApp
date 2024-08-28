//
//  NewConversationViewController.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 19/8/24.
//

import UIKit
import ProgressHUD

class NewConversationViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    private var results = [[String:String]]()
    private var users = [[String:String]]()
    private var hasFetcherd = false
    
    public var completion : (([String: String]) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
    }
}

extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = results[indexPath.row]["name"]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
        }
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        ProgressHUD.animate("Please wait...", .barSweepToggle)
        
        self.searchUsers(query: text)
    }
    
    private func searchUsers(query: String) {
        if hasFetcherd {
            filterUsers(with: query)
        } else {
            DatabaseManager.shared.getAllUsers() { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let usersCollection):
                    self.hasFetcherd = true
                    self.users = usersCollection
                    self.filterUsers(with: query)
                case .failure(let error):
                    print("Get users failed: \(error)")
                }
                
            }
        }
    }
    
    private func filterUsers(with term: String) {
        guard hasFetcherd else {
            return
        }
        
        ProgressHUD.dismiss()
        let results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else { return false }
            
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        self.tableView.reloadData()
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
