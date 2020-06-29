//
//  PluginManager.m
//  PluginManager
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "FConvenience.h"
#import "MF_PluginManager.h"
#import "MF_Plugin.h"
#import "MF_defines.h"

@implementation MF_PluginManager

// Shared instance if needed
+ (MF_PluginManager*) sharedInstance {
    static MF_PluginManager* pData = nil;
    if (pData == nil)
        pData = [[MF_PluginManager alloc] init];
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
    NSArray *paths = @[libPathENB, libPathDIS, usrPathENB, usrPathDIS];
    return paths;
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

// Look at a folder and find all MacForge plugins within it and add them to the given Dictionatry
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
    NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
    
    for (NSString *path in [MF_PluginManager MacEnhancePluginPaths])
        [self readFolder:path :myDict];
    
    NSArray *keys = [myDict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    
    for (NSString *app in sortedKeys) {
        [pluginsArray addObject:[myDict objectForKey:app]];
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

// Try to install all item in an array of file paths
- (void)installBundles:(NSArray*)pathArray {
    for (NSString* path in pathArray)
        [MF_PluginManager installItem:path];
}

+ (Boolean)installItem:(NSString*)filePath {
    // Create domain list
    NSArray *domains = [MF_PluginManager MacEnhancePluginPaths];
    
    // Set install location to /Library/Application Support/MacEnhance/Plugins
    NSString *installPath = [NSString stringWithFormat:@"%@/%@", domains[0], filePath.lastPathComponent];
    NSDictionary *defaults = [NSUserDefaults.standardUserDefaults persistentDomainForName:@"com.macenhance.MacForge"];
    if ([[defaults valueForKey:@"prefInstallToUser"] boolValue]) {
        installPath = [NSString stringWithFormat:@"%@/%@", domains[2], filePath.lastPathComponent];
        if (![FileManager fileExistsAtPath:domains[2] isDirectory:nil])
            [FileManager createDirectoryAtPath:domains[2] withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    // Set intall location for bundles
    if ([filePath.pathExtension isEqualToString:@"bundle"]) {
        
//        NSLog(@"%@", [[NSBundle bundleWithPath:filePath] infoDictionary]);
        NSDictionary *dict = [[NSBundle bundleWithPath:filePath] infoDictionary];
        
        // MacForge plugin
        if ([dict valueForKey:@"SIMBLTargetApplications"]) {
            
            // If the bundle already exist somewhere replace that instead of installing to /Library/Application Support/MacEnhance/Plugins
            for (NSString *path in domains) {
                NSString *possibleBundle = [NSString stringWithFormat:@"%@/%@", path, filePath.lastPathComponent];
                if ([FileManager fileExistsAtPath:possibleBundle])
                    installPath = possibleBundle;
            }
            
        } else {
            
            // Pref bundle
            if ([dict valueForKey:@"MacForgePrefBundle"]) {
                installPath = [@"/Library/Application Support/MacEnhance/Preferences/" stringByAppendingString:filePath.lastPathComponent];
            }
            
            // System Theme bundle
            if ([dict valueForKey:@"MacForgeThemeBundle"]) {
                installPath = [@"/Library/Application Support/MacEnhance/Themes/" stringByAppendingString:filePath.lastPathComponent];
            }
            
            // cDock Theme bundle
            if ([dict valueForKey:@"cDockThemeBundle"]) {
                installPath = [@"~/Library/Application Support/cDock/themes" stringByExpandingTildeInPath];
                installPath = [installPath stringByAppendingFormat:@"/%@", filePath.lastPathComponent];
            }
            
        }
    }

    // Set intall location for Mousecape cape files
    if ([filePath.pathExtension isEqualToString:@"cape"]) {
        installPath = [NSString stringWithFormat:@"~/Library/Application Support/Mousecape/capes/%@", filePath.lastPathComponent];
        installPath = [installPath stringByExpandingTildeInPath];
        
        // Make the cape folder if needed
        NSString *capefolder = [@"~/Library/Application Support/Mousecape/capes" stringByExpandingTildeInPath];
        if (![FileManager fileExistsAtPath:capefolder isDirectory:nil])
            [FileManager createDirectoryAtPath:capefolder withIntermediateDirectories:true attributes:nil error:nil];
    }

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
    for (NSString *file in [MF_PluginManager arrayOfFoldersInFolder:folderPath]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", folderPath, file];
        BOOL isDir;
        if ([FileManager fileExistsAtPath:filePath isDirectory:&isDir] && [filePath.pathExtension isEqualToString:@""]) {
            // Looks like a folder... lets see what's inside
            if (![filePath.lastPathComponent isEqualToString:@"__MACOSX"])
                [MF_PluginManager folderinstall:filePath];
        } else {
            // Probably a file, lets try to install it
            [MF_PluginManager installItem:filePath];
        }
    }
    
    for (NSString *file in [FileManager contentsOfDirectoryAtPath:folderPath error:nil]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", folderPath, file];
        if ([[file pathExtension] isEqualToString:@"cape"])
            [MF_PluginManager installItem:filePath];
    }
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
    [MF_PluginManager folderinstall:unzipDir];
    
    if (downloadButton) {
        downloadButton.enabled = true;
        downloadButton.title = @"OPEN";
    }
    
    // Update the installed plugins list
    [self readPlugins:nil];
    
    return true;
}

// Try to update or install a plugin given a bundle plist and a repo
- (Boolean)pluginUpdateOrInstall:(NSDictionary *)item withButton:(NSButton *)button andProgress:(NSProgressIndicator *)progress {
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
            [progressObject setFrameOrigin:CGPointMake(downloadButton.frame.origin.x + downloadButton.frame.size.width/2 - progressObject.frame.size.width/2,
                                                       downloadButton.frame.origin.y + downloadButton.frame.size.height/2 - progressObject.frame.size.height/2)];
    }
    
    _plugin = item;
    Boolean success = false;

    // 1
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURL *dataUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", MF_REPO_URL, [item objectForKey:@"filename"]]];

    // 2
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL: dataUrl];

    // 3
    [dataTask resume];
    
    return success;
}

// Try to update or install a plugin given a bundle plist and a repo
- (Boolean)pluginUpdateOrInstall:(NSDictionary *)item withCompletionHandler:(void (^)(BOOL result))completionBlock {
    __block Boolean success = false;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Get installation URL
        NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", MF_REPO_URL, [item objectForKey:@"filename"]]];

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
            [MF_PluginManager folderinstall:unzipDir];
            
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

- (NSString*)pluginLocalPath:(NSString *)bundleID {
    NSString *result;
        
    // Maybe it's a .app
    NSURL *fileURL = [Workspace URLForApplicationWithBundleIdentifier:bundleID];
    
    // If it's in /Applications consider it installed
    if (!result) {
        NSArray *comp = fileURL.path.pathComponents;
        if (comp.count > 0)
            if ([fileURL.path.pathComponents[1] containsString:@"Applications"])
                result = fileURL.path;
    }
    
    // Maybe it's a .bundle
    if (!result) {
        if ([installedPluginDICT.allKeys containsObject:bundleID])
            result = installedPluginDICT[bundleID][@"path"];
    }
    
    // Maybe it's a .theme
    if (!result) {
        NSString *themePath = [@"/Library/Application Support/MacEnhance/Themes" stringByAppendingFormat:@"%@.bundle", bundleID];
        if ([FileManager fileExistsAtPath:themePath])
            result = themePath;
    }
    
    // Maybe it's a .cape
    if (!result) {
        NSString *capeFolder = [@"~/Library/Application Support/Mousecape/capes" stringByExpandingTildeInPath];
        NSString* capePath = [capeFolder stringByAppendingFormat:@"/%@.cape", bundleID];
        for (NSString* file in [FileManager contentsOfDirectoryAtPath:capeFolder error:nil])
            if ([file containsString:bundleID])
                capePath = [capeFolder stringByAppendingFormat:@"/%@", file];
        
        if ([FileManager fileExistsAtPath:capePath])
            result = capePath;
    }
    
    if (!result) result = @"";
    return result;
}

// Delete a plugin given it's plist
- (Boolean)pluginDelete:(NSDictionary*)item {
    [self readPlugins:nil];
    NSError* error;
    NSURL* trash;
    NSURL *localPath = [NSURL fileURLWithPath:[self pluginLocalPath:item[@"package"]]];
    if (localPath.path.length)
        [FileManager trashItemAtURL:localPath resultingItemURL:&trash error:&error];
    return false;
}

// Reveal a plugin in Finder
- (Boolean)pluginRevealFinder:(NSDictionary*)item {
    [self readPlugins:nil];
    NSURL *localPath = [NSURL fileURLWithPath:[self pluginLocalPath:item[@"package"]]];
    if (localPath.path.length)
        [Workspace activateFileViewerSelectingURLs:[NSArray arrayWithObject:localPath]];
    return false;;
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
    
    // Try finding an icon based on target applications we will always use the first icon found
    for (NSDictionary* targetApp in targets) {
        NSString *iconPath = [Workspace absolutePathForAppBundleWithIdentifier:targetApp[@"BundleIdentifier"]];

        if ([iconPath length]) {
            // Custom icon for cape files
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.alexzielenski.Mousecape"]) {
                result = [NSImage imageNamed:@"NSArrowCursor"];
                if (result) return result;
            }
            
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
            
            // Use app icon
            result = [Workspace iconForFile:iconPath];
            if (result) return result;
        } else {
            // Fix icon for Messages on macOS 11
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.iChat"]) {
                iconPath = [Workspace absolutePathForAppBundleWithIdentifier:@"com.apple.MobileSMS"];
                result = [Workspace iconForFile:iconPath];
                if (result) return result;
            }
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
    
    // Update com.macenhance.MacForge > updateCount
    CFPreferencesSetAppValue(CFSTR("updateCount"), (CFPropertyListRef)udCount, CFSTR("com.macenhance.MacForge"));
    CFPreferencesAppSynchronize(CFSTR("com.macenhance.MacForge"));
    
    // Send notirifcation to DockTilePlugin to update
    [NSDistributedNotificationCenter.defaultCenter postNotificationName:@"com.macenhance.MacForgeDockTileUpdate" object:@""];
}

// Check for plugin updates and automatically install them
- (void)checkforPluginUpdatesAndInstall:(NSTableView*)table {
    [self checkforPluginUpdates:table];
    if (needsUpdate.count > 0) {
        for (NSString *key in needsUpdate.allKeys) {
            NSDictionary *itemDict = [needsUpdate objectForKey:key];
            [self pluginUpdateOrInstall:itemDict withCompletionHandler:^(BOOL res) {
                if (res)
                    [self->needsUpdate removeObjectForKey:key];
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

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)installPackages {
    if (needsUpdate.count > 0) {
        for (NSString *key in needsUpdate.allKeys) {
            NSDictionary *itemDict = [needsUpdate objectForKey:key];
            [self pluginUpdateOrInstall:itemDict withCompletionHandler:^(BOOL res) {
                if (res) {
                    [self->needsUpdate removeObjectForKey:key];
                    [self updateApplicationIcon];
                }
            }];
        }
    }
}

- (void)notifyUser:(Boolean)shouldInstall {
    CFPreferencesAppSynchronize(CFSTR("com.macenhance.MacForge"));
    NSInteger updateCounter = CFPreferencesGetAppIntegerValue(CFSTR("updateCount"), CFSTR("com.macenhance.MacForge"), NULL);
    if (updateCounter != 0) {
        // New updates found
        if (updateCounter != needsUpdate.count) {
            NSUserNotification *notification = NSUserNotification.new;
            NSString *packages = @"";
            for (NSString *key in needsUpdate.allKeys) {
                NSDictionary *dic = [needsUpdate objectForKey:key];
                if (packages.length > 0) packages = [packages stringByAppendingString:@", "];
                packages = [packages stringByAppendingString:[dic objectForKey:@"name"]];
            }
            
            notification.identifier = [@"com.macenhance.MacForge-" stringByAppendingString:NSProcessInfo.processInfo.globallyUniqueString];
            notification.title = @"Packages need updating";
            if (shouldInstall) notification.title = @"Packages updated";
            notification.subtitle = @"";
            notification.informativeText = packages;
            notification.soundName = NSUserNotificationDefaultSoundName;
                                              
            NSUserNotificationCenter *c = NSUserNotificationCenter.defaultUserNotificationCenter;
            [c setDelegate:self];
            [c deliverNotification:notification];
        }
    }
}

- (NSString*)getItemLocalVersion:(NSString*)bundleID {
    NSString *localVersion = @"failed";
    NSString *localPath = @"";
    if (bundleID.length) localPath = [self pluginLocalPath:bundleID];
    if (localPath.length) {
        NSString *ext = localPath.pathExtension;
        
        if ([ext isEqualToString:@"cape"]) {
            
            NSDictionary *d = [[NSDictionary alloc] initWithContentsOfFile:localPath];
            NSObject *test = d[@"CapeVersion"];
            localVersion = [NSString stringWithFormat:@"%@", test];
            
        } else {
            
            NSDictionary *dic = [NSBundle bundleWithPath:localPath].infoDictionary;
            localVersion = [dic objectForKey:@"CFBundleShortVersionString"];
            if ([localVersion isEqualToString:@""])
                localVersion = [dic objectForKey:@"CFBundleVersion"];
            
        }
    }
    return localVersion;
}

// Check for plugin updates and update the application icon badge
// Also send notification if option is enabled
// Also install if option is enabled
- (void)checkforPluginUpdates:(NSTableView*)table {
    needsUpdate = NSMutableDictionary.new;
    [self readPlugins:nil];
    
    NSURL* data = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages.plist", @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo"]];
    NSMutableDictionary* sourceDict = [NSMutableDictionary.alloc initWithContentsOfURL:data];
    
    for (NSString *key in sourceDict.allKeys) {
        NSDictionary *itemInfo = sourceDict[key];
        NSString *bundleID = itemInfo[@"package"];
        NSString *webVersion = itemInfo[@"version"];
        NSString *localVersion = [self getItemLocalVersion:bundleID];
        if (![localVersion isEqualToString:@"failed"]) {
            if (![localVersion isEqualToString:webVersion]) {
//                [needsUpdate setObject:itemInfo forKey:bundleID];
                NSComparisonResult res = [MF_PluginManager compareVersion:(NSString*)webVersion toVersion:(NSString*)localVersion];
                if (res == 1)
                    [needsUpdate setObject:itemInfo forKey:bundleID];
            }
        }
    }

    if (table != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            table.tableColumns.firstObject.maxWidth = 10000;
            [table reloadData];
        });
    }
    
    // Extra
    CFPreferencesAppSynchronize(CFSTR("com.macenhance.MacForge"));
    NSDictionary *defaults = [NSUserDefaults.standardUserDefaults persistentDomainForName:@"com.macenhance.MacForge"];
    Boolean shouldInstall = [defaults[@"prefPluginAutoUpdate"] boolValue];
    Boolean shouldNotify = [defaults[@"prefPluginNotifications"] boolValue];
    
    [self updateApplicationIcon];
    
    // Install
    if (shouldInstall) [self installPackages];
    
    // Notify
    if (shouldNotify) [self notifyUser:shouldInstall];
}

@end
