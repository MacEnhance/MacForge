//
//  shareClass.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import "shareClass.h"
#import "AppDelegate.h"

extern AppDelegate *myDelegate;
extern NSMutableArray *pluginsArray;
extern NSMutableArray *confirmDelete;
extern NSMutableDictionary *installedPluginDICT;
extern NSMutableDictionary *needsUpdate;


@implementation shareClass

+ (shareClass*) sharedInstance {
    static shareClass* pData = nil;
    if (pData == nil)
        pData = [[shareClass alloc] init];
    return pData;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)installBundles:(NSArray*)pathArray {
    //    NSLog(@"%@", pathArray);
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    for (NSString* path in pathArray) {
        if ([[path pathExtension] isEqualToString:@"bundle"]) {
            NSArray* pathComp=[path pathComponents];
            NSString* name=[pathComp objectAtIndex:[pathComp count] - 1];
            NSString* libPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins/%@", libSupport, name];
            //        NSLog(@"\n%@\n%@", libPath, path);
            [self replaceFile:path :libPath];
        }
        
        if ([[path pathExtension] isEqualToString:@"app"]) {
            NSArray* pathComp=[path pathComponents];
            NSString* name=[pathComp objectAtIndex:[pathComp count] - 1];
            NSString* libPath = [NSString stringWithFormat:@"/Applications/%@", name];
            //        NSLog(@"\n%@\n%@", libPath, path);
            [self replaceFile:path :libPath];
        }
    }
}

- (void)replaceFile:(NSString*)start :(NSString*)end {
    NSError* error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[end stringByDeletingLastPathComponent]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[end stringByDeletingLastPathComponent] withIntermediateDirectories:true attributes:nil error:&error];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:end]) {
        //        NSLog(@"File Exists");
        [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:end] withItemAtURL:[NSURL fileURLWithPath:start] backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&error];
    } else {
        //        NSLog(@"File Doesn't Exist");
        [[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:start] toURL:[NSURL fileURLWithPath:end] error:&error];
    }
    //    NSLog(@"%@", error);
}

- (void)readFolder:(NSString *)str :(NSMutableDictionary *)dict {
    NSArray *appFolderContents = [[NSArray alloc] init];
    appFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:str error:nil];
    
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
            
            NSString* nameandPath = [NSString stringWithFormat:@"%@ - %@", name, path];
            
            [dict setObject:itm forKey:nameandPath];
        }
    }
}

- (void)readPlugins:(NSTableView *)pluginTable
{
    pluginsArray = [[NSMutableArray alloc] init];
    confirmDelete = [[NSMutableArray alloc] init];
    NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
    
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
    
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSString* libPathDIS = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", libSupport];
    
    NSString* usrPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", usrSupport];
    NSString* usrPathDIS = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", usrSupport];
    
    NSString* OpeePath = [NSString stringWithFormat:@"/Library/Opee/Extensions"];
    
    [self readFolder:libPathENB :myDict];
    [self readFolder:libPathDIS :myDict];
    
    [self readFolder:usrPathENB :myDict];
    [self readFolder:usrPathDIS :myDict];
    
    [self readFolder:OpeePath :myDict];
    
    NSArray *keys = [myDict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    //    sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    
    for (NSString *app in sortedKeys)
    {
        [pluginsArray addObject:[myDict objectForKey:app]];
        [confirmDelete addObject:[NSNumber numberWithBool:false]];
    }
    
    installedPluginDICT = [[NSMutableDictionary alloc] init];
    installedPluginDICT = myDict;
    
    [pluginTable reloadData];
}

- (void)pluginInstall:(NSDictionary*)item :(NSString*)repo
{
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repo, [item objectForKey:@"filename"]]];
    
    //SynchronousRequest to grab the data
    NSURLRequest *request = [NSURLRequest requestWithURL:installURL];
    NSError *error;
    NSURLResponse *response;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (!result) {
        // Download failed
        NSLog(@"Error");
    } else {
        // Install downloaded file
        
        NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
        [result writeToFile:temp atomically:YES];
        NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
        NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSString* libSupport = [[libDomain objectAtIndex:0] path];
        NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
        
        NSArray *domains = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport],
                            [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", libSupport],
                            [NSString stringWithFormat:@"%@/SIMBL/Plugins", usrSupport],
                            [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", usrSupport],
                            nil];
        
        NSString *installPath = domains[0];
        
        for (NSString *path in domains) {
            NSString *possibleBundle = [NSString stringWithFormat:@"%@/%@.bundle", path, [item objectForKey:@"name"]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:possibleBundle])
                installPath = path;
        }
        
        NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", installPath]];
        [task waitUntilExit];
        shareClass* t = [[shareClass alloc] init];
        [t readPlugins:nil];
        
//        NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
//        [result writeToFile:temp atomically:YES];
//        NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
//        NSString* libSupport = [[libDomain objectAtIndex:0] path];
//        NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
//        NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", libPathENB]];
//        [task waitUntilExit];
//        shareClass* t = [[shareClass alloc] init];
//        [t readPlugins:nil];
    }
}

- (void)pluginUpdate:(NSDictionary*)item :(NSString*)repo
{
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repo, [item objectForKey:@"filename"]]];
    
    //SynchronousRequest to grab the data
    NSURLRequest *request = [NSURLRequest requestWithURL:installURL];
    NSError *error;
    NSURLResponse *response;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (!result) {
        // Download failed
        NSLog(@"Error");
    } else {
        NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
        [result writeToFile:temp atomically:YES];
        NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
        NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSString* libSupport = [[libDomain objectAtIndex:0] path];
        NSString* usrSupport = [[usrDomain objectAtIndex:0] path];

        NSArray *domains = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport],
                            [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", libSupport],
                            [NSString stringWithFormat:@"%@/SIMBL/Plugins", usrSupport],
                            [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", usrSupport],
                            nil];
        
        NSString *installPath = domains[0];
        
        for (NSString *path in domains) {
            NSString *possibleBundle = [NSString stringWithFormat:@"%@/%@.bundle", path, [item objectForKey:@"name"]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:possibleBundle])
                installPath = path;
        }
        
//        NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
        
        NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", installPath]];
        [task waitUntilExit];
        shareClass* t = [[shareClass alloc] init];
        [t readPlugins:nil];
    }
}

- (void)pluginDelete:(NSDictionary*)item {
    int pos = 0;
    bool found = false;
    for (NSDictionary* dict in pluginsArray) {
        if ([[dict objectForKey:@"bundleId"] isEqualToString:[item objectForKey:@"package"]])
        {
            found = true;
            break;
        }
        pos += 1;
    }
    
    if (found) {
        NSDictionary* obj = [pluginsArray objectAtIndex:pos];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
}

- (NSImage*)getbundleIcon:(NSDictionary*)plist {
    NSImage* result = nil;
    NSArray* targets = [[NSArray alloc] init];
    if ([plist objectForKey:@"targets"]) {
        targets = [plist objectForKey:@"targets"];
    } else {
        NSDictionary* info = [plist objectForKey:@"bundleInfo"];
        targets = [info objectForKey:@"SIMBLTargetApplications"];
    }
    
    NSString* iconPath = [NSString stringWithFormat:@"%@/Contents/icon.icns", [plist objectForKey:@"path"]];
    if ([iconPath length]) {
        result = [[NSImage alloc] initWithContentsOfFile:iconPath];
        if (result) return result;
    }
    
//    for (NSDictionary* targetApp in targets) {
//        iconPath = [targetApp objectForKey:@"BundleIdentifier"];
//        iconPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:iconPath];
//        if ([iconPath length]) {
//            result = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
//            if (result) return result;
//        }
//    }
    
    for (NSDictionary* targetApp in targets) {
        iconPath = [targetApp objectForKey:@"BundleIdentifier"];
        iconPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:iconPath];

        if ([iconPath length]) {
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.notificationcenterui"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Notifications.icns"];
                if (result) return result;
            }

            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.systemuiserver"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/Assistant.icns"];
                if (result) return result;
            }

            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.loginwindow"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GroupIcon.icns"];
                if (result) return result;
            }

            result = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
            NSData *imgDataOne = [result TIFFRepresentation];
            NSData *imgDataTwo = [[[NSWorkspace sharedWorkspace] iconForFile:@"/System/Library/CoreServices/loginwindow.app"] TIFFRepresentation];
            if ([imgDataOne isEqualToData:imgDataTwo])
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
            if (result) return result;
        }
    }
    
    result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
    return result;
}

- (void)checkforPluginUpdates :(NSTableView*)table {
    [self readPlugins:nil];
    
    NSDictionary *plugins = [[NSDictionary alloc] initWithDictionary:[installedPluginDICT copy]];
    NSArray *sourceURLS = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sources"];
    
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
            id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
            NSInteger result = [comparator compareVersion:localVersion toVersion:updateVersion];
            if (result == NSOrderedAscending)
                [needsUpdate setObject:bundleInfo forKey:bundleID];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        NSString *udCount = [NSString stringWithFormat:@"%ld", (unsigned long)[needsUpdate count]];
        NSDockTile *myTile = [NSApp dockTile];
        if ((unsigned long)[needsUpdate count] > 0)
            [myTile setBadgeLabel:udCount];
        else
            [myTile setBadgeLabel:@""];
        [myDelegate setBadge:udCount];
        [table reloadData];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:[needsUpdate count] forKey:@"updateCount"];
        [defaults synchronize];
    });
}

- (Boolean)keypressed:(NSEvent *)theEvent {
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    bool                specKey     =   false;
    
    switch (code) {
        case NSLeftArrowFunctionKey: {
            [myDelegate popView:nil];
            specKey = true;
            break;
        }
        case NSRightArrowFunctionKey: {
            [myDelegate pushView:nil];
            specKey = true;
            break;
        }
        case NSCarriageReturnCharacter: {
            [myDelegate pushView:nil];
            specKey = true;
            break;
        }
    }
    
    return specKey;
}

@end
