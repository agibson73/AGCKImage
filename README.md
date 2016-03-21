# AGCKImage
AGCKImage is an easy to use framework to deal with CloudKit Image Assets.


Setup: Download the zip and drag the folder into your project!

Use: On any imageview 
     // pass the recordID of the record and the property key for the image asset

    imageView.agCKImageAsset(post.recordID, assetKey: "image")

There are also methods for refresh cache for recordID,download with progress, and download with placeholders.  The cache is automatically set up to clean files older than 2 days but this can be easily changed.

    
Using CloudKit this way allows for faster operations because you never have to include the assets in the desired keys. Also since CloudKit assets downloaded in the traditional methods are not guaranteed to persist or have the same names this simplifies the process. 

To use this in the most effective way use CKQueryOperation when downloading your records. Use the .desiredKeys property and exclude the asset keys. This means speedier downloads. Then use the methods provided on the imageviews to fetch assets when needed. Example of CKQueryOperation if you are unfamiliar is..This just gets the recordId which is all we need to load up some image assets using the provided framework.
          let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "RecordType", predicate: predicate)
        let images: NSMutableArray = []
        
        let imageOperation = CKQueryOperation(query: query)
        imageOperation.desiredKeys = ["recordID"]
         imageOperation.qualityOfService = .UserInitiated // <----- THATS THE CELLULAR
        imageOperation.queuePriority = .High
        imageOperation.recordFetchedBlock = {
            record in
 
            images.addObject(record)
        }

        imageOperation.queryCompletionBlock = {
            cursor,error in
            //reload your tableview,collectionview or whatever.  call on the main thread.
            dispatch_async(dispatch_get_main....blahaha{
            }
        }
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(imageOperation)


Cheers. 

![](http://i.imgur.com/GMfmOsS.gif)
