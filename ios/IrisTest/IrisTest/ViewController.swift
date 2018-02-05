//
//  ViewController.swift
//  IrisTest
//
//  Created by Arthur  on 2/2/18.
//  Copyright © 2018 Arthur . All rights reserved.
//

import UIKit
import CoreML



class ViewController: UIViewController, ModelManagerDelegate {
    
    
    
    
    //var model: iris_logistic_regression?
    
    
    
    var model:MLModel?
    
    
    
    func makeModel(){
        
        let d = ModelDownloadManager.shared
        
        d.delegate = self
        
        guard let bar:URL = URL(string:  "https://docs-assets.developer.apple.com/coreml/models/SqueezeNet.mlmodel") else {
            handleError(.missingObject, "no valid iris url")
            return
        }
        
        
        d.startModelFetch(url: bar)
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  model = iris_logistic_regression()
        
        
        makeModel()
        
        //  runModel()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func hasNew(model: MLModel) {
        self.model = model
        print("now we just have to figure out how to run this")
    }
    
    func didNotMakeModel(reason: String) {
        debugPrint("oops")
    }
    /*
     func runModel(){
     
     guard let m = model else {
     handleError(.missingObject,"No Model")
     return
     }
     
     let pred = iris_logistic_regressionInput(sepal_length__cm_: 5.1, sepal_width__cm_: 3.5, petal_length__cm_: 1.4, petal_width__cm_: 0.2)
     
     do {
     let output =   try m.prediction(input: pred)
     print("\(output)")
     } catch {
     handleError(.runningModel, "\(error)")
     }
     
     }
     */
    
    
}



