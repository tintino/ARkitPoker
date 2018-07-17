//
//  AVCaptureLayerViewController.swift
//  pokAR
//
//  Created by Martin Gonzalez vega on 17/07/2018.
//  Copyright © 2018 T1incho. All rights reserved.
//

import UIKit
import AVKit
import Vision

class AVCaptureLayerViewController: UIViewController {
    @IBOutlet weak var labelDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
}

extension AVCaptureLayerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Core ML expects images in the form of a CVPixelBuffer
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Get traning model with objects detection.
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
            
            if error == nil {
                
                guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
                guard let firstObservation = results.first else { return }
                
                DispatchQueue.main.async {
                    self.labelDescription.text = "\(firstObservation.identifier) \(String(format: "%0.f", firstObservation.confidence * 100)) %"
                }
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
