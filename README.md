# AGCKImage
AGCKImage is an easy to use framework to deal with CloudKit Image Assets.


Setup: Download the zip and drag the folder into your project!

Use: On any imageview 
     // pass the recordID of the record and the property key for the image asset
    imageView.agCKImageAsset(post.recordID, assetKey: "image")

There are also methods for refresh cache for recordID,download with progress, and download with placeholders.  The cache is automatically set up to clean cache older than 2 days but this can be easily changed.

    
Using CloudKit this way allows for faster operations because you never have to include the assets in the desired keys. Also since CloudKit assets downloaded in the traditional methods are not guaranteed to persist or have the same names this simplifies the process. 
