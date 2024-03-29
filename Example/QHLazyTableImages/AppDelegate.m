//
//  AppDelegate.m
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "ParseOperation.h"
#import "AppRecord.h"


// the http URL used for fetching the top iOS paid apps on the App Store
static NSString *const TopPaidAppsFeed =
@"http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml";


@interface AppDelegate ()

// the queue to run our "ParseOperation"
@property (nonatomic, strong) NSOperationQueue *queue;

// the NSOperation driving the parsing of the RSS feed
@property (nonatomic, strong) ParseOperation *parser;

@end


#pragma mark -

@implementation AppDelegate

// -------------------------------------------------------------------------------
//    application:didFinishLaunchingWithOptions:
// -------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:TopPaidAppsFeed]];
    
    // create an session data task to obtain and the XML feed
    NSURLSessionDataTask *sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                if ([error code] == NSURLErrorAppTransportSecurityRequiresSecureConnection)
                {
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    abort();
                }
                else
                {
                    [self handleError:error];
                }
            }];
        }
        else
        {
            // create the queue to run our ParseOperation
            self.queue = [[NSOperationQueue alloc] init];
            
            // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
            self->_parser = [[ParseOperation alloc] initWithData:data];
            
            __weak AppDelegate *weakSelf = self;
            
            self.parser.errorHandler = ^(NSError *parseError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [weakSelf handleError:parseError];
                });
            };
            
            // referencing parser from within its completionBlock would create a retain cycle
            __weak ParseOperation *weakParser = self.parser;
            
            self.parser.completionBlock = ^(void) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                });
                if (weakParser.appRecordList != nil)
                {
                    // The completion block may execute on any thread.  Because operations
                    // involving the UI are about to be performed, make sure they execute on the main thread.
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ViewController *rootViewController =
                        [(UINavigationController*)weakSelf.window.rootViewController topViewController];
                        rootViewController.entries = weakParser.appRecordList;
                    });
                }
                weakSelf.queue = nil;
            };
            [self.queue addOperation:self.parser]; // this will start the "ParseOperation"
        }
    }];
    [sessionTask resume];
    // show in the status bar that network activity is starting
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    return YES;
}

// -------------------------------------------------------------------------------
//    handleError:error
//  Reports any error with an alert which was received from connection or loading failures.
// -------------------------------------------------------------------------------
- (void)handleError:(NSError *)error
{
    NSString *errorMessage = [error localizedDescription];
    
    // alert user that our current record was deleted, and then we leave this view controller
    //
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Show Top Paid Apps"
                                                                   message:errorMessage
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         // dissmissal of alert completed
                                                     }];
    
    [alert addAction:OKAction];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
