//
//  SVDownloadOperation.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVDownloadOperation.h"
#import "SVDownload.h"
#import "SVPodcastEntry.h"
#import "SVPodcatcherClient.h"
@implementation SVDownloadOperation {
    BOOL _isExecuting;
    BOOL _isFinished;
    SVDownload  *download;
//    MKNetworkOperation *networkOp;
    NSInteger currentProgressPercentage;
    NSString *basePath;
}
@synthesize downloadObjectID;
-(id)initWithDownloadObjectID:(NSManagedObjectID *)objectId
             downloadBasePath:(NSString *)path
{
    self = [super init];
    if (self) {
        NSParameterAssert(objectId);
        NSParameterAssert(path);
//        NSAssert(![objectId isTemporaryID], @"Object id shoudl not be a temp id");
        self.downloadObjectID = objectId;
        basePath = [path copy];
        
    }
    return self;
}
- (void)downloadProgressChanged:(double)progress forDownload:(SVDownload *)localDownload inContext:(NSManagedObjectContext *)localContext
{
    NSInteger percentage = (NSInteger)(progress * 100);
    if (currentProgressPercentage != percentage) {
        currentProgressPercentage = percentage;
        LOG_DOWNLOADS(4, @"Download Progress: %d for entry: %@" , currentProgressPercentage, localDownload.entry.title);
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[localDownload.entry identifier], @"identifier",[NSNumber numberWithDouble:progress], @"progress",  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadProgressChanged" object:nil userInfo:info];
        [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *innerContext) {
            SVDownload *innerDownload = (SVDownload *)[localDownload inContext:innerContext];
            innerDownload.stateValue = SVDownloadStateDownloading;
            innerDownload.progressValue = progress;
        } saveParentContext:YES];
    }

}
- (void)done
{
//    if( networkOp ) {
//        [networkOp cancel];
//    }
//    
//    // Alert anyone that we are finished
//    [self willChangeValueForKey:@"isExecuting"];
//    [self willChangeValueForKey:@"isFinished"];
//    _isExecuting = NO;
//    _isFinished  = YES;
//    [self didChangeValueForKey:@"isFinished"];
//    [self didChangeValueForKey:@"isExecuting"];
}
-(void)start
{

//    NSManagedObjectContext *localContext = [NSManagedObjectContext contextForCurrentThread];
//    download = (SVDownload *)[localContext objectWithID:self.downloadObjectID];
//    LOG_DOWNLOADS(2, @"Starting episode download: %@", download.entry);
//    
//    NSAssert(!download.entry.downloadCompleteValue, @"This entry is already downloaded");
//    NSUInteger start = 0;
//    NSDictionary *headers = nil;
//    NSString *filePath = [basePath stringByAppendingPathComponent:[download.entry identifier]];
//    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
//    if (fileExists) {
//        start = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
//        headers = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"bytes=%d-", start] forKey:@"Range"];
//    }
//    
//    SVDownload *lastDownlaod = [SVDownload MR_findFirstWithPredicate:nil
//                                                            sortedBy:@"position"
//                                                           ascending:YES];
//    NSInteger position = 0;
//    if (lastDownlaod) {
//        position = lastDownlaod.positionValue + 1;
//    }
//    
//    [self willChangeValueForKey:@"isExecuting"];
//    _isExecuting = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//    
//    [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) {
//        
//        SVDownload *localDownload = [download MR_inContext:localContext];
//        if ([[NSFileManager defaultManager] fileExistsAtPath:download.filePath] && download.entry.downloadCompleteValue){
//            //Download already existed, file exists, and entry is marked as download.
//            // Nothing to see here
//            NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");
//            return;
//        }
//        
//        localDownload.stateValue = SVDownloadStateDownloading;
//        MKNetworkOperation *op = [[SVPodcatcherClient sharedInstance] operationWithURLString:download.entry.mediaURL];
//        if (headers){ 
//            NSLog(@"Set custom headers: %@", headers);
//            [op addHeaders:headers];
//        }
//        
//        [op addDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath append:YES]];
//        [op onDownloadProgressChanged:^(double progress) {
//            [self downloadProgressChanged:progress
//                              forDownload:localDownload 
//                                inContext:localContext];
//        }];
//        
//        [op onCompletion:^(MKNetworkOperation *completedOperation) {
//            [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *innerContext) {
//                SVDownload *innerDownload = (SVDownload *)[localDownload inContext:innerContext];
//                LOG_NETWORK(2, @"Downloaded episode: %@", innerDownload.entry.title);
//                innerDownload.entry.downloadCompleteValue = YES;
//                [innerDownload deleteInContext:innerContext];    
//                [self done];
//            }];
//        } onError:^(NSError *error) {
//            LOG_DOWNLOADS(2, @"Download failed with Error: %@", error);
//            [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *innerContext) {
//                SVDownload *innerDownload = (SVDownload *)[localDownload inContext:innerContext];
//                LOG_NETWORK(2, @"Failed to download episode: %@", innerDownload.entry.title);
//                innerDownload.stateValue = SVDownloadStateFailed;
//            } saveParentContext:YES];
//            
//        }];
//        
//        [[SVPodcatcherClient sharedInstance] enqueueOperation:op];
//    }];

    
    
    
}
-(BOOL)isConcurrent 
{
    return YES;
}
-(BOOL)isExecuting 
{
    return _isExecuting;
}
-(BOOL)isFinished
{
    return _isFinished;
}
-(void)cancel
{
//    [networkOp cancel];
//    [self willChangeValueForKey:@"isExecuting"];
//    _isExecuting = NO;
//    [self didChangeValueForKey:@"isExecuting"];
//    [self willChangeValueForKey:@"isFinished"];
//    _isFinished = YES;;
//    [self didChangeValueForKey:@"isFinished"];
    
}
@end
