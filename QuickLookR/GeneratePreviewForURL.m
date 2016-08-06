#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Cocoa/Cocoa.h>

#include "rdata.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{

  @autoreleasepool {
    
    NSURL *myURL = (__bridge NSURL *)url;
    
    NSString *contents = [ myURL absoluteString ];
    
    NSLog(@"generate preview for %@", contents);

    //int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSString *cmd = @"rdatainfo::get_info('" ;
    cmd = [ cmd stringByAppendingString: contents ] ;
    cmd = [ cmd stringByAppendingString: @"')" ] ;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/Rscript";
    task.arguments = @[@"-e", cmd];
    task.standardOutput = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *rOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    if (false == QLPreviewRequestIsCancelled(preview)) {
      QLPreviewRequestSetDataRepresentation(preview,
                                            (__bridge CFDataRef)([rOutput dataUsingEncoding:NSUTF8StringEncoding]),
                                            kUTTypePlainText,
                                            NULL);
    }
    
  }
  
  return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
