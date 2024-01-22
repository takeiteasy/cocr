//
//  ScreenReader.m
//  ocr
//
//  Created by George Watson on 21/01/2024.
//

#include "ScreenReader.h"
#import <CommonCrypto/CommonDigest.h>

@interface NSData (MyAdditions)
- (NSString *)MD5Hash;
@end

@implementation NSData (MyAdditions)
- (NSString *)MD5Hash {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", result[i]];
    return output;
}
@end

@implementation ScreenReader {
    NSString *lastHash;
}

-(id)initWithFrame:(NSRect)frame {
    if (self = [super init]) {
        _frame = frame;
        lastHash = @"";
    }
    return self;
}

- (BOOL)readText:(void(^)(NSString *finished))completion {
    NSString *outPath = [NSString stringWithFormat:@"/tmp/cocr_%@.png", [[NSUUID UUID] UUIDString]];
    
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/usr/sbin/screencapture"];
    int y = [[[NSScreen screens] objectAtIndex:0] frame].size.height - _frame.size.height - (int)_frame.origin.y;
    if (_frame.size.width == 0 || _frame.size.height == 0)
        [NSApp terminate:nil];
    [task setArguments:@[@"-r", @"-x", @"-R", [NSString stringWithFormat:@"%d,%d,%d,%d", (int)_frame.origin.x, y, (int)_frame.size.width, (int)_frame.size.height], outPath]];
    [task launch];
    [task waitUntilExit];
    
    NSString *hash = [[NSData dataWithContentsOfFile:outPath] MD5Hash];
    if ([lastHash isEqualTo:hash])
        return false;
    
    lastHash = hash;
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
