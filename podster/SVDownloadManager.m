//
//  SVDownloadManager.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#define kDownloadsDirectory @"PodcatcherDownloads"

#import "SVDownloadManager.h"
#import "SVPodcastEntry.h"
#import "SVPodcast.h"
#import "SVDownload.h"
#import "SVDownloadOperation.h"
#import "SVSubscription.h"
#include <sys/xattr.h>

@interface SVDownloadManager()
-(NSString *)downloadsPath;
-(void)ensureDownloadsDirectory;
@end
@implementation SVDownloadManager {
    NSMutableDictionary *operationLookup;
    NSInteger currentProgressPercentage;
   // MKNetworkEngine *downloadEngine;
    NSInteger maxConcurrentDownloads;
    NSOperationQueue *queue;
}
+ (id)sharedInstance
{
    static SVDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SVDownloadManager alloc] init];
    });
    
    return manager;
}
-(id)init
{
    self = [super init];
    if (self) {
        [self ensureDownloadsDirectory];
        currentProgressPercentage = 0;
      //  downloadEngine = [[MKNetworkEngine alloc] initWithHostName:nil
                                                //customHeaderFields:nil];
        operationLookup = [NSMutableDictionary dictionary];
        maxConcurrentDownloads = 2;
        queue = [NSOperationQueue new];
        [queue setMaxConcurrentOperationCount:1];
        queue.name = @"com.vantertech.podster.downloads";
    }
    
    return self;
}

- (void)resumeDownloads
{
    [MRCoreDataAction lookupWithBlock:^(NSManagedObjectContext *localContext) {
        NSArray *downloads = [SVDownload MR_findAllSortedBy:@"position" ascending:YES inContext:localContext];
        for (SVDownload *download in downloads) {
            // HACK: This should retrigger the download
            [self downloadEntry:download.entry];
        }

    }];
}

- (void)pauseDownloadForEntry:(SVPodcastEntry *)entry
{
//    NSParameterAssert(entry.mediaURL);
//    MKNetworkOperation *op = [operationLookup objectForKey:entry.mediaURL];
//    if (op) {
//        [op cancel];
//        [operationLookup removeObjectForKey:entry.mediaURL];
//    }
//    
//    [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
//        SVPodcastEntry *localEntry = [entry inContext:localContext];
//        localEntry.download.stateValue = SVDownloadStatePaused;
//    }];
}

-(SVDownload *)nextUpDownload
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %d", SVDownloadAttributes.state, SVDownloadStatePending];
    SVDownload *nextUp = [SVDownload MR_findFirstWithPredicate:predicate
                                                   sortedBy:SVDownloadAttributes.position
                                                  ascending:YES inContext:[PodsterManagedDocument defaultContext]];
    return nextUp;
}

-(void)startNextDownloadIfNeccesary
{
    LOG_DOWNLOADS(2, @"Checking for next download");
    SVDownload *nextUp = [self nextUpDownload];
    if (nextUp) {
        LOG_DOWNLOADS(2, @"Found something else to download. Starting!");
        [self downloadEntry:nextUp.entry];
    } else {
        LOG_DOWNLOADS(2, @"Nothing else pending");
    }
}

-(void)downloadEntry:(SVPodcastEntry *)entry
{
    LOG_DOWNLOADS(2, @"Downloading entry %@", entry);
    NSParameterAssert(entry);
    NSAssert(!entry.downloadCompleteValue, @"This entry is already downloaded");
    NSUInteger start = 0;
    NSDictionary *headers = nil;
    NSString *filePath = [[self downloadsPath] stringByAppendingPathComponent:[entry identifier]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (fileExists) {
        start = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
        headers = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"bytes=%d-", start] forKey:@"Range"];
    }
    
    SVDownload *lastDownlaod = [SVDownload MR_findFirstWithPredicate:nil
                                                            sortedBy:@"position"
                                                           ascending:YES];
    NSInteger position = 0;
    if (lastDownlaod) {
        position = lastDownlaod.positionValue + 1;
    }
    __block SVDownload *download = nil;
    [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) {

        SVPodcastEntry *localEntry = [entry MR_inContext:localContext];
        download = localEntry.download;
        localEntry.download.positionValue = position;
        if (!download) {
            download = [SVDownload MR_createInContext:localContext];
            localEntry.download = download;
            download.filePath = [[self downloadsPath] stringByAppendingPathComponent:[localEntry identifier]];
            download.stateValue = SVDownloadStatePending;
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:download.filePath] && download.entry.downloadCompleteValue){
            //Download already existed, file exists, and entry is marked as download.
            // Nothing to see here
            NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");
            return;
        }
        
    }];
    SVDownloadOperation *op = [[SVDownloadOperation alloc] initWithDownloadObjectID:download.objectID 
                                                                   downloadBasePath:[self downloadsPath]];
    [queue addOperation:op];

}

-(NSString *)downloadsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:kDownloadsDirectory];

}

-(void)ensureDownloadsDirectory
{
    NSString *downloadsPath = [self downloadsPath];
    u_int8_t b = 1;
    [[NSFileManager defaultManager] createDirectoryAtPath:downloadsPath
                              withIntermediateDirectories:YES 
                                               attributes:nil
                                                    error:nil];
    setxattr([downloadsPath fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
}
@end
