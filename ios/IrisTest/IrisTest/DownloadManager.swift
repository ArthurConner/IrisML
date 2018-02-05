//
//  DownloadManager.swift
//  IrisTest
//
//  Created by Arthur  on 2/5/18.
//  Copyright © 2018 Arthur . All rights reserved.
//

import Foundation
import CoreML

protocol ModelManagerDelegate {
    
    func hasNew(model:MLModel)
    func didNotMakeModel(reason:String)
}

class ModelDownloadManager : NSObject {
    
    var session:URLSession?
    let queue = OperationQueue()
    
    var delegate:ModelManagerDelegate?
    
    static let shared = ModelDownloadManager()
    
    // Download service sets these values:
    var task: URLSessionDownloadTask?
    var isDownloading = false
    var resumeData: Data?
    
    // Download delegate sets this value:
    var progress: Float = 0

    
    func startModelFetch(url:URL){
        
        if session == nil {
            let s =  URLSession(configuration: .default, delegate: self, delegateQueue: queue)
            session = s
        }
        
        guard let sess = self.session else {
            handleError(.missingObject, "No background session")
            return
        }
        
        let t = sess.downloadTask(with: url, completionHandler: {[weak self] location,r,e in
            
            guard let me = self else {
                return
            }
            
            guard let d = me.delegate else {
                handleError(.missingObject, "No delegate to handle model")
                return
            }
            
            guard let location = location else {
                let reason = "no save path"
                handleError(.missingObject,  reason)
                d.didNotMakeModel(reason:reason)
                return
            }
            
            let compiledUrl:URL
            
            do {
                compiledUrl = try MLModel.compileModel(at: location)
            } catch {
                let reason = "can't compile \(error)"
                handleError(.missingObject,  reason)
                d.didNotMakeModel(reason:reason)
                return
            }
            
            
            do {
                let model = try MLModel(contentsOf: compiledUrl)
                d.hasNew(model: model)
                
            } catch {
                
                let reason = "model not found  \(error)"
                handleError(.missingObject,  reason)
                d.didNotMakeModel(reason:reason)
            }
            
        })
        
        t.resume()
    
        
    }
    
    
    
}

extension ModelDownloadManager : URLSessionDelegate{
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
        
        guard let d = self.delegate else {
            handleError(.missingObject, "No delegate to handle model")
            return
        }

        let compiledUrl:URL
        
        do {
            compiledUrl = try MLModel.compileModel(at: location)
        } catch {
            let reason = "can't compile \(error)"
            handleError(.missingObject,  reason)
            d.didNotMakeModel(reason:reason)
            return
        }
        
        
        do {
            let model = try MLModel(contentsOf: compiledUrl)
            d.hasNew(model: model)
            
        } catch {
            
            
            let reason = "model not found  \(error)"
            handleError(.missingObject,  reason)
            d.didNotMakeModel(reason:reason)
        }
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let reason = "no delegate for error \(String(describing: error))"
        guard let d = self.delegate else {
            handleError(.missingObject, reason)
            return
        }
        d.didNotMakeModel(reason:reason)
    }
    
}

