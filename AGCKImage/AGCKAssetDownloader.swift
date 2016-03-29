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

import UIKit
import CloudKit

class AGCKAssetDownloader: NSObject {
    
   
    class func createAGCKAssetOperation(recordID:CKRecordID,assetKey:String)->CKFetchRecordsOperation{
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        operation.desiredKeys = [assetKey]
        operation.qualityOfService = .UserInitiated
        return operation
    }

    // just an extra function for dowloading with data returned and added to cache
    class func downloadAsset(recordID:CKRecordID,assetKey:String,completion:(data:NSData!)->Void){
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        operation.desiredKeys = [assetKey]
        operation.qualityOfService = .UserInitiated
        
        
        operation.perRecordCompletionBlock = {
            record,recordID,error in
            if let _ = record{
                guard let asset = record!.valueForKey(assetKey) as? CKAsset else{completion(data: nil); return}
                
                    let url = asset.fileURL
                    let imageData = NSData(contentsOfFile: url.path!)!
                    let ckImage = UIImage(data: imageData)
                guard let _ = ckImage else{completion(data: nil); return}
                        // add to cache
                        AGCKAssetCache.defaultManager.addAssetImageToCache(recordID!.recordName, image: ckImage!)
                        completion (data: imageData)
                    
                }else{
                    completion(data:nil)
                }
            }
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(operation)
    }
    
    class func downloadVideoInBackGround(assetKey:String,recordID:CKRecordID,completion:(Bool!,path:String!)->Void){
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        operation.desiredKeys = [assetKey]
        operation.qualityOfService = .UserInitiated
        
        operation.perRecordCompletionBlock = {
            record,retrievedRecordID,error in
            if let _ = record{
                let asset = record!.valueForKey(assetKey) as? CKAsset
                if let _ = asset{
                    let url = asset!.fileURL as NSURL!
                    let videoData = NSData(contentsOfURL: url)
                    let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
                    let destination = cachePath.stringByAppendingString("video.mp4")
                    NSFileManager.defaultManager().createFileAtPath(destination, contents: videoData, attributes: nil)
                    completion(true,path: destination)
                    
                    
                }else{
                    completion(false,path: nil)
                }
            }else{
                completion(false,path: nil)
            }
        }

        CKContainer.defaultContainer().publicCloudDatabase.addOperation(operation)
        
    }

}
