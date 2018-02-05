//
//  ViewController.swift
//  IrisTest
//
//  Created by Arthur  on 2/2/18.
//  Copyright © 2018 Arthur . All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO


class ViewController: UIViewController, ModelManagerDelegate {
    
    @IBOutlet weak var classificationLabel: UILabel!
    
    var classificationRequest: VNCoreMLRequest?
    
    let irisModel = mobilnet025()
    let useRemote = false
    
    func makeModel(){
        if useRemote {
            let d = ModelDownloadManager.shared
            
            classificationLabel.text = "Downloading model"
            d.delegate = self
            
            let name = "https://docs-assets.developer.apple.com/coreml/models/MobileNet.mlmodel"
            // let name  = "https://docs-assets.developer.apple.com/coreml/models/SqueezeNet.mlmodel"
            
            guard let bar:URL = URL(string:  name) else {
                handleError(.missingObject, "no valid iris url")
                return
            }
            
            d.startModelFetch(url: bar)
        } else {
            
            hasNew(model: irisModel.model)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeModel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func hasNew(model: MLModel) {
        
        do {
            let vis = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vis, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            self.classificationRequest = request
            
            if let im = UIImage(named: "sunflower-sun-summer-yellow.jpg") {
                updateClassifications(for: im)
            }
            
        } catch {
            handleError(.runningModel,"unable to run model \(error)")
        }
        
    }
    
    func didNotMakeModel(reason: String) {
        debugPrint("oops")
    }
    
    func updateClassifications(for image: UIImage) {
        
        guard let request = self.classificationRequest else {
            handleError(.missingObject, "don't have the classification request yet")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.classificationLabel.text = "Classifying..."
        }
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([request])
            } catch {
                handleError(.runningModel, "Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                self.classificationLabel.text = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                self.classificationLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
            }
        }
    }
    
    
}



