//
//  ScreenReader.h
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#ifndef ScreenReader_h
#define ScreenReader_h
#import <Cocoa/Cocoa.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>

@interface ScreenReader : NSObject
@property NSRect frame;

-(id)initWithFrame:(NSRect)frame;
-(BOOL)readText:(void(^)(NSString*))completion;
@end

#endif /* ScreenReader_h */
