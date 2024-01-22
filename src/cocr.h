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
#include "ScreenReader.h"
#include "TextWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSTimer *refreshTimer;
}

@property (nonatomic, strong) SelectWindow *captureWindow;
@property (nonatomic, strong) ScreenReader *screenReader;
@property (nonatomic, strong) TextWindow *subtitleWindow;
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
    BOOL keepAlive;
    NSTimeInterval refreshInterval;
} Settings;

extern State state;
extern Settings settings;

#endif /* cocr_h */
