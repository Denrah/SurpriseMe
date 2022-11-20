//
//  RecorderViewController.swift
//  SurpriseMe
//
//  Created by National Team on 21.11.2022.
//

import UIKit
import AVFoundation
import AVKit

class RecorderViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  var captureSession = AVCaptureSession()
  var cameraInput: AVCaptureDeviceInput?
  var videoOutput: AVCaptureMovieFileOutput?
  let mcService = MCService.shared
  var image: UIImage?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imageView.image = image
    // Do any additional setup after loading the view.
    record()
  }
  
  func record() {
    let session = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                        mediaType: .video, position: .front)
    guard let camera = (session.devices.compactMap { $0 }.first { $0.position == .front }) else { return }
    
    if let cameraInput = try? AVCaptureDeviceInput(device: camera) {
      self.cameraInput = cameraInput
      if captureSession.canAddInput(cameraInput) {
        captureSession.addInput(cameraInput)
      }
    }
    
    let videoOutput = AVCaptureMovieFileOutput()
    self.videoOutput = videoOutput
    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
    }
    
    self.captureSession.startRunning()
    
    if captureSession.isRunning {
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let fileUrl = paths[0].appendingPathComponent("output.mp4")
      try? FileManager.default.removeItem(at: fileUrl)
      videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
  }
  
  @IBAction func tapFinish() {
    if self.captureSession.isRunning {
      self.videoOutput?.stopRecording()
    }
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

extension RecorderViewController: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    if let data = try? Data(contentsOf: outputFileURL) {
      mcService.send(event: .sendingVideo)
      mcService.send(event: .sendVideo(data: data))
    }
    dismiss(animated: true)
  }
}
