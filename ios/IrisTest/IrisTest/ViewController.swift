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


struct FlowerImage : ExpressibleByStringLiteral {
    
    
    
    let name:String
    let version:Int
    
    let image:CIImage
    let orientation:CGImagePropertyOrientation
    
    
    static let dataSet:[FlowerImage] = ["daisy2.jpg","daisy4.jpg","dandelion2.jpg","dandelion4.jpg","roses2.jpg","roses4.jpg",
                                        "sunflowers2.jpg","sunflowers4.jpg","tulips2.jpg","tulips4.jpg","daisy1.jpg","daisy3.jpg","dandelion1.jpg",
                                        "dandelion3.jpg","roses1.jpg","roses3.jpg","sunflowers1.jpg","sunflowers3.jpg","tulips1.jpg","tulips3.jpg"]
    
    init(_ file:String){
        
        
        guard let im = UIImage(named: file), let ciImage = CIImage(image: im) else {
            
            fatalError("boo.\(file)")
        }
        
        let minDim = min(im.size.height,im.size.width)
        
        let cropCI = ciImage.cropped(to: CGRect(x: (im.size.width - minDim)/2, y: (im.size.height - minDim)/2, width: minDim, height: minDim))
        
        let ratio = 128.0/minDim
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(cropCI, forKey: "inputImage")
        filter.setValue(ratio, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        self.image = outputImage
        self.orientation = CGImagePropertyOrientation(im.imageOrientation)
        self.name = (file as NSString).deletingPathExtension
        self.version = Int((file as NSString).pathExtension) ?? 0
        
    }
    
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init("\(value)")
    }
    
    init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(value)
    }
    
    init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    
}


struct ModelExecution{
    let start:TimeInterval
    let stop:TimeInterval
    let index:Int
    let result:String
    
    func elapseTime()->TimeInterval{
        return stop - start
    }
    
    static func columnTitle() -> String{
      return "flower.name,flower.version,index,start,stop,elapseTime,result"
    }
    
    func columnFormat()->String{
        let flower = FlowerImage.dataSet[index]
        return "\(flower.name),\(flower.version),\(index),\(start),\(stop),\(elapseTime()),\(result)"
    }
    
}

class ViewController: UIViewController, ModelManagerDelegate {
    
    @IBOutlet weak var classificationLabel: UILabel!
    
    var classificationRequest: VNCoreMLRequest?
    
    let irisModel = mobilnet025()
    let useRemote = false
    var runs:[ModelExecution] = []
    
    var currentIndex:Int = 0
    var startTime:TimeInterval = Date.timeIntervalSinceReferenceDate
    
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
        startTime = Date.timeIntervalSinceReferenceDate
        do {
            let vis = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vis, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            self.classificationRequest = request
            
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.updateClassifications()
            }
            
            
        } catch {
            handleError(.runningModel,"unable to run model \(error)")
        }
        
    }
    
    func didNotMakeModel(reason: String) {
        debugPrint("oops")
    }
    
    
    
    func updateClassifications() {
        
        
        
            let flower = FlowerImage.dataSet[self.currentIndex]
            
            guard let request = self.classificationRequest else {
                handleError(.missingObject, "don't have the classification request yet")
                return
            }
            
            // DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: flower.image   , orientation: flower.orientation)
            do {
                self.startTime = Date.timeIntervalSinceReferenceDate
                try handler.perform([request])
            } catch {
                handleError(.runningModel, "Failed to perform classification.\n\(error.localizedDescription)")
            }
       
    }
    
    
    func postProcess(){
        
        let reportLines = runs.map{$0.columnFormat()}
        let report = reportLines.joined(separator: "\n")
        
        let totalTime = runs.reduce(0, { $0 + $1.elapseTime()})/Double(runs.count)
        
        let columnTitle = ModelExecution.columnTitle()
        print("Batched average \(totalTime)")
        print(" runs\n\(columnTitle)\n\(report)")
    }
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        
        guard let _ = request.results else {
            self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
            return
        }
        
        let stop = Date.timeIntervalSinceReferenceDate
        
        let result:String
        
        if let results = request.results {
            
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                result  = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                
                result =  descriptions.joined(separator: ";")
                
            }
        } else {
            result =  "Unable to classify image.\n\(error!.localizedDescription)"
            
        }
        
        let exec = ModelExecution(start: startTime, stop: stop, index: currentIndex, result: result)
        
        runs.append(exec)
        if runs.count < FlowerImage.dataSet.count * 16 {
            currentIndex = (currentIndex + 1) % (FlowerImage.dataSet.count)
            if currentIndex  == 0 {
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1, execute: {
                    self.updateClassifications()
                })
            } else {
                updateClassifications()
            }
            
        } else {
            postProcess()
        }

        
    }
    
    
}



