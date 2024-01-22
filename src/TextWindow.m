//
//  TextWindow.m
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#include "TextWindow.h"

@implementation TextView
- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {}
    return self;
}

- (void)drawRect:(NSRect)frame {
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:frame
                                                         xRadius:6.0
                                                         yRadius:6.0];
    [[NSColor colorWithRed:0.f
                     green:0.f
                      blue:0.f
                     alpha:.75f] set];
    [path fill];
}
@end

//! MARK: TextWindow Implementation

@implementation TextWindow
@synthesize labelText;

-(id)init {
    if (self = [super initWithContentRect:NSMakeRect(0, 0, 0, 0)
                                styleMask:NSWindowStyleMaskBorderless
                                  backing:NSBackingStoreBuffered
                                    defer:NO]) {
        label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        view = [[TextView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        
        labelText = [[NSMutableString alloc] initWithString:@""];
        
        [label setBezeled:NO];
        [label setDrawsBackground:NO];
        [label setEditable:NO];
        [label setSelectable:NO];
        [label setAlignment:NSTextAlignmentCenter];
        [label setTextColor:[NSColor whiteColor]];
        [[label cell] setBackgroundStyle:NSBackgroundStyleRaised];
        [label sizeToFit];
        
        [self setTitle:NSProcessInfo.processInfo.processName];
        [self setOpaque:NO];
        [self setExcludedFromWindowsMenu:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setIgnoresMouseEvents:YES];
        [self makeKeyAndOrderFront:self];
        [self setLevel:NSFloatingWindowLevel];
        [self setCanHide:NO];
        [self setReleasedWhenClosed:NO];
        
        [self setContentView:view];
        [view addSubview:label];
    }
    return self;
}

-(BOOL)canBecomeKeyWindow {
    return YES;
}

-(void)resize {
    if (![labelText length]) {
        [self setFrame:NSMakeRect(0, 0, 0, 0)
               display:YES];
        [view setFrame:NSMakeRect(0, 0, 0, 0)];
        [label setFrame:NSMakeRect(0, 0, 0, 0)];
    } else {
        [label setStringValue:labelText];
        [label sizeToFit];
        int x = 0;
        int y = 0;
        int w = [label frame].size.width + 10;
        int h = [label frame].size.height + 10;
        [self setFrame:NSMakeRect(x, y, w, h)
               display:YES];
        [view setFrame:NSMakeRect(0, 0, w, h)];
        [label setFrame:NSMakeRect(0, 0, w, h)];
    }
    [view setNeedsDisplay:YES];
}
@end
