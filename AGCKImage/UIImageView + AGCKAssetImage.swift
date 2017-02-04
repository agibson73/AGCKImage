//  Copyright © 2016  Alex Gibson. oakmonttech@gmail.com
/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import Foundation
import UIKit
import CloudKit


private var agOperations = "operations"
extension UIImageView{
    
    // need this to track and cancel operations
    var operations : CKFetchRecordsOperation!{
        get{
             return objc_getAssociatedObject(self, &agOperations) as? CKFetchRecordsOperation
            }
        set(newValue) {
            objc_setAssociatedObject(self, &agOperations, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    func agCKImageAsset(_ recordID:CKRecordID,assetKey:String){
        
        downloadAssetImage(nil, shouldRefresh: false, recordID: recordID, assetKey: assetKey, ckProgress: {progress,finished in})
    }
    
    func agCKImageAssetWithPlaceHolder(_ recordID:CKRecordID,assetKey:String,placeHolder:UIImage?){
        downloadAssetImage(placeHolder, shouldRefresh: false, recordID: recordID, assetKey: assetKey, ckProgress: {progress,finished in})
    }
    func agCKImageAssetWithResetCacheForID(_ recordID:CKRecordID,assetKey:String){
        downloadAssetImage(nil, shouldRefresh: true, recordID: recordID, assetKey: assetKey, ckProgress: {progress,finished in})
    }
    

    func agCKImageAssetWithProgress(_ recordID:CKRecordID,assetKey:String,ckProgress:@escaping (_ progress:Double?,_ finished:Bool?)->Void){
        downloadAssetImage(nil, shouldRefresh: false, recordID: recordID, assetKey: assetKey, ckProgress: {progress,finished in
            ckProgress(progress, finished)
        })
       
    }
    func agCKImageAssetWithProgressWithResetCacheForID(_ recordID:CKRecordID,assetKey:String,ckProgress:@escaping (_ progress:Double?,_ finished:Bool?)->Void){
        downloadAssetImage(nil, shouldRefresh: true, recordID: recordID, assetKey: assetKey, ckProgress: {progress,finished in
            ckProgress(progress, finished)
        })
    }
    

    
    fileprivate func downloadAssetImage(_ placeHolder:UIImage?,shouldRefresh:Bool,recordID:CKRecordID,assetKey:String,ckProgress:@escaping (_ progress:Double?,_ finished:Bool?)->Void){
        
        // cancel current operation
        self.cancelCurrentOperation()
        // set to nil or placholder
        self.image = placeHolder

        var cacheImage : UIImage?
        
        // to refresh or not to refresh...that is the question
        if shouldRefresh == true{
            AGCKAssetCache.defaultManager.removeAssetFromCache(recordID.recordName)
        }else{
             cacheImage = AGCKAssetCache.defaultManager.retrieveImageFromCache(recordID.recordName)
        }
        
        // well if we don't have a cache image let's have some action
        if cacheImage == nil{
            // just a local progress variable..probably don't need it but i use it in the perRecordCompletionBlock
            var internalProgress = 0.0
            let operation = AGCKAssetDownloader.createAGCKAssetOperation(recordID, assetKey: assetKey)
            operation.perRecordProgressBlock = {
                record,progress in
                internalProgress = progress
                ckProgress(progress,false)
            }
            
            operation.perRecordCompletionBlock = {
                record,recordID,error in
                if let _ = record{
                    let asset = record!.value(forKey: assetKey) as? CKAsset
                    
                    if let _ = asset{
                        let url = asset!.fileURL
                        let imageData = try! Data(contentsOf: URL(fileURLWithPath: url.path))
                        let ckImage = UIImage(data: imageData)!
                        AGCKAssetCache.defaultManager.addAssetImageToCache(recordID!.recordName, image: ckImage)
                        DispatchQueue.main.async(execute: {
                            self.image = ckImage
                        })
                        
                    }
                    if error != nil{
                        print(error!)
                    }
                }
                ckProgress(internalProgress, true)
                
            }
            CKContainer.default().publicCloudDatabase.add(operation)
            self.operations = operation
        }else{
            ckProgress(1.0, true)
            self.image = cacheImage
        }
    }


    // cancel operation
    func cancelCurrentOperation(){
        guard let op = self.operations else{return}
        op.cancel()
    }

    
    
}
