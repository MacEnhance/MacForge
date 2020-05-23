//
//  MF_pluginPreferencesView.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "MF_pluginPreferencesView.h"

@implementation MF_pluginPreferencesView

- (void)viewWillDraw{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self doAQuery];
        
        // create a table view and a scroll view
        NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 700, 500)];
        _tv = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 700, 500)];
        // create columns for our table
        NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"Col1"];
//        NSTableColumn * column2 = [[NSTableColumn alloc] initWithIdentifier:@"Col2"];
        [column1 setWidth:250];
//        [column2 setWidth:250];
        // generally you want to add at least one column to the table view.
        [_tv addTableColumn:column1];
//        [_tv addTableColumn:column2];
        [_tv setDelegate:self];
        [_tv setDataSource:self];
        // embed the table view in the scroll view, and add the scroll view
        // to our window.
        [tableContainer setDocumentView:_tv];
        [tableContainer setHasVerticalScroller:YES];
        [self addSubview:tableContainer];
    });
    
    NSButton *b = NSButton.new;
    [b setFrame:CGRectMake(self.frame.size.width/2, self.frame.size.height - 50, 100, 18)];
    [b setButtonType:NSButtonTypeSwitch];
    [self addSubview:b];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 30;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
//    NSUserDefaults *blPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.w0lf.MacForgeHelper"];
//    NSDictionary *blDict = [blPrefs dictionaryRepresentation];
//    NSArray *tmpblacklist = [blDict objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
//    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI"];
//    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:tmpblacklist];
//    for (NSString *app in alwaysBlaklisted)
//        if (![tmpblacklist containsObject:app])
//            [newlist addObject:app];
//    _blackList = newlist;
//    return _blackList.count;
    
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];

    NSError *error = nil;
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];

    NSArray *array = [[NSFileManager defaultManager]
                     contentsOfDirectoryAtURL:[urls objectAtIndex:0]
                   includingPropertiesForKeys:properties
                                      options:(NSDirectoryEnumerationSkipsHiddenFiles)
                                        error:&error];
    if (array == nil) {
        // Handle the error
    }
    
//    self.applicationList = array;
//    NSLog(@"%lu", (unsigned long)array.count);
    
//    return array.count / 2;
//    NSLog(@"%lu", self.applicationList.count);
    return self.applicationList.count;
}

-(void)doAQuery {
    _query = [[NSMetadataQuery alloc] init];
   // [query setSearchScopes: @[@"/Applications"]];  // If you want to find applications only in /Applications folder
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kMDItemKind == 'Application'"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:nil];
    [_query setPredicate:predicate];
    [_query startQuery];
}

-(void)queryDidFinishGathering:(NSNotification *)notif {
    int i = 0;
    NSMutableArray *bundleIDs = NSMutableArray.new;
    for(i = 0; i<_query.resultCount; i++ ){
        NSString *bid = [[_query resultAtIndex:i] valueForAttribute:(NSString*)kMDItemCFBundleIdentifier];
        if (bid.length)
            if (![bundleIDs containsObject:bid])
                [bundleIDs addObject:bid];
    }
    self.applicationList = bundleIDs;
    [_tv reloadData];
    
    [_tv setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES selector:@selector(compare:)]]];
    
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
//    blacklistTableCell *result = (blacklistTableCell*)[[NSView alloc] initWithFrame:CGRectMake(0, 25, 100, 15)];
    NSImageView *img = [[NSImageView alloc] initWithFrame:CGRectMake(5, 3, 24, 24)];
//    NSUInteger index = [[tableView tableColumns] indexOfObject:tableColumn];
    NSString *bundleID = [self.applicationList objectAtIndex:row];
    
    NSString *appPath = @"";
    appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];

//    NSUInteger index = [[tableView tableColumns] indexOfObject:tableColumn];
//    NSLog(@"row %ld : col : %lu : total : %lu", (long)row, (unsigned long)index, row + row + index);
    
//    NSURL *aurl = (NSURL*)[self.applicationList objectAtIndex:row + row + index];
//    if (aurl)
//        appPath = [aurl path];

    NSImage *appIMG = NSImage.new;
    NSString *appName = @"";
    
//    NSLog(@"%@", appPath);
    
    if (appPath.length) {
        appIMG = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
        if (appIMG == nil)
            appIMG = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
        NSBundle *bundle = [NSBundle bundleWithPath:appPath];
        NSDictionary *info = [bundle infoDictionary];
        appName = [info objectForKey:@"CFBundleExecutable"];
    } else {
        appIMG = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
        appName = bundleID;
    }

    NSTextField *appNameView = [[NSTextField alloc] initWithFrame:CGRectMake(32, 5, 200, 20)];
    appNameView.editable = NO;
    appNameView.bezeled = NO;
    [appNameView setSelectable:false];
    [appNameView setDrawsBackground:false];
    if (appName.length)
        appNameView.stringValue = appName;

    [img setImage:appIMG];
    [result addSubview:appNameView];
    [result addSubview:img];
//    result.bundleID = bundleID;
    return result;
}

@end
