//
//  ConversationsViewController.swift
//  ChattingApp
//
//  Created by Trần Quang Tuấn on 15/8/24.
//

import UIKit
import FirebaseAuth
import ProgressHUD

class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private let noCoversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "You have no message! Contact to friends for more"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noCoversationsLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversation()
    }
    
    private func startListeningForConversation() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = Utils.convertedEmail(Email: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let success):
                guard !success.isEmpty else {
                    return
                }
                
                self?.conversations = success
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let failure):
                print("failed to get: \(failure)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatToCreateANewChat" {
            let vc = segue.destination as! NewConversationViewController
            // Gán dữ liệu cho destinationVC
            vc.completion = {[weak self] result in
                print("\(result)")
                self?.createNewConversation(result: result)
            }
        }
    }
    
    private func createNewConversation(result: [String: String]) {
        guard let name = result["name"], let email = result["email"] else { return }
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func fetchConversations() {
        tableView.isHidden = false
    }
    
    func setupTableView() {
        tableView.register(UINib(nibName: "ConversationTableViewCell", bundle: nil), forCellReuseIdentifier: ConversationTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath)
                as? ConversationTableViewCell else { return UITableViewCell() }
        let model = conversations[indexPath.row]
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}
