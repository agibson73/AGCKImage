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
    
    var cache : AGCKCache!
    var fileManager : FileManager!
    var ioQueue : DispatchQueue!
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
    
    func setUp() {
        ioQueue = DispatchQueue(label: "com.iosAssasin", attributes: [])
        cache = AGCKCache()
        ioQueue.sync(execute: {
            self.fileManager = FileManager()
        })
        self.createFolderForCKCache()
        
        // Respond to memory warnings
        NotificationCenter.default.addObserver(self, selector: #selector(AGCKAssetCache.removeAllCache), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AGCKAssetCache.autoCleanFilesOlderThan1Week), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
    }
    
    // clean the cache
    func removeAllCache(){
        cache.removeAllObjects()
        purgeCache()
        
    }
    
    // always check Cache First for speed
    func doesAssetCacheExistForRecordID(_ recordID:String)->Bool {
        if cache.object(forKey: recordID as AnyObject) != nil {
            return true
        }
        return false
    }
    
    func doesAssetExistInCacheDirecory(_ recordName: String)->Bool {
        return fileManager.fileExists(atPath: self.pathForAsset(recordName))
    }
    
    func addAssetImageToCache(_ recordName: String, image: UIImage) {
        
        if doesAssetCacheExistForRecordID(recordName) == false {
            cache.setObject(image, forKey: recordName as AnyObject)
        }
        if doesAssetExistInCacheDirecory(recordName) == false {
            self.ioQueue.async(execute: {
                let data = UIImageJPEGRepresentation(image, 1)
                try? data!.write(to: URL(fileURLWithPath: self.pathForAsset(recordName)), options: [.atomic])
            })
        }
        
    }
    func doesCacheImageExistForKey(_ recordName: String)->Bool {
        if doesAssetCacheExistForRecordID(recordName) == true {
            return true
        } else if doesAssetExistInCacheDirecory(recordName) == true {
            return true
        }
        return false
    }
    
    func retrieveImageFromCache(_ recordName: String)->UIImage! {
        if doesAssetCacheExistForRecordID(recordName) == true {
            return cache.object(forKey: recordName as AnyObject) as? UIImage
        } else if doesAssetExistInCacheDirecory(recordName) == true {
            self.ioQueue.async(execute: {
                self.cache.setObject(UIImage(data: try! Data(contentsOf: self.localUrlForAsset(recordName)))!, forKey: recordName as AnyObject)
            })
            
            return UIImage(data: try! Data(contentsOf: self.localUrlForAsset(recordName)))
        } else {
            return nil
        }
        
    }
    
    func localUrlForAsset(_ recordName:String)->URL! {
        return  URL(fileURLWithPath: self.pathForAsset(recordName))
    }
    
    func pathForAsset(_ recordName:String)->String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentDirectory = paths[0] as String
        let myFilePath = documentDirectory.stringByAppendingPathComponent("/ckCache/\(recordName).media")
        return myFilePath
    }
    
    func createFolderForCKCache() {
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
        if !fileManager.fileExists(atPath: agCkCache) {
            do {
                try self.fileManager.createDirectory(atPath: agCkCache, withIntermediateDirectories: false, attributes: nil)
                
            } catch let createDirectoryError as NSError {
                print("Error with creating directory at path: \(createDirectoryError.localizedDescription)")
            }
            
        }
    }
    
    func showFilesInCache() {
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let cachePaths = fileManager.subpaths(atPath: documentDirectoryPath)
        if cachePaths != nil {
            for path in cachePaths! {
                print("path \(path)")
            }
        }
    }
    
    func removeAssetFromCache(_ recordName:String) {
        // remove from cache
        cache.removeObject(forKey: recordName as AnyObject)
        //remove from disk memory
        
        if doesAssetExistInCacheDirecory(recordName) == true {
            let path = self.pathForAsset(recordName)
            do {
                try fileManager.removeItem(atPath: path)
            }catch let error {
                print("not removed \(error)")
            }
        }
    }
    
    func removeItemAtURL(_ url:URL) {
        let path = url.path
        if fileManager.fileExists(atPath: path) == true {
            do {
                try fileManager.removeItem(atPath: path)
            }catch let error {
                print("not removed \(error)")
            }
        }
    }
    
    func purgeCache() {
        let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
        
        do {
            try fileManager.removeItem(atPath: agCkCache)
            createFolderForCKCache()
        }catch let error {
            print("not removed \(error)")
        }
    }
    
    func purgeCacheInBackGround(_ completion:@escaping (_ success:Bool)->Void) {
        self.ioQueue.async(execute: {
            let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
            
            do {
                try self.fileManager.removeItem(atPath: agCkCache)
                self.createFolderForCKCache()
                completion(true)
            }catch let error {
                print("not removed \(error)")
                completion(false)
            }
        })
        
    }
    
    func cacheAgeOfAsset(_ recordName:String)->Date! {
        
        let path = self.pathForAsset(recordName)
        if doesAssetExistInCacheDirecory(recordName) == true {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: path)
                guard let date = attrs[FileAttributeKey.creationDate] as? Date else {return nil}
                return date
                
            }catch let error {
                print("Error reading attributes \(error)")
                return nil
            }
            
        }
        return nil
    }
    
    func cacheAgeItemAtPath(_ path:String)->Date! {
        // lets get the age
        do {
            let attrs = try fileManager.attributesOfItem(atPath: path)
            guard let date = attrs[FileAttributeKey.creationDate] as? Date else {return nil}
            return date
            
        }catch let error {
            print("Error reading attributes \(error)")
            return nil
        }
        
    }
    
    // call this when entering the background to clean cache
    func autoCleanFilesOlderThan(_ daysAgo:Double) {
        self.ioQueue.async(execute: {
            let timeInterval = daysAgo * 12 * 60 * 60
            let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
            let cachePaths = self.fileManager.subpaths(atPath: agCkCache)
            guard let _ = cachePaths else {return}
            for path in cachePaths! {
                print(path)
                if self.cacheAgeItemAtPath(agCkCache + "/" + path) != nil {
                    let date = self.cacheAgeItemAtPath(agCkCache + "/" + path)
                    // print("\(NSDate().timeIntervalSinceDate(date)) and timeInterval is \(timeInterval)")
                    if Date().timeIntervalSince(date!) > timeInterval {
                        print("Creation Date is \(date)")
                        
                        do {
                            try self.fileManager.removeItem(atPath: agCkCache + "/" + path)
                        }catch let error {
                            print("not removed \(error)")
                        }
                        
                    }
                }
                
            }
        })
    }
    
    // call this when entering the background to clean cache
    func autoCleanFilesOlderThan1Week() {
        self.ioQueue.async(execute: {
            let timeInterval = 7 * 12 * 60 * 60
            let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
            let cachePaths = self.fileManager.subpaths(atPath: agCkCache)
            guard let _ = cachePaths else {return}
            for path in cachePaths! {
                print(path)
                if self.cacheAgeItemAtPath(agCkCache + "/" + path) != nil {
                    let date = self.cacheAgeItemAtPath(agCkCache + "/" + path)
                    // print("\(NSDate().timeIntervalSinceDate(date)) and timeInterval is \(timeInterval)")
                    if Date().timeIntervalSince(date!) > Double(timeInterval) {
                        print("Creation Date is \(date)")
                        
                        do {
                            try self.fileManager.removeItem(atPath: agCkCache + "/" + path)
                        }catch let error {
                            print("not removed \(error)")
                        }
                        
                    }
                }
                
            }
        })
    }
    
    // call this when entering the background to clean cache
    func autoCleanFilesOlderThan(_ daysAgo:Double, completion:@escaping (_ finished:Bool)->Void) {
        self.ioQueue.async(execute: {
            let timeInterval = daysAgo * 12 * 60 * 60
            let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let agCkCache = documentDirectoryPath.stringByAppendingPathComponent("/ckCache")
            let cachePaths = self.fileManager.subpaths(atPath: agCkCache)
            guard let _ = cachePaths else {completion(true); return}
            for path in cachePaths! {
                if self.cacheAgeItemAtPath(agCkCache + "/" + path) != nil {
                    let date = self.cacheAgeItemAtPath(agCkCache + "/" + path)
                    if Date().timeIntervalSince(date!) > timeInterval {
                        do {
                            try self.fileManager.removeItem(atPath: agCkCache + "/" + path)
                        }catch let error {
                            print("not removed \(error)")
                        }
                        
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                completion(true)
            })
            
            
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIApplicationDidEnterBackground,object: nil)
    }
}
