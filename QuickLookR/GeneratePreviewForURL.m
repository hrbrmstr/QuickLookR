#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
                               CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

//' This does the hard work
OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
                               CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {

  @autoreleasepool {
    
    NSURL *myURL = (__bridge NSURL *)url ;
    
    NSString *ext = [ [ myURL pathExtension ] lowercaseString ];
    
    NSString *contents = [ myURL absoluteString ] ;
    
    NSLog(@"Generating preview for %@", contents) ;
    
    if ([ ext isEqualToString: @"rmd" ]) {

      QLPreviewRequestSetURLRepresentation(
        preview,
        url,
        kUTTypePlainText,
        NULL
      );
      
      return noErr;

    } else {

      NSPipe *pipe = [ NSPipe pipe ] ;
      NSFileHandle *file = pipe.fileHandleForReading ;
      
      NSString *cmd = @"rdatainfo::get_info('" ;
      cmd = [ cmd stringByAppendingString: contents ] ;
      cmd = [ cmd stringByAppendingString: @"')" ] ;
      
      NSLog(@"Running: %@", cmd) ;

      NSTask *task = [ [ NSTask alloc ] init] ;
      task.launchPath = @"/usr/local/bin/Rscript";
      task.arguments = @[ @"-e", cmd ];
      task.standardOutput = pipe;
      
      [task launch];
      
      NSData *data = [ file readDataToEndOfFile ] ;
      [ file closeFile ];
      
      NSString *rOutput = [ [ NSString alloc ] initWithData: data encoding: NSUTF8StringEncoding ] ;
    
      if (false == QLPreviewRequestIsCancelled(preview)) {
        QLPreviewRequestSetDataRepresentation(
          preview,
          (__bridge CFDataRef)([ rOutput dataUsingEncoding:NSUTF8StringEncoding ]),
          kUTTypePlainText, NULL
        ) ;
      }
      
    }
    
  }
  
  return noErr;
  
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) { }
