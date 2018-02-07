//
//  ViewController.swift
//  IrisTest
//
//  Created by Arthur  on 2/2/18.
//  Copyright © 2018 Arthur . All rights reserved.
//

import UIKit
import CoreML
import ImageIO


struct FlowerImage : ExpressibleByStringLiteral {
    

    let name:String
    let version:Int
    
    let image:mobilnet025Input
    
    let orientation:CGImagePropertyOrientation
    
    static let imageDim = 128
    
    static let dataSet:[FlowerImage] = ["daisy2.jpg","daisy4.jpg","dandelion2.jpg","dandelion4.jpg","roses2.jpg","roses4.jpg",
                                        "sunflowers2.jpg","sunflowers4.jpg","tulips2.jpg","tulips4.jpg","daisy1.jpg","daisy3.jpg","dandelion1.jpg",
                                        "dandelion3.jpg","roses1.jpg","roses3.jpg","sunflowers1.jpg","sunflowers3.jpg","tulips1.jpg","tulips3.jpg"]
    
    // see https://gist.github.com/omarojo/b47ad0f0965ba8bf2e825ef571ef804c
    
    static func  pixelBufferFromImage(image ciimage: CIImage) -> CVPixelBuffer {
        
        //let cgimage = convertCIImageToCGImage(inputImage: ciimage!)
        let tmpcontext = CIContext(options: nil)
        let cgimage =  tmpcontext.createCGImage(ciimage, from: ciimage.extent)
        
        let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
        let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
        let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
        let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        keysPointer.initialize(to: keys)
        valuesPointer.initialize(to: values)
        
        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
        
        let width = imageDim
        let height = imageDim
        
        var pxbuffer: CVPixelBuffer?
        // if pxbuffer = nil, you will get status = -6661
        _ = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, options, &pxbuffer)
        _ = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        
        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!);
        
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
        let context = CGContext(data: bufferAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesperrow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
        context?.concatenate(CGAffineTransform(rotationAngle: 0))
        context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) )) //Flip Vertical
        //        context?.concatenate(__CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGFloat(width), 0.0)) //Flip Horizontal
        
        
        context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)));
        _ = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        return pxbuffer!;
        
    }
    
    init(_ file:String){
        
        
        guard let im = UIImage(named: file), let ciImage = CIImage(image: im) else {
            
            fatalError("boo.\(file)")
        }
        
        let minDim = min(im.size.height,im.size.width)
        
        let cropCI = ciImage.cropped(to: CGRect(x: (im.size.width - minDim)/2, y: (im.size.height - minDim)/2, width: minDim, height: minDim))
        
        let ratio = CGFloat(FlowerImage.imageDim)/minDim
        
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(cropCI, forKey: "inputImage")
        filter.setValue(ratio, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.value(forKey: "outputImage") as! CIImage
        
        self.image = mobilnet025Input( input__0: FlowerImage.pixelBufferFromImage(image:outputImage))
        
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

class ViewController: UIViewController {
    
    @IBOutlet weak var classificationLabel: UILabel!
    
    let irisModel = mobilnet025()
    let useRemote = false
    var runs:[ModelExecution] = []
    
    var currentIndex:Int = 0
    var startTime:TimeInterval = Date.timeIntervalSinceReferenceDate
    
    func makeModel(){
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateClassifications()
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
    
    
    func didNotMakeModel(reason: String) {
        debugPrint("oops")
    }
    
    
    func updateClassifications(){
        let flower = FlowerImage.dataSet[self.currentIndex]
        self.startTime = Date.timeIntervalSinceReferenceDate
        
        var result = "did not work"
        var stop = self.startTime
        do {
            let p = try self.irisModel.model.prediction(from: flower.image)
            stop = Date.timeIntervalSinceReferenceDate
            
            if let pred =   p.featureValue(for: "final_result__0") {
            
            result = "\(pred)".split(separator: "\n").joined(separator: "|")
                
            } else {
                result = "\(p)"
            }
        } catch {
            handleError(.missingObject, "\(error)")
            result = "failed: \(error)"
        }
        
        let exec = ModelExecution(start: startTime, stop: stop, index: currentIndex, result: result)
        
        runs.append(exec)
        
        if runs.count < FlowerImage.dataSet.count * 100 {
            currentIndex = (currentIndex + 1) % (FlowerImage.dataSet.count) //GKRandomSource.sharedRandom().nextInt(upperBound:
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1, execute: {
                self.updateClassifications()
            })
     
        } else {
            postProcess()
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

    
    
}



