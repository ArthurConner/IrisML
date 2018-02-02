//
//  ViewController.swift
//  IrisTest
//
//  Created by Arthur  on 2/2/18.
//  Copyright © 2018 Arthur . All rights reserved.
//

import UIKit



class ViewController: UIViewController {

    var model: iris_logistic_regression?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model = iris_logistic_regression()
        runModel()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

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

}

