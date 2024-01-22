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
        _screenReader = nil;
        refreshTimer = nil;
    }
    return self;
}

- (void)timerRefresh {
    [_screenReader readText:^(NSString *result) {
        printf("%s\n", [result UTF8String]);
        if (!settings.keepAlive)
            [NSApp terminate:nil];
    }];
}

- (void)newWindowAtX:(NSInteger)x andY:(NSInteger)y {
    _captureWindow = [[SelectWindow alloc] initWithPositionX:x
                                                        andY:y];
}

- (void)initScreenReader {
    NSRect frame = [_captureWindow frame];
    _screenReader = [[ScreenReader alloc] initWithFrame:frame];
    if (!settings.keepAlive)
        [self timerRefresh];
    else
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:settings.refreshInterval
                                                        target:self
                                                      selector:@selector(timerRefresh)
                                                      userInfo:nil
                                                       repeats:YES];
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
        case kCGEventLeftMouseDragged:
            state.dragging = YES;
            [[state.delegate captureWindow] resizeWithMousePositionX:state.mousePosition.x
                                                                andY:state.mousePosition.y];
            if (!lastDraggingState) {
                [state.delegate newWindowAtX:state.mousePosition.x
                                        andY:state.mousePosition.y];
                return NULL;
            }
            break;
        case kCGEventLeftMouseUp:
            if (state.dragging) {
                [[state.delegate captureWindow] resizeWithMousePositionX:state.mousePosition.x
                                                                    andY:state.mousePosition.y];
                [state.delegate initScreenReader];
                if (!settings.keepAlive)
                    [[state.delegate captureWindow] close];
                else {
                    NSRect frame = [[state.delegate captureWindow] frame];
                    frame.size.width += 4;
                    frame.size.height += 4;
                    frame.origin.x -= 2;
                    frame.origin.y -= 2;
                    [[state.delegate captureWindow] setFrame:frame
                                                     display:YES
                                                     animate:YES];
                }
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), state.tapLoop, kCFRunLoopCommonModes);
                CGEventTapEnable(state.tap, 0);
                state.tap = nil;
                return NULL;
            } else
                [NSApp terminate:nil];
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
    puts("usage: cocr [options]");
    puts("");
    puts("  Description:");
    puts("    A general purpose CLI on-screen OCR for Mac");
    puts("");
    puts("  Arguments:");
    puts("    * --help/-h -- Display this message");
}

int main(int argc, char *argv[]) {
    int opt;
    extern int optind;
    extern char* optarg;
    extern int optopt;
    while ((opt = getopt_long(argc, argv, "h", long_options, NULL)) != -1) {
        switch (opt) {
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
    
    settings.keepAlive = YES;
    settings.refreshInterval = 1.f;
    state.dragging = NO;
    
    assert((state.tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, kCGEventMaskForAllEvents, EventCallback, NULL)));
    state.tapLoop = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, state.tap, 0);
    CGEventTapEnable(state.tap, 1);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), state.tapLoop, kCFRunLoopCommonModes);
    
    @autoreleasepool {
        state.delegate = [AppDelegate new];
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [NSApp setDelegate:state.delegate];
        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return 0;
}
