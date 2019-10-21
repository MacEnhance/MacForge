/**
 * Copyright 2003-2009, Mike Solomon <mas63@cornell.edu>
 * SIMBL is released under the GNU General Public License v2.
 * http://www.opensource.org/licenses/gpl-2.0.php
 */

#import "NSAlert_SIMBL.h"

@implementation NSAlert (SIMBLAlert)

+ (void) errorAlert:(NSString*)_message withDetails:(NSString*)_details, ... {
	va_list ap;
	va_start(ap, _details);

	NSString* detailsFormatted = [[NSString alloc] initWithFormat:_details arguments:ap];
	va_end(ap);

    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:_message];
    [alert setInformativeText:detailsFormatted];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:NSApp.mainWindow completionHandler:^(NSModalResponse returnCode) { }];
}

@end
