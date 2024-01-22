//
//  TextWindow.h
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#ifndef TextWindow_h
#define TextWindow_h
#import <Cocoa/Cocoa.h>

@interface TextView : NSView {}
@end

@interface TextWindow : NSWindow {
    TextView* view;
    NSTextField* label;
}
@property (nonatomic, strong) NSMutableString *labelText;
-(id)init;
@end

#endif /* TextWindow_h */
