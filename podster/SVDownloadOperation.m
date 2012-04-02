//
//  SVDownloadOperation.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVDownloadOperation.h"
#import "SVDownload.h"
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
#import "PodsterManagedDocument.h"
#import "SVPodcatcherClient.h"
@implementation SVDownloadOperation {
    BOOL _isExecuting;
    BOOL _isFinished;
    SVDownload  *download;
    AFHTTPRequestOperation *networkOp;
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
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[localDownload.entry identifier], @"identifier", [NSNumber numberWithDouble:progress], @"progress",  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadProgressChanged" object:nil userInfo:info];
        [localContext performBlock: ^{

            localDownload.stateValue = SVDownloadStateDownloading;
            localDownload.progressValue = (float) progress;
            localDownload.entry.podcast.downloadPercentageValue = (float) (progress * 100);
            if (!localDownload.entry.podcast.isDownloadingValue) {
                localDownload.entry.podcast.isDownloadingValue = YES;
            } 
         
         if (currentProgressPercentage == 100) {
              localDownload.entry.podcast.isDownloadingValue = NO;
         }

        }];
    }
}

- (void)done
{
    if( networkOp ) {
        [networkOp cancel];
    }
    
    // Alert anyone that we are finished
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _isExecuting = NO;
    _isFinished  = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

-(void)start
{
    dispatch_semaphore_t semaphore =  dispatch_semaphore_create(0);
    NSManagedObjectContext *localContext = [PodsterManagedDocument defaultContext];
    [localContext performBlockAndWait:^{
        
        
        download = (SVDownload *)[localContext objectWithID:self.downloadObjectID];
        LOG_DOWNLOADS(2, @"Starting episode download: %@", download.entry);
        
        NSAssert(!download.entry.downloadCompleteValue, @"This entry is already downloaded");
        NSUInteger start = 0;
        NSDictionary *headers = nil;
        NSString *filePath = [basePath stringByAppendingPathComponent:[download.entry identifier]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if (fileExists) {
            start = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
            headers = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"bytes=%d-", start] forKey:@"Range"];
        }
        
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        
        SVDownload *localDownload = [download MR_inContext:localContext];
        if ([[NSFileManager defaultManager] fileExistsAtPath:download.filePath] && download.entry.downloadCompleteValue){
            //Download already existed, file exists, and entry is marked as download.
            // Nothing to see here
            NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");
            return;
        }
        
        localDownload.stateValue = SVDownloadStateDownloading;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:localDownload.entry.mediaURL]];
        if (headers){ 
            NSLog(@"Set custom headers: %@", headers);
            [request setAllHTTPHeaderFields:headers];
        }
        
        
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [op setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath append:YES]];
        
        [op setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
            [self downloadProgressChanged:(double)totalBytesRead / (double)(totalBytesExpectedToRead + start)
                              forDownload:localDownload 
                                inContext:localContext];
        }];
        
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [localContext performBlock:^{
                LOG_NETWORK(2, @"Downloaded episode: %@", localDownload.entry.title);
                localDownload.entry.downloadCompleteValue = YES;
                [localDownload MR_deleteInContext:localContext];    
                [self done];
                dispatch_semaphore_signal(semaphore);
                
            }];
                        
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [localContext
             performBlock:^{
                 LOG_DOWNLOADS(2, @"Download failed with Error: %@", error);        
                 LOG_NETWORK(2, @"Failed to download episode: %@", localDownload.entry.title);
                 localDownload.stateValue = SVDownloadStateFailed;
                 dispatch_semaphore_signal(semaphore);
                 
             }];
            
        }];
        networkOp = op;
        [op start];
    }];

   
    LOG_DOWNLOADS(2, @"Operation watiting for download to complete");
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    LOG_DOWNLOADS(2, @"Download complete"); 

    
    
    
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
    [networkOp cancel];
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = YES;;
    [self didChangeValueForKey:@"isFinished"];
    
}
@end
