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


class AGCKAssetCache: NSObject {
    
    var cache : NSCache!
    var fileManager : NSFileManager!
    var ioQueue : dispatch_queue_t!
    class var defaultManager: AGCKAssetCache {
        struct Static {
            static let instance : AGCKAssetCache = AGCKAssetCache()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        setUp()
        
    }
    
    func setUp(){
        ioQueue = dispatch_queue_create("com.iosAssasin", DISPATCH_QUEUE_SERIAL)
        cache = NSCache()
        fileManager = NSFileManager.defaultManager()
        createFolderForCKCache()
        let sem = dispatch_semaphore_create(0)
        
        // Clean cache older than 2 days.  Can be changed
        autoCleanFilesOlderThan(2, completion: {finished in
            dispatch_semaphore_signal(sem)
        })
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        // Respond to memory warnings
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeAllCache", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
    }
    
    // clean the cache
    func removeAllCache(){
        cache.removeAllObjects()
        purgeCache()
        
    }
    
    // always check Cache First for speed
    func doesAssetCacheExistForRecordID(recordID:String)->Bool{
        if cache.objectForKey(recordID) != nil{
            return true
        }
        return false
    }
    
    func doesAssetExistInCacheDirecory(recordName:String)->Bool{
        return fileManager.fileExistsAtPath(self.pathForAsset(recordName))
    }
    
    func addAssetImageToCache(recordName:String,image:UIImage){
        
        if doesAssetCacheExistForRecordID(recordName) == false{
            cache.setObject(image, forKey: recordName)
        }
        if doesAssetExistInCacheDirecory(recordName) == false{
            dispatch_async(self.ioQueue, {
                let data = UIImageJPEGRepresentation(image, 1)
                data!.writeToFile(self.pathForAsset(recordName), atomically: true)
            })
        }
        
    }
    func doesCacheImageExistForKey(recordName:String)->Bool{
        if doesAssetCacheExistForRecordID(recordName) == true{
            return true
        }else if doesAssetExistInCacheDirecory(recordName) == true{
            return true
        }
        return false
    }
    
    func retrieveImageFromCache(recordName:String)->UIImage!{
        if doesAssetCacheExistForRecordID(recordName) == true{
            return cache.objectForKey(recordName) as? UIImage
        }else if doesAssetExistInCacheDirecory(recordName) == true{
            dispatch_async(self.ioQueue, {
                self.cache.setObject(UIImage(data: NSData(contentsOfURL: self.localUrlForAsset(recordName))!)!, forKey: recordName)
            })
            
            return UIImage(data: NSData(contentsOfURL: self.localUrlForAsset(recordName))!)
        }else{
            return nil
        }
        
    }

    func localUrlForAsset(recordName:String)->NSURL!{
        return  NSURL(fileURLWithPath: self.pathForAsset(recordName))
    }
    
    func pathForAsset(recordName:String)->String{
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        let documentDirectory = paths[0] as String
        let myFilePath = documentDirectory.stringByAppendingPathComponent("/ckCache/\(recordName).media")
        return myFilePath
    }
    
    func createFolderForCKCache(){
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
        let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
        if !fileManager.fileExistsAtPath(agCkCache) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(agCkCache, withIntermediateDirectories: false, attributes: nil)
                
            } catch let createDirectoryError as NSError {
                print("Error with creating directory at path: \(createDirectoryError.localizedDescription)")
            }
            
        }
    }
    
    func showFilesInCache(){
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
        let cachePaths = fileManager.subpathsAtPath(documentDirectoryPath)
        if let _ = cachePaths{
            for path in cachePaths!{
                print("path \(path)")
                
            }
        }
        
    }
    
    func removeAssetFromCache(recordName:String){
        // remove from cache
        cache.removeObjectForKey(recordName)
        //remove from disk memory
        
        if doesAssetExistInCacheDirecory(recordName) == true{
            let path = self.pathForAsset(recordName)
            do{
                try fileManager.removeItemAtPath(path)
            }catch let error{
                print("not removed \(error)")
            }
        }

    }
    

    func removeItemAtURL(url:NSURL){
        let path = url.path!
        if fileManager.fileExistsAtPath(path) == true{
            do{
                try fileManager.removeItemAtPath(path)
            }catch let error{
                print("not removed \(error)")
            }
        }
    }
    
    func purgeCache(){
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
        let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
        
        do{
            try fileManager.removeItemAtPath(agCkCache)
            createFolderForCKCache()
        }catch let error{
            print("not removed \(error)")
        }
    }
    
    func purgeCacheInBackGround(completion:(success:Bool)->Void){
        dispatch_async(self.ioQueue, {
            let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
            let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
            
            do{
                try self.fileManager.removeItemAtPath(agCkCache)
                self.createFolderForCKCache()
                completion(success: true)
            }catch let error{
                print("not removed \(error)")
                completion(success: false)
            }
        })
        
    }
    
    func cacheAgeOfAsset(recordName:String)->NSDate!{
        
        let path = self.pathForAsset(recordName)
        if doesAssetExistInCacheDirecory(recordName) == true{
            do{
                let attrs = try fileManager.attributesOfItemAtPath(path)
                guard let date = attrs[NSFileCreationDate] as? NSDate else{return nil}
                return date

            }catch let error{
                print("Error reading attributes \(error)")
                return nil
            }
            
        }
        return nil
    }
    
    func cacheAgeItemAtPath(path:String)->NSDate!{
        // lets get the age
        do{
            let attrs = try fileManager.attributesOfItemAtPath(path)
            guard let date = attrs[NSFileCreationDate] as? NSDate else{return nil}
            return date
            
        }catch let error{
            print("Error reading attributes \(error)")
            return nil
        }
        
    }
    
    // call this when entering the background to clean cache
    func autoCleanFilesOlderThan(daysAgo:Double){
         dispatch_async(self.ioQueue, {
        let timeInterval = daysAgo * 12 * 60 * 60
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
        let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
        let cachePaths = self.fileManager.subpathsAtPath(agCkCache)
        guard let _ = cachePaths else{return}
            for path in cachePaths!{
                print(path)
                if self.cacheAgeItemAtPath(agCkCache + "/" + path) != nil{
                    let date = self.cacheAgeItemAtPath(agCkCache + "/" + path)
                   // print("\(NSDate().timeIntervalSinceDate(date)) and timeInterval is \(timeInterval)")
                    if NSDate().timeIntervalSinceDate(date) > timeInterval{
                        print("Creation Date is \(date)")
                        
                        do{
                            try self.fileManager.removeItemAtPath(agCkCache + "/" + path)
                        }catch let error{
                            print("not removed \(error)")
                        }
                        
                    }
                }

            }
        })
    }
    
    // call this when entering the background to clean cache
    func autoCleanFilesOlderThan(daysAgo:Double,completion:(finished:Bool)->Void){
        dispatch_async(self.ioQueue, {
            let timeInterval = daysAgo * 12 * 60 * 60
            let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
            let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
            let cachePaths = self.fileManager.subpathsAtPath(agCkCache)
            guard let _ = cachePaths else{completion(finished: true); return}
            for path in cachePaths!{
                if self.cacheAgeItemAtPath(agCkCache + "/" + path) != nil{
                    let date = self.cacheAgeItemAtPath(agCkCache + "/" + path)
                    if NSDate().timeIntervalSinceDate(date) > timeInterval{
                        do{
                            try self.fileManager.removeItemAtPath(agCkCache + "/" + path)
                        }catch let error{
                            print("not removed \(error)")
                        }
                        
                    }
                }
            }
            completion(finished: true)

        })
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
}
