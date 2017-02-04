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
    
   
    class func createAGCKAssetOperation(_ recordID:CKRecordID,assetKey:String)->CKFetchRecordsOperation{
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        operation.desiredKeys = [assetKey]
        operation.qualityOfService = .userInitiated
        return operation
    }

    // just an extra function for dowloading with data returned and added to cache
    class func downloadAsset(_ recordID:CKRecordID,assetKey:String,completion:@escaping (_ data:Data?)->Void){
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        operation.desiredKeys = [assetKey]
        operation.qualityOfService = .userInitiated
        
        
        operation.perRecordCompletionBlock = {
            record,recordID,error in
            if let _ = record{
                guard let asset = record!.value(forKey: assetKey) as? CKAsset else{completion(nil); return}
                
                    let url = asset.fileURL
                    let imageData = try! Data(contentsOf: URL(fileURLWithPath: url.path))
                    let ckImage = UIImage(data: imageData)
                guard let _ = ckImage else{completion(nil); return}
                        // add to cache
                        AGCKAssetCache.defaultManager.addAssetImageToCache(recordID!.recordName, image: ckImage!)
                        completion (imageData)
                    
                }else{
                    completion(nil)
                }
            }
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    class func downloadVideoInBackGround(_ assetKey:String,recordID:CKRecordID,completion:@escaping (Bool?,_ path:String?)->Void){
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        operation.desiredKeys = [assetKey]
        operation.qualityOfService = .userInitiated
        
        operation.perRecordCompletionBlock = {
            record,retrievedRecordID,error in
            if let _ = record{
                let asset = record!.value(forKey: assetKey) as? CKAsset
                if let _ = asset{
                    let url = asset!.fileURL as URL!
                    let videoData = try? Data(contentsOf: url!)
                    let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                    let destination = cachePath + "video.mp4"
                    FileManager.default.createFile(atPath: destination, contents: videoData, attributes: nil)
                    completion(true,destination)
                    
                    
                }else{
                    completion(false,nil)
                }
            }else{
                completion(false,nil)
            }
        }

        CKContainer.default().publicCloudDatabase.add(operation)
        
    }

}
