//
//  SendViewController.swift
//  SurpriseMe
//
//  Created by National Team on 21.11.2022.
//

import UIKit
import AVFoundation
import AVKit
import Combine

class SendViewController: UIViewController {
  
  @IBOutlet weak var statusLabel: UILabel!
  let mcService = MCService.shared
  private var subscriptions = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mcService.$state.sink { state in
      if state == .notConnected {
        DispatchQueue.main.async {
          self.back()
        }
      }
    }.store(in: &subscriptions)
    
    mcService.onDidReceivedEvent = { event in
      DispatchQueue.main.async {
        print(event)
        switch event {
        case .sentImage(let data):
          self.mcService.send(event: .imageReceived)
          let alert = UIAlertController(title: "Вам прислали картинку! Посмотреть?", message: "Во время просмотра ваша реакция будет записана на камеру", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Да!", style: .default, handler: { _ in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "recordVC")
            (vc as? RecorderViewController)?.image = UIImage(data: data)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
            self.statusLabel.text = "Статус: отправка видео-реакции..."
          }))
          alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: { _ in
            self.mcService.send(event: .imageCanceled)
          }))
          self.present(alert, animated: true)
          self.statusLabel.text = "Статус: ожидание"
        case .sendVideo(let data):
          self.mcService.send(event: .videoReceived)
          let alert = UIAlertController(title: "Вам прислали видео-реакцию! Посмотреть?", message: nil, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Да!", style: .default, handler: { _ in
            let path = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask)[0].appendingPathComponent("video.mp4")
            if (try? data.write(to: path)) != nil {
              let player = AVPlayer(url: path)
              let playerController = AVPlayerViewController()
              playerController.player = player
              self.present(playerController, animated: true) {
                player.play()
              }
            }
          }))
          alert.addAction(UIAlertAction(title: "Нет", style: .cancel))
          self.present(alert, animated: true)
          
          self.statusLabel.text = "Статус: ожидание"
        case .sendingImage:
          self.statusLabel.text = "Статус: получение изображения..."
        case .sendingVideo:
          self.statusLabel.text = "Статус: получение видео-реакции..."
        case .videoReceived:
          self.statusLabel.text = "Статус: ожидание"
        case .imageReceived:
          self.statusLabel.text = "Статус: ожидание ответа-реакции..."
        case .imageCanceled:
          self.statusLabel.text = "Статус: ожидание"
          let alert = UIAlertController(title: "Собеседник отказался от просмотра изображения", message: nil, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .cancel))
          self.present(alert, animated: true)
        }
      }
    }
    // Do any additional setup after loading the view.
  }
  
  @IBAction func back() {
    mcService.disconnect()
    dismiss(animated: true)
  }
  
  @IBAction func sendButtonTap() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .photoLibrary
    imagePicker.delegate = self
    present(imagePicker, animated: true)
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
}

extension SendViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.5) {
      mcService.send(event: .sendingImage)
      mcService.send(event: .sentImage(data: data))
      self.statusLabel.text = "Статус: отправка изображения..."
    }
    picker.dismiss(animated: true)
  }
}
