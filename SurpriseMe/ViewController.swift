//
//  ViewController.swift
//  SurpriseMe
//
//  Created by National Team on 21.11.2022.
//

import UIKit
import MultipeerConnectivity
import Combine

class ViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  
  let mcService = MCService.shared
  var foundPeers: [MCPeerID] = []
  
  private var subscriptions = Set<AnyCancellable>()
  
  var hasAppearedOnce = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.dataSource = self
    tableView.delegate = self
    // Do any additional setup after loading the view.
    
    mcService.$foundPeers.sink { peers in
      self.foundPeers = Array(peers).sorted { $0.displayName < $1.displayName }
      self.tableView.reloadData()
    }.store(in: &subscriptions)
    
    mcService.$state.sink { state in
      if state == .connected {
        DispatchQueue.main.async {
          let storyboard = UIStoryboard(name: "Main", bundle: nil)
          let vc = storyboard.instantiateViewController(withIdentifier: "sendVC")
          vc.modalPresentationStyle = .fullScreen
          self.present(vc, animated: true)
        }
      }
    }.store(in: &subscriptions)
    
    mcService.delegate = self
    
   
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    guard !hasAppearedOnce else { return }
    hasAppearedOnce = true
    
    let alert = UIAlertController(title: "Как вас зовут?", message: "Это имя увидят собеседники поблизости", preferredStyle: .alert)
    alert.addTextField()
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
      if let text = alert?.textFields?.first?.text, !text.isEmpty {
        self.mcService.displayName = text
      }
      self.mcService.start(with: self.mcService.displayName)
    }))
    present(alert, animated: true)
  }


}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.textLabel?.text = foundPeers[indexPath.row].displayName
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return foundPeers.count
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    mcService.invite(peer: foundPeers[indexPath.row])
  }
}

extension ViewController: MCServiceDelegate {
  func mcService(_ service: MCService, didReceiveInvitationFrom peer: MCPeerID) {
    let alertController = UIAlertController(title: "\(peer.displayName) хочет отправить сообщение", message: nil, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Принять", style: .default, handler: { _ in
      self.mcService.handleInvitation(accept: true)
    }))
    alertController.addAction(UIAlertAction(title: "Отклонить", style: .cancel, handler: { _ in
      self.mcService.handleInvitation(accept: false)
    }))
    present(alertController, animated: true)
  }
}
