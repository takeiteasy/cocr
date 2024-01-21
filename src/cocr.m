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

#include "cocr.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <Carbon/Carbon.h>
#include <getopt.h>

State state;
Settings settings;

@implementation AppDelegate
- (id)init {
    if (self = [super init]) {
        state.mousePosition = [NSEvent mouseLocation];
        _captureWindow = nil;
        _screenCapture = nil;
    }
    return self;
}

- (void)newWindowAtX:(NSInteger)x andY:(NSInteger)y {
    LOGF(@"* WINDOW CREATED AT: %ld, %ld", x, y);
    _captureWindow = [[SelectWindow alloc] initWithPositionX:x
                                                         andY:y];
}

- (void)initScreenCapture {
    NSRect frame = [_captureWindow frame];
    LOGF(@"* CAPTURING AT: x:%f, y:%f, w:%f, h:%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    _screenCapture = [[ScreenCapture alloc] initWithFrame:frame];
    [_screenCapture readText:^(NSString *result) {
        LOGF(@"* RESULT \"%@\"", result);
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminate:)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
}
@end

static CGEventRef EventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *ref) {
    state.mousePosition = [NSEvent mouseLocation];
    bool lastDraggingState = state.dragging;
    switch (type) {
        case kCGEventLeftMouseDown:
            return NULL;
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
                [state.delegate initScreenCapture];
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), state.tapLoop, kCFRunLoopCommonModes);
                CGEventTapEnable(state.tap, 0);
                state.tap = nil;
                LOG(@"* DRAGGING FINISHED");
                NSRect frame = [[state.delegate captureWindow] frame];
                LOGF(@"FRAME: x:%f, y:%f, w:%f, h:%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
                return NULL;
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
