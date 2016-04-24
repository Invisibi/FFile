//
//  NSString+MimeType.m
//  Pods
//
//  Created by muqq on 2016/4/24.
//
//

#import "NSURL+MimeType.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSURL (MimeType)

- (NSString *)mimeType {
    // Borrowed from http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[self pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)(MIMEType);
}
@end
