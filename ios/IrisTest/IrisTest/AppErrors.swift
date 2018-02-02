//
//  AppErrors.swift
//  IrisTest
//
//  Created by Arthur  on 2/2/18.
//  Copyright © 2018 Arthur . All rights reserved.
//

import Foundation

enum AppErrorCode{
    case missingObject
    case runningModel
}


func handleError(_ code:AppErrorCode, _ desc:String){
    print("error \(code) \(desc)")
}
