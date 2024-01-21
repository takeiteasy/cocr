//
//  ScreenCapture.h
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#ifndef ScreenCapture_h
#define ScreenCapture_h
#import <Cocoa/Cocoa.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>

@interface ScreenCapture : NSObject
@property NSRect frame;

-(id)initWithFrame:(NSRect)frame;
-(void)readText;
@end

#endif /* ScreenCapture_h */
