/* cocr -- General purpose on-screen OCR for Mac [https://github.com/takeiteasy/cocr]
 
 The MIT License (MIT)

 Copyright (c) 2023 George Watson

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <Carbon/Carbon.h>
#include <Cocoa/Cocoa.h>
#include <getopt.h>

#if defined(DEBUG)
#define ENABLE_VERBOSE_MODE YES
#else
#define ENABLE_VERBOSE_MODE NO
#endif

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

@interface DashedBorderView : NSView
@end

@interface CaptureWindow : NSWindow
@property (nonatomic, strong) DashedBorderView *dashedBorderView;
-(id)initWithPositionX:(NSInteger)x andY:(NSInteger)y;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSStatusItem *statusBar;
@property (nonatomic, strong) CaptureWindow *captureWindow;
- (id)init;
- (void)newWindowAtX:(NSInteger)x andY:(NSInteger)y;
@end

static struct {
    CFMachPortRef tap;
    CFRunLoopSourceRef tapLoop;
    AppDelegate *delegate;
    NSPoint mousePosition;
    BOOL dragging;
} state;

static struct {
    BOOL enableVerboseMode;
} settings;

@implementation DashedBorderView
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // dash customization parameters
    CGFloat dashPattern[] = {10, 6}; // 10 units on, 6 units off, for example
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    // Set the line color
    CGContextSetStrokeColorWithColor(context, [NSColor colorWithRed:0.f
                                                              green:0.f
                                                               blue:0.f
                                                              alpha:.5f].CGColor);
    // Set the line width
    CGContextSetLineWidth(context, 2.0); // Set this to the width you desire
    // Set the line dash pattern
    CGContextSetLineDash(context, 0, dashPattern, 2); // 2 is the number of elements in the dashPattern
    // Create a path for the rectangle
    CGContextBeginPath(context);
    CGContextAddRect(context, NSInsetRect(self.bounds, 1, 1)); // Inset the rect so the border is fully visible
    // Stroke the path
    CGContextStrokePath(context);
}
@end

@implementation CaptureWindow {
    NSInteger originX;
    NSInteger originY;
}

- (id)initWithPositionX:(NSInteger)x andY:(NSInteger)y {
    originX = x;
    originY = y;
    if (self = [super initWithContentRect:NSMakeRect(originX, originY, 0, 0)
                                styleMask:NSWindowStyleMaskBorderless
                                  backing:NSBackingStoreBuffered
                                    defer:NO]) {
        [self setTitle:NSProcessInfo.processInfo.processName];
        [self setOpaque:NO];
        [self setExcludedFromWindowsMenu:NO];
        [self setBackgroundColor:[NSColor colorWithDeviceRed:0.f
                                                       green:0.f
                                                        blue:1.f
                                                       alpha:.1f]];
        [self setIgnoresMouseEvents:YES];
        [self makeKeyAndOrderFront:self];
        [self setLevel:NSFloatingWindowLevel];
        [self setCanHide:NO];
        [self setReleasedWhenClosed:NO];
        
        _dashedBorderView = nil;
    }
    return self;
}

- (void)resizeWithMousePositionX:(NSInteger)x andY:(NSInteger)y {
    if (_dashedBorderView)
        return;
    NSInteger newX = x - originX;
    NSInteger newY = y - originY;
    NSInteger offsetX = 0;
    NSInteger offsetY = 0;
    if (newX < 0)
        offsetX = labs(newX);
    if (newY < 0)
        offsetY = labs(newY);
    [self setFrame:NSMakeRect(originX - offsetX,
                              originY - offsetY,
                              labs(newX),
                              labs(newY))
           display:NO];
}

- (void)finalPosition:(NSInteger)x andY:(NSInteger)y {
    [self setBackgroundColor:[NSColor colorWithDeviceRed:1.f
                                                   green:0.f
                                                    blue:0.f
                                                   alpha:.05f]];
    [self resizeWithMousePositionX:x andY:y];
    _dashedBorderView = [[DashedBorderView alloc] initWithFrame:[self frame]];
    [self setContentView:_dashedBorderView];
}
@end

@implementation AppDelegate
- (id)init {
    if (self = [super init]) {
        _statusBar = nil;
        state.mousePosition = [NSEvent mouseLocation];
        _captureWindow = nil;
    }
    return self;
}

- (void)newWindowAtX:(NSInteger)x andY:(NSInteger)y {
    _captureWindow = [[CaptureWindow alloc] initWithPositionX:x
                                                         andY:y];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminate:)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
    _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusBar.button.image = [NSImage imageWithSystemSymbolName:@"sparkles"
                                       accessibilityDescription:nil];
#if __MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4
    statusBar.highlightMode = YES;
#endif
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    _statusBar.menu = menu;
}
@end

static CGEventRef EventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *ref) {
    state.mousePosition = [NSEvent mouseLocation];
    bool lastDraggingState = state.dragging;
    switch (type) {
        case kCGEventLeftMouseDragged:
            state.dragging = YES;
            [[state.delegate captureWindow] resizeWithMousePositionX:state.mousePosition.x
                                                                andY:state.mousePosition.y];
            if (!lastDraggingState) {
                LOG(@"* DRAGGING STARTED");
                [state.delegate newWindowAtX:state.mousePosition.x
                                        andY:state.mousePosition.y];
                return NULL;
            }
            break;
        case kCGEventLeftMouseUp:
            if (state.dragging) {
                [[state.delegate captureWindow] finalPosition:state.mousePosition.x
                                                         andY:state.mousePosition.y];
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), state.tapLoop, kCFRunLoopCommonModes);
                CGEventTapEnable(state.tap, 0);
                state.tap = nil;
                LOG(@"* DRAGGING FINISHED");
                NSRect frame = [[state.delegate captureWindow] frame];
                LOGF(@"FRAME: x:%f, y:%f, w:%f, h:%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
                break;
            }
            break;
        case kCGEventTapDisabledByTimeout:
        case kCGEventTapDisabledByUserInput:
            CGEventTapEnable(state.tap, 1);
        default:
            break;
    }
    return event;
}

static struct option long_options[] = {
    {"verbose", no_argument, NULL, 'v'},
    {"help", no_argument, NULL, 'h'},
    {NULL, 0, NULL, 0}
};

static void usage(void) {
    puts("usage: ocr [options]");
    puts("");
    puts("  Description:");
    puts("    TODO");
    puts("");
    puts("  Arguments:");
    puts("    * --verbose/-v -- Enable logging");
    puts("    * --help/-h -- Display this message");
}

int main(int argc, char *argv[]) {
    int opt;
    extern int optind;
    extern char* optarg;
    extern int optopt;
    while ((opt = getopt_long(argc, argv, "hv", long_options, NULL)) != -1) {
        switch (opt) {
            case 'v':
                settings.enableVerboseMode = YES;
                break;
            case 'h':
                usage();
                return 0;
            case '?':
                fprintf(stderr, "ERROR: Unknown argument \"-%c\"\n", optopt);
                usage();
                return 3;
        }
    }
    
    settings.enableVerboseMode = YES;
    state.dragging = NO;
    assert((state.tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, kCGEventMaskForAllEvents, EventCallback, NULL)));
    LOG(@"* EVENT TAP ENABLE");
    state.tapLoop = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, state.tap, 0);
    CGEventTapEnable(state.tap, 1);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), state.tapLoop, kCFRunLoopCommonModes);
    
    @autoreleasepool {
        state.delegate = [AppDelegate new];
        LOG(@"* APP DELEGATE CREATED");
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [NSApp setDelegate:state.delegate];
        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return 0;
}
