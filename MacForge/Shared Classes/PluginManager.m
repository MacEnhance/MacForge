//
//  PluginManager.m
//  PluginManager
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "FConvenience.h"
#import "PluginManager.h"

@implementation PluginManager

// Shared instance if needed
+ (PluginManager*) sharedInstance {
    static PluginManager* pData = nil;
    if (pData == nil)
        pData = [[PluginManager alloc] init];
    return pData;
}

// Download starting
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    if (progressObject)
        progressObject.doubleValue = 0.0f;
    _downloadSize=[response expectedContentLength];
    _dataToDownload=[[NSMutableData alloc]init];
}

// Download update progress
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_dataToDownload appendData:data];
    double progress = [ _dataToDownload length ]/_downloadSize;
//    NSLog(@"Bytes received - %f", [ _dataToDownload length ]/_downloadSize);

    if (progressObject)
        progressObject.doubleValue = progress * 100;
    
    if (downloadButton)
        downloadButton.title = @"";
    
    if (progress == 1.0)
        [self pluginDownloaded:_dataToDownload];
}

+ (NSArray*)MacEnhancePluginPaths {
    NSArray* libDomain = [FileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [FileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
    NSString* libPathENB = [NSString stringWithFormat:@"%@/MacEnhance/Plugins", libSupport];
    NSString* libPathDIS = [NSString stringWithFormat:@"%@/MacEnhance/Plugins (Disabled)", libSupport];
    NSString* usrPathENB = [NSString stringWithFormat:@"%@/MacEnhance/Plugins", usrSupport];
    NSString* usrPathDIS = [NSString stringWithFormat:@"%@/MacEnhance/Plugins (Disabled)", usrSupport];
    NSString* OpeePath = [NSString stringWithFormat:@"/Library/Opee/Extensions"];
    
//    NSString* appPath = [NSString stringWithFormat:@"/Applications"];
//    NSString* libTheme = [NSString stringWithFormat:@"%@/MacEnhance/Themes", libSupport];
    
    NSArray *paths = @[libPathENB, libPathDIS, usrPathENB, usrPathDIS, OpeePath];
    return paths;
}

// Try to install all item in an array of file paths
- (void)installBundles:(NSArray*)pathArray {
    for (NSString* path in pathArray) {
        // Install a bundle
        if ([[path pathExtension] isEqualToString:@"bundle"]) {
            NSArray* pathComp=[path pathComponents];
            NSString* name=[pathComp objectAtIndex:[pathComp count] - 1];
            NSString* newPath = [NSString stringWithFormat:@"%@/%@", [PluginManager MacEnhancePluginPaths][0], name];
            [self replaceFile:path :newPath];
        }
        
        // Install an application
        if ([[path pathExtension] isEqualToString:@"app"]) {
            NSArray* pathComp=[path pathComponents];
            NSString* name=[pathComp objectAtIndex:[pathComp count] - 1];
            NSString* newPath = [NSString stringWithFormat:@"/Applications/%@", name];
            [self replaceFile:path :newPath];
        }
    }
}

// Try to replace file `end` with file `start`
- (void)replaceFile:(NSString*)start :(NSString*)end {
    NSError* error;
    // Make intermediate tirectories to destination if they don't exist
    if (![FileManager fileExistsAtPath:[end stringByDeletingLastPathComponent]]) {
        [FileManager createDirectoryAtPath:[end stringByDeletingLastPathComponent]
               withIntermediateDirectories:true
                                attributes:nil
                                     error:&error];
    }
    
    // Try replacing the file
    if ([FileManager fileExistsAtPath:end]) {
        // File exists
        [FileManager replaceItemAtURL:[NSURL fileURLWithPath:end]
                        withItemAtURL:[NSURL fileURLWithPath:start]
                       backupItemName:nil
                              options:NSFileManagerItemReplacementUsingNewMetadataOnly
                     resultingItemURL:nil
                                error:&error];
    } else {
        // File doesn't exist
        [FileManager moveItemAtURL:[NSURL fileURLWithPath:start]
                             toURL:[NSURL fileURLWithPath:end]
                             error:&error];
    }
}

// Look at a folder and find all MacForge plugins wihtin it and add them to the given Dictionatry
- (void)readFolder:(NSString *)str :(NSMutableDictionary *)dict {
    NSArray *appFolderContents = [[NSArray alloc] init];
    appFolderContents = [FileManager contentsOfDirectoryAtPath:str error:nil];
    
    for (NSString* fileName in appFolderContents) {
        if ([fileName hasSuffix:@".bundle"]) {
            NSString* path=[str stringByAppendingPathComponent:fileName];
            NSString* name=[fileName stringByDeletingPathExtension];
            
            //check Info.plist
            NSBundle        *bundle = [NSBundle bundleWithPath:path];
            
            NSString        *plistPath = [bundle bundlePath];
            plistPath = [NSString stringWithFormat:@"%@/Contents/Info.plist", plistPath];
            
            NSDictionary    *info = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
            NSString* bundleIdentifier=[bundle bundleIdentifier];
            if (![bundleIdentifier length]) bundleIdentifier=@"(null)";
            
            NSString* bundleVersion=[info objectForKey:@"CFBundleShortVersionString"];
            if (![bundleVersion length]) bundleVersion=[info objectForKey:@"CFBundleVersion"];
            
            NSString* description=bundleIdentifier;
            if ([bundleVersion length])
            {
                description=[NSString stringWithFormat:@"%@ - %@", bundleVersion, description];
            }
            
            NSArray *components = [path pathComponents];
            NSString* location= [components objectAtIndex:1];
            NSString* endcomp= [components objectAtIndex:[components count] - 2];
            if ([location length])
            {
                if ([endcomp rangeOfString:@"Disabled"].length)
                    description=[NSString stringWithFormat:@"%@ - %@ (Disabled)", description, location];
                else
                    description=[NSString stringWithFormat:@"%@ - %@", description, location];
            }
            
            NSMutableDictionary* itm=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      name, @"name", path, @"path", description, @"description",
                                      bundleIdentifier, @"bundleId", bundleVersion, @"version",
                                      info, @"bundleInfo",
                                      [NSNumber numberWithBool:YES], @"enabled",
                                      [NSNumber numberWithBool:NO], @"fileSystemConflict",
                                      nil];
            
//            NSString* nameandPath = [NSString stringWithFormat:@"%@ - %@", name, path];
//            [dict setObject:itm forKey:nameandPath];
            [dict setObject:itm forKey:bundleIdentifier];
        }
    }
}

// Read all install locations looking for MacForge plugins
- (void)readPlugins:(NSTableView *)pluginTable {
    pluginsArray = [[NSMutableArray alloc] init];
    confirmDelete = [[NSMutableArray alloc] init];
    NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
    
    for (NSString *path in [PluginManager MacEnhancePluginPaths])
        [self readFolder:path :myDict];
    
    NSArray *keys = [myDict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    
    for (NSString *app in sortedKeys) {
        [pluginsArray addObject:[myDict objectForKey:app]];
        [confirmDelete addObject:[NSNumber numberWithBool:false]];
    }
    
    installedPluginDICT = [[NSMutableDictionary alloc] init];
    installedPluginDICT = myDict;
    
    [pluginTable reloadData];
}

+ (NSArray*)arrayOfFoldersInFolder:(NSString*) folder {
    NSFileManager *fm = [NSFileManager defaultManager];
//    NSArray* files = [fm directoryContentsAtPath:folder];
    NSArray* files = [fm contentsOfDirectoryAtPath:folder error:nil];
    NSMutableArray *directoryList = [NSMutableArray arrayWithCapacity:10];
    
    for(NSString *file in files) {
        NSString *path = [folder stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fm fileExistsAtPath:path isDirectory:(&isDir)];
        if(isDir) {
            [directoryList addObject:file];
        }
    }
    
    return directoryList;
}

+ (Boolean)installItem:(NSString*)filePath {
    // Create domain list
    NSArray *domains = [PluginManager MacEnhancePluginPaths];
    
    // Set install location to /Library/Application Support/MacEnhance/Plugins
    NSString *installPath = [NSString stringWithFormat:@"%@/%@", domains[0], filePath.lastPathComponent];
    
    // Set intall location for bundles
    if ([filePath.pathExtension isEqualToString:@"bundle"]) {
        // If the bundle already exist somewhere replace that instead of installing to /Library/Application Support/MacEnhance/Plugins
        for (NSString *path in domains) {
            NSString *possibleBundle = [NSString stringWithFormat:@"%@/%@", path, filePath.lastPathComponent];
            if ([FileManager fileExistsAtPath:possibleBundle])
                installPath = possibleBundle;
        }
    }

    // Set intall location for themes
    if ([filePath.pathExtension isEqualToString:@"theme"])
        installPath = [NSString stringWithFormat:@"/Library/MacEnhance/Themes/%@", filePath.lastPathComponent];

    // Set install location for applications
    if ([filePath.pathExtension isEqualToString:@"app"])
        installPath = [NSString stringWithFormat:@"/Applications/%@", filePath.lastPathComponent];
    
    // Logging
    NSLog(@"\nInstalling : %@\n Destination : %@", filePath, installPath);
    NSError *err;
    
    // Remove item if it already exists
    if ([FileManager fileExistsAtPath:installPath])
        [FileManager removeItemAtPath:installPath error:&err];
    if (err) NSLog(@"%@", err);
    
    // Install the item
    if ([FileManager isReadableFileAtPath:filePath])
        [FileManager copyItemAtPath:filePath toPath:installPath error:&err];
    if (err) NSLog(@"%@", err);

    return true;
}

+ (void)folderinstall:(NSString*)folderPath {
    for (NSString *file in [PluginManager arrayOfFoldersInFolder:folderPath]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", folderPath, file];
        BOOL isDir;
        if ([FileManager fileExistsAtPath:filePath isDirectory:&isDir] && [filePath.pathExtension isEqualToString:@""]) {
            // Looks like a folder... lets see what's inside
            if (![filePath.lastPathComponent isEqualToString:@"__MACOSX"])
                [PluginManager folderinstall:filePath];
        } else {
            // Probably a file, lets try to install it
            [PluginManager installItem:filePath];
        }
    }
}

// Try to update or install a plugin given a bundle plist and a repo
- (Boolean)pluginUpdateOrInstallWithProgress:(NSDictionary *)item :(NSString *)repo :(NSButton *)button :(NSProgressIndicator *)progress {
    if (progress) {
        progressObject = progress;
        progressObject.hidden = false;
        progressObject.doubleValue = 0;
    }
    
    if (button) {
        downloadButton = button;
        downloadButton.enabled = false;
        downloadButton.title = @"";
        
        if (progressObject)
            [progressObject setFrameOrigin:CGPointMake(downloadButton.frame.origin.x + downloadButton.frame.size.width/2 - progressObject.frame.size.width/2, downloadButton.frame.origin.y + downloadButton.frame.size.height/2 - progressObject.frame.size.height/2)];

//            [progressObject setFrameOrigin:CGPointMake(downloadButton.frame.origin.x + downloadButton.frame.size.width + 10, downloadButton.frame.origin.y + downloadButton.frame.size.height/2 - progressObject.frame.size.height/2)];
    }
    
    _plugin = item;
    Boolean success = false;

    // 1
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURL *dataUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repo, [item objectForKey:@"filename"]]];

    // 2
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL: dataUrl];

    // 3
    [dataTask resume];
    
    return success;
}

- (Boolean)pluginDownloaded:(NSData*)data {
    if (progressObject) {
        progressObject.hidden = true;
        progressObject.doubleValue = 0;
    }
    
    // Downloaded zip file
    NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [_plugin objectForKey:@"package"], [_plugin objectForKey:@"version"]];
    [data writeToFile:temp atomically:YES];
    
    // Create folder to unzip contents to
    NSString *unzipDir = [NSString stringWithFormat:@"/tmp/macenhance_extracted/%@_%@", [_plugin objectForKey:@"package"], [_plugin objectForKey:@"version"]];
    BOOL isDir;
    if(![FileManager fileExistsAtPath:unzipDir isDirectory:&isDir])
        if(![FileManager createDirectoryAtPath:unzipDir withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", unzipDir);
    
    // Unzip download
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", unzipDir]];
    [task waitUntilExit];
    if ([task terminationStatus] == 0) {
        // presumably the only case where we've successfully installed
        // ???
        //                success = true;
    }
    
    // Try to install the contents
    [PluginManager folderinstall:unzipDir];
    
    if (downloadButton) {
        downloadButton.enabled = true;
        downloadButton.title = @"OPEN";
    }
    
    // Update the installed plugins list
    [self readPlugins:nil];
    
    return true;
}

// Try to update or install a plugin given a bundle plist and a repo
- (Boolean)pluginUpdateOrInstall:(NSDictionary *)item :(NSString *)repo withCompletionHandler:(void (^)(BOOL result))completionBlock {
    __block Boolean success = false;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Get installation URL
        NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repo, [item objectForKey:@"filename"]]];

        // SynchronousRequest to grab the data
        NSURLRequest *request = [NSURLRequest requestWithURL:installURL];
        NSError *error;
        NSURLResponse *response;

        // Try to download file
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!result) {
            // Download failed
            NSLog(@"Error : %@", error);
        } else {
            // Downloaded zip file
            NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
            [result writeToFile:temp atomically:YES];
            
            // Create folder to unzip contents to
            NSString *unzipDir = [NSString stringWithFormat:@"/tmp/macenhance_extracted/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
            BOOL isDir;
            if(![FileManager fileExistsAtPath:unzipDir isDirectory:&isDir])
                if(![FileManager createDirectoryAtPath:unzipDir withIntermediateDirectories:YES attributes:nil error:NULL])
                    NSLog(@"Error: Create folder failed %@", unzipDir);
            
            // Unzip download
            NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", unzipDir]];
            [task waitUntilExit];
            if ([task terminationStatus] == 0) {
                success = true;
            }
            
            // Try to install the contents
            [PluginManager folderinstall:unzipDir];
            
            // Update the installed plugins list
            [self readPlugins:nil];
        }
                       
        // This is your completion handler
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (completionBlock)
                completionBlock(success);
        });
    });
    
    return success;
}

// Delete a plugin given it's plist
- (Boolean)pluginDelete:(NSDictionary*)item {
    int pos = 0;
    bool found = false;
    
    // Make sure out pluginsArray is up to date
    [self readPlugins:nil];
    
    // Look for the plugin
    for (NSDictionary* dict in pluginsArray) {
        if ([[dict objectForKey:@"bundleId"] isEqualToString:[item objectForKey:@"package"]]) {
            found = true;
            break;
        }
        pos += 1;
    }
    
    // If we found the plugin delete it
    if (found) {
        NSDictionary* obj = [pluginsArray objectAtIndex:pos];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [FileManager trashItemAtURL:url resultingItemURL:&trash error:&error];
        if (error == noErr)
            return true;
    }
    
    return false;;
}

// Reveal a plugin in Finder
- (Boolean)pluginRevealFinder:(NSDictionary*)item {
    int pos = 0;
    bool found = false;
    
    // Make sure out pluginsArray is up to date
    [self readPlugins:nil];
    
    NSString *bundleID = [item objectForKey:@"package"];
    
    for (NSDictionary* dict in pluginsArray) {
        if ([[dict objectForKey:@"bundleId"] isEqualToString:bundleID]) {
            found = true;
            break;
        }
        pos += 1;
    }
    
    if (found) {
        NSDictionary* obj = [pluginsArray objectAtIndex:pos];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        [Workspace activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
        return true;
    }
    
    if ([Workspace URLForApplicationWithBundleIdentifier:bundleID]) {
        NSURL *fileURL = [Workspace URLForApplicationWithBundleIdentifier:bundleID];
        
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        [dict setObject:@[] forKey:NSWorkspaceLaunchConfigurationArguments];
        
//        NSLog(@"------ %@", [NSRunningApplication runningApplicationsWithBundleIdentifier:[item objectForKey:@"package"]]);
//        NSLog(@"------ %@", [NSString stringWithFormat:@"%@/Contents/MacOS/%@", fileURL.path, fileURL.path.lastPathComponent.stringByDeletingPathExtension]);

        if ([NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID].count == 0) {
            NSError *err;
            [Workspace launchApplicationAtURL:fileURL options:NSWorkspaceLaunchDefault configuration:dict error:&err];
//            [Workspace launchApplication:fileURL.path];
            if (err)
                NSLog(@"------ %@", err);
        } else {
            [Workspace activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
        }
    }
    
    return false;;
}

-(void)pluginGetIcon:(NSString*)string withCompletion:(void(^)(BOOL success, NSError* error, id responce))completion
{
    NSString *str =[NSString stringWithFormat:@"MY FUNTn CALLBACK %@",string];
    if (completion){
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES,nil,str); // here that call when method complete
        });
    }
}

// Fetch an icon for a bundle given it's plist
+ (NSImage*)pluginGetIcon:(NSDictionary*)plist {
    NSImage* result = nil;
    
    // Get the list of targets for the bundle
    NSArray* targets = [[NSArray alloc] init];
    if ([plist objectForKey:@"targets"]) {
        targets = [plist objectForKey:@"targets"];
    } else {
        NSDictionary* info = [plist objectForKey:@"bundleInfo"];
        targets = [info objectForKey:@"SIMBLTargetApplications"];
    }
    
    // Load custom local icon if it exists
    NSString *bundle_path = [plist objectForKey:@"path"];
    if ([bundle_path length]) {
        result = [Workspace iconForFile:bundle_path];
        if (result) return result;
    }
    
    // Old loading of custom bundle icon
    NSString* iconPath = [NSString stringWithFormat:@"%@/Contents/icon.icns", bundle_path];
//    if ([iconPath length]) {
//        result = [[NSImage alloc] initWithContentsOfFile:iconPath];
//        if (result) return result;
//    }
    
//    for (NSDictionary* targetApp in targets) {
//        iconPath = [targetApp objectForKey:@"BundleIdentifier"];
//        iconPath = [Workspace absolutePathForAppBundleWithIdentifier:iconPath];
//        if ([iconPath length]) {
//            result = [Workspace iconForFile:iconPath];
//            if (result) return result;
//        }
//    }
    
//    NSLog(@"%@%@", [plist objectForKey:@"sourceURL"], [plist objectForKey:@"icon"]);
    
    // Try finding an icon based on target applications
    // We will always use the first icon found
    for (NSDictionary* targetApp in targets) {
        iconPath = [targetApp objectForKey:@"BundleIdentifier"];
        iconPath = [Workspace absolutePathForAppBundleWithIdentifier:iconPath];

        if ([iconPath length]) {
            // Use specific icon for Notification Center
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.notificationcenterui"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Notifications.icns"];
                if (result) return result;
            }

            // Use specific icon for Sysytem UI Server
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.systemuiserver"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/Assistant.icns"];
                if (result) return result;
            }

            // Use specific icon for LoginWindow
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.loginwindow"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GroupIcon.icns"];
                if (result) return result;
            }
            
            // Not sure what I'm doing here 🤷‍♂️
            result = [Workspace iconForFile:iconPath];
//            NSData *imgDataOne = [result TIFFRepresentation];
//            NSData *imgDataTwo = [[Workspace iconForFile:@"/System/Library/CoreServices/loginwindow.app"] TIFFRepresentation];
//            if ([imgDataOne isEqualToData:imgDataTwo])
//                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
            if (result) return result;
        }
    }
    
    // If we don't find any valid icon then use the default BUNDLE/KEXT icon
    result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
    return result;
}

// Update icon and send message to update DockTilePlugin also
- (void)updateApplicationIcon {
    // Get the number of apps that need an update
    NSString *udCount = [NSString stringWithFormat:@"%ld", (unsigned long)[needsUpdate count]];
    
    // If updateCount is 0 set it to an empty string so it will clear badge
    if ([udCount isEqualToString:@"0"]) udCount = @"";
    
    // Try updating the Dock tile
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDockTile *myTile = [NSApp dockTile];
        [myTile setBadgeLabel:udCount];
    });
    
    // Update com.w0lf.MacForge > updateCount
    CFPreferencesSetAppValue(CFSTR("updateCount"), (CFPropertyListRef)udCount, CFSTR("com.w0lf.MacForge"));
    CFPreferencesAppSynchronize(CFSTR("com.w0lf.MacForge"));
    
    // Send notirifcation to DockTilePlugin to update
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeDockTileUpdate" object:@""];
}

// Check for plugin updates and automatically install them
- (void)checkforPluginUpdatesAndInstall:(NSTableView*)table {
    [self checkforPluginUpdates:table];
    if (needsUpdate.count > 0) {
        for (NSString *key in needsUpdate.allKeys) {
            NSDictionary *itemDict = [needsUpdate objectForKey:key];
            [self pluginUpdateOrInstall:itemDict :[itemDict objectForKey:@"sourceURL"] withCompletionHandler:^(BOOL res) {
                if (res)
                    [needsUpdate removeObjectForKey:key];
            }];
        }
        [self updateApplicationIcon];
    }
}

// Check for updates and retun needsupdate array
- (NSMutableDictionary*)getNeedsUpdate {
    return needsUpdate;
}

- (NSMutableDictionary*)getInstalledPlugins {
    return installedPluginDICT;
}

- (void)checkforPluginUpdates:(NSTableView *)table :(NSButton *)counter {
    [self checkforPluginUpdates:table];
    dispatch_async(dispatch_get_main_queue(), ^{
        [counter setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self->needsUpdate.count]];
        [counter sizeToFit];
    });
}

+ (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB {
    if ((versionA.length <= 0) && (versionB.length <= 0)) {
        return NSOrderedSame;
    } else if (versionA.length <= 0) {
        return NSOrderedAscending;
    } else if (versionB.length <= 0) {
        return NSOrderedDescending;
    }
    
    NSArray *partsA = [versionA componentsSeparatedByString:@"."];
    NSArray *partsB = [versionB componentsSeparatedByString:@"."];
    
    NSUInteger sameCount = MIN(partsA.count, partsB.count);
    
    for (NSUInteger i = 0; i < sameCount; ++i) {
        NSString *partA = [partsA objectAtIndex:i];
        NSString *partB = [partsB objectAtIndex:i];
        if (partA.longLongValue < partB.longLongValue) {
            return NSOrderedAscending;
        } else if (partA.longLongValue > partB.longLongValue) {
            return NSOrderedDescending;
        }
    }
    
    if (partsA.count < partsB.count) {
        return NSOrderedAscending;
    } else if (partsA.count > partsB.count) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

// Check for plugin updates and update the application icon badge
- (void)checkforPluginUpdates:(NSTableView*)table {
    needsUpdate = [[NSMutableDictionary alloc] init];
    [self readPlugins:nil];
    
    NSDictionary *plugins = [[NSDictionary alloc] initWithDictionary:[installedPluginDICT copy]];
    CFPreferencesAppSynchronize(CFSTR("com.w0lf.MacForge"));
    NSArray *sourceURLS = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("sources"), CFSTR("com.w0lf.MacForge")));
    
    NSMutableDictionary *sourceDICTS = [[NSMutableDictionary alloc] init];
    for (NSString *source in sourceURLS) {
        NSURL* data = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", source]];
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithContentsOfURL:data];
        if (dic != nil) {
            for (NSString *key in dic) {
                NSMutableDictionary *bundle = [dic objectForKey:key];
                [bundle setObject:source forKey:@"sourceURL"];
            }
            [sourceDICTS addEntriesFromDictionary:[dic copy]];
        }
    }
    
    for (NSString* key in plugins) {
        id value = [plugins objectForKey:key];
        id bundleID = [value objectForKey:@"bundleId"];
        id localVersion = [value objectForKey:@"version"];
        
//        NSLog(@"%@ : %@", bundleID, localVersion);
        
        if ([sourceDICTS objectForKey:bundleID]) {
            NSDictionary *bundleInfo = [[NSDictionary alloc] initWithDictionary:[sourceDICTS objectForKey:bundleID]];
            id updateVersion = [bundleInfo objectForKey:@"version"];
            NSComparisonResult res = [PluginManager compareVersion:(NSString*)updateVersion toVersion:(NSString*)localVersion];
            if (res == 1)
                [needsUpdate setObject:bundleInfo forKey:bundleID];
        }
    }
    
    if (table != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [table reloadData];
        });
    }
        
    [self updateApplicationIcon];
}

// Check for plugin updates and update the application icon badge
- (NSUserNotification*)checkforPluginUpdatesNotify {
    needsUpdate = [[NSMutableDictionary alloc] init];
    [self readPlugins:nil];
    
    NSDictionary *plugins = [[NSDictionary alloc] initWithDictionary:[installedPluginDICT copy]];
    CFPreferencesAppSynchronize(CFSTR("com.w0lf.MacForge"));
    NSArray *sourceURLS = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("sources"), CFSTR("com.w0lf.MacForge")));
    
    NSMutableDictionary *sourceDICTS = [[NSMutableDictionary alloc] init];
    for (NSString *source in sourceURLS) {
        NSURL* data = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", source]];
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithContentsOfURL:data];
        if (dic != nil) {
            for (NSString *key in dic) {
                NSMutableDictionary *bundle = [dic objectForKey:key];
                [bundle setObject:source forKey:@"sourceURL"];
            }
            [sourceDICTS addEntriesFromDictionary:[dic copy]];
        }
    }
    
    for (NSString* key in plugins) {
        id value = [plugins objectForKey:key];
        id bundleID = [value objectForKey:@"bundleId"];
        id localVersion = [value objectForKey:@"version"];
        if ([sourceDICTS objectForKey:bundleID]) {
            NSDictionary *bundleInfo = [[NSDictionary alloc] initWithDictionary:[sourceDICTS objectForKey:bundleID]];
            id updateVersion = [bundleInfo objectForKey:@"version"];
            NSComparisonResult res = [PluginManager compareVersion:(NSString*)updateVersion toVersion:(NSString*)localVersion];
            if (res == 1)
                [needsUpdate setObject:bundleInfo forKey:bundleID];
        }
    }
        
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.w0lf.MacForgeHelper"]) {
        CFPreferencesAppSynchronize(CFSTR("com.w0lf.MacForge"));
        NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
        if ([[GUIDefaults objectForKey:@"prefPluginNotifications"] boolValue]) {
            NSString *packages = @"";
            for (NSString *key in needsUpdate.allKeys) {
                NSDictionary *dic = [needsUpdate objectForKey:key];
                if (packages.length > 0) packages = [packages stringByAppendingString:@", "];
                packages = [packages stringByAppendingString:[dic objectForKey:@"name"]];
            }
            
            notification.title = @"Plugins need updating";
            notification.subtitle = @"";
            notification.informativeText = packages;
            notification.soundName = NSUserNotificationDefaultSoundName;
            notification.contentImage = [NSImage imageNamed:@"icon_Upload-Information-icon_24x24"];
        }
    }
        
    [self updateApplicationIcon];
    
    return notification;
}

@end
