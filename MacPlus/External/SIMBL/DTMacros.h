/**
 * Copyright 2003-2009, Mike Solomon <mas63@cornell.edu>
 * SIMBL is released under the GNU General Public License v2.
 * http://www.opensource.org/licenses/gpl-2.0.php
 */

#import <Foundation/Foundation.h>


#define DTOwnerBundle [NSBundle bundleForClass:[self class]]

#define DTPathFromComponents(...) [NSString pathWithComponents:[NSArray arrayWithObjects:__VA_ARGS__, nil]]

enum DTLogLevel
{
	DTLog_Developer = 0,
	DTLog_Debug     = 10,
	DTLog_Log       = 20,
	DTLog_Alert     = 30,
	DTLog_Critical  = 40,
	
	DebugLevel00 = 0,
	DebugLevel10 = 10,
	DebugLevel20 = 20,
	DebugLevel30 = 30,
	DebugLevel40 = 40,
	DebugLevel50 = 50,
};

#define DLOG_0 0
#define DLOG_10 10
#define DLOG_20 20
#define DLOG_30 30
#define DLOG_40 40
#define DLOG_50 50

#define DTAssert(condition) NSAssert(condition, [NSString stringWithCString:"assert " #condition " failed"])

#ifdef DEBUG
#define DLog(logLevel, arg) if (logLevel >= DEBUG) NSLog arg
#define DTLog(logLevel, ...) if (logLevel >= DEBUG) NSLog(__VA_ARGS__)
#define DTLogOnCondition(logLevel, condition, ...) if (logLevel >= DEBUG && (condition)) NSLog(__VA_ARGS__)
#define DTLogMessage() NSLog(@"[%@ %@]", [self className], NSStringFromSelector(_cmd))
#define DTLogMessageCall() \
Method* method = class_getInstanceMethod([self class], _cmd); \
unsigned _numArgs = method_getNumberOfArguments(method); \
for (int i = 0; i < _numArgs; i++) \
{ \
	const char* type; \
	int offset; \
	unsigned _stackSize = method_getArgumentInfo(method, i, &type, &offset); \
}
#else
#define DLog(logLevel, arg)
#define DTLog(logLevel, ...)
#define DTLogOnCondition(logLevel, condition, ...)
#define DTLogMessage()
#endif
