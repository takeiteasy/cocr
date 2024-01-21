//
//  SelectWindow.h
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#ifndef SelectWindow_h
#define SelectWindow_h
#import <Cocoa/Cocoa.h>

@interface DashedBorderView : NSView
@end

@interface SelectWindow : NSWindow
@property (nonatomic, strong) DashedBorderView *dashedBorderView;
-(id)initWithPositionX:(NSInteger)x andY:(NSInteger)y;
-(void)resizeWithMousePositionX:(NSInteger)x andY:(NSInteger)y;
-(void)finalPosition:(NSInteger)x andY:(NSInteger)y;
@end

#endif /* SelectWindow_h */
