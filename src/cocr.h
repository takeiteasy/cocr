//
//  cocr.h
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#ifndef cocr_h
#define cocr_h
#include <Cocoa/Cocoa.h>
#include "SelectWindow.h"

#if defined(DEBUG)
#define LOGF(MSG, ...)              \
do {                                \
    if (settings.enableVerboseMode) \
        NSLog((MSG), __VA_ARGS__);  \
} while(0)
#define LOG(MSG) LOGF(@"%@", (MSG))
#else
#define LOGF(MSG, ...)
#define LOG(MSG)
#endif

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) CaptureWindow *captureWindow;
- (id)init;
- (void)newWindowAtX:(NSInteger)x andY:(NSInteger)y;
@end

typedef struct {
    CFMachPortRef tap;
    CFRunLoopSourceRef tapLoop;
    AppDelegate *delegate;
    NSPoint mousePosition;
    BOOL dragging;
} State;

typedef struct {
    BOOL enableVerboseMode;
} Settings;

extern State state;
extern Settings settings;

#endif /* cocr_h */
