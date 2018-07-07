//
//  sourcesTable.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "shareClass.h"
#import "AppDelegate.h"

extern AppDelegate* myDelegate;
NSString *repoPackages = @"";
NSArray *sourceURLS;

@interface sourcesTable : NSTableView {
    shareClass *_sharedMethods;
}
@end

@interface sourceTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField*  sourceName;
@property (weak) IBOutlet NSTextField*  sourceDescription;
@property (weak) IBOutlet NSImageView*  sourceImage;
@property (weak) IBOutlet NSImageView*  sourceIndicator;
@end

@implementation sourcesTable
{
    NSInteger previusRow;
    NSDictionary* item;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [shareClass alloc];
    
//    [self setTarget:self];
//    [self setDoubleAction:@selector(doubleClickInTable:)];
    
    item = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    sourceURLS = [item objectForKey:@"sources"];
//    NSLog(@"%@", sourceURLS);
    
    return [sourceURLS count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    sourceTableCell *result = (sourceTableCell*)[tableView makeViewWithIdentifier:@"sView" owner:self];
    
    result.sourceIndicator.animates = YES;
    result.sourceIndicator.image = [NSImage imageNamed:@"loading_mini.gif"];
    result.sourceIndicator.canDrawSubviewsIntoLayer = YES;
    [result.superview setWantsLayer:YES];
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.mySIMBL", 0);
    dispatch_async(backgroundQueue, ^{
        NSArray* sourceURLS = [self->item objectForKey:@"sources"];
        NSString* source = [sourceURLS objectAtIndex:row];
        NSURL* data = [NSURL URLWithString:[NSString stringWithFormat:@"%@/resource.plist?%@", source, [[NSProcessInfo processInfo] globallyUniqueString]]];
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithContentsOfURL:data];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([source length])
                result.sourceDescription.stringValue = source;
            
            if (dic)
            {
                if ([dic objectForKey:@"name"])
                    result.sourceName.stringValue = [dic objectForKey:@"name"];
                result.sourceImage.image = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/icon.png?%@", source, [[NSProcessInfo processInfo] globallyUniqueString]]]];
            }
            
            [result.sourceIndicator setImage:[NSImage imageNamed:NSImageNameRightFacingTriangleTemplate]];
        });
    });
    
    return result;
}

-(NSColor*)inverseColor:(NSColor*)color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [NSColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

- (void)keyDown:(NSEvent *)theEvent {
    Boolean result = [[shareClass sharedInstance] keypressed:theEvent];
    if (!result) [super keyDown:theEvent];
}

-(void)tableChange:(NSNotification *)aNotification {
    id sender = [aNotification object];
    NSInteger selectedRow = [sender selectedRow];
    if (selectedRow != -1) {
        sourceTableCell *ctc = [sender viewAtColumn:0 row:selectedRow makeIfNecessary:YES];
        repoPackages = [sourceURLS objectAtIndex:selectedRow];
        if (selectedRow != previusRow) {
            NSColor *aColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            if (aColor) {
                aColor = [self inverseColor:aColor];
                [ctc.sourceName setTextColor:aColor];
                [ctc.sourceDescription setTextColor:aColor];
                if (previusRow != -1) {
                    [ctc.sourceName setTextColor:[NSColor blackColor]];
                    [ctc.sourceDescription setTextColor:[NSColor grayColor]];
                }
                previusRow = selectedRow;
            }
        }
    }
    else {
        // No row was selected
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self tableChange:aNotification];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self tableChange:aNotification];
}

@end

@implementation sourceTableCell
@end
