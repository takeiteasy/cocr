//
//  ScreenReader.m
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#include "ScreenReader.h"

@implementation ScreenReader {
    NSString *lastString;
}

-(id)initWithFrame:(NSRect)frame {
    if (self = [super init]) {
        _frame = frame;
    }
    return self;
}

- (BOOL)readText:(void(^)(NSString *finished))completion {
    NSString *outPath = [NSString stringWithFormat:@"/tmp/cocr_%@.png", [[NSUUID UUID] UUIDString]];
    
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/usr/sbin/screencapture"];
    int y = [[[NSScreen screens] objectAtIndex:0] frame].size.height - _frame.size.height - (int)_frame.origin.y;
    [task setArguments:@[@"-r", @"-x", @"-R", [NSString stringWithFormat:@"%d,%d,%d,%d", (int)_frame.origin.x, y, (int)_frame.size.width, (int)_frame.size.height], outPath]];
    [task launch];
    [task waitUntilExit];
    
    NSImage* nsImg = [[NSImage alloc] initWithContentsOfFile:outPath];
    if (!nsImg) {
        NSLog(@"ERROR: Failed to load image at \"%@\"", outPath);
        return NO;
    }
    NSRect imageRect = NSMakeRect(0, 0, nsImg.size.width, nsImg.size.height);
    CGImageRef img = [nsImg CGImageForProposedRect:&imageRect
                                           context:NULL
                                             hints:nil];
    if (!img) {
        NSLog(@"ERROR: Failed to load image at \"%@\"", outPath);
        return NO;
    }
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:img options:@{}];
    
    NSArray<NSString*> *languages = @[@"en-US"];
    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR: %@", error.localizedDescription);
            return;
        }
        
        NSArray *observations = [request results];
        NSMutableArray<NSString*> *recognizedStrings = [[NSMutableArray alloc] init];
        
        for (VNRecognizedTextObservation *observation in observations) {
            VNRecognizedText *topCandidate = [[observation topCandidates:1] firstObject];
            if (topCandidate)
                [recognizedStrings addObject:topCandidate.string];
        }
        
        completion([recognizedStrings componentsJoinedByString:@", "]);
    }];
    request.recognitionLanguages = languages;
    
    NSError *error = nil;
    [requestHandler performRequests:@[request]
                              error:&error];
    BOOL result = !!error;
    if (result)
        NSLog(@"Unable to perform the requests: %@", error.localizedDescription);
    return result;
}
@end
