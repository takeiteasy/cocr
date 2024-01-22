//
//  SelectWindow.m
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#include "SelectWindow.h"

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

@implementation SelectWindow {
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
        
        _dashedBorderView = [[DashedBorderView alloc] initWithFrame:[self frame]];
        [self setContentView:_dashedBorderView];
    }
    return self;
}

- (void)resizeWithMousePositionX:(NSInteger)x andY:(NSInteger)y {
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

- (void)finalPosition:(NSInteger)x andY:(NSInteger)y andKeepOpen:(BOOL)keepOpen {
    [self resizeWithMousePositionX:x andY:y];
    if (!keepOpen)
        [self close];
}
@end
