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
#import "DDLog.h"
#import "Reachability.h"
#import "SVPlaybackManager.h"
@interface SVDownloadManager()
-(NSString *)downloadsPath;
-(void)ensureDownloadsDirectory;
@end

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
@implementation SVDownloadManager {
    NSMutableDictionary *operationLookup;
    NSInteger currentProgressPercentage;
    // MKNetworkEngine *downloadEngine;
    NSInteger maxConcurrentDownloads;
    NSOperationQueue *queue;
    BOOL cancelling;
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
        [queue setMaxConcurrentOperationCount:maxConcurrentDownloads];
        queue.name = @"com.vantertech.podster.downloads";
        NSString *lostWifi = NSLocalizedString(@"Downloads have been paused because you lost WI-FI connectivity", @"Downloads have been paused because you lost WI-FI connectivity");

        [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^void(NSNotification *note) {
                                                          AFNetworkReachabilityStatus status = [[SVPodcatcherClient sharedInstance] networkReachabilityStatus];
                                                          if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                                                              [self resumeDownloads];
                                                          } else {
                                                              BOOL wasDownloading = queue.operationCount > 0;
                                                              if (wasDownloading) {
                                                                  UILocalNotification *notDone = [[UILocalNotification alloc] init];
                                                                  notDone.alertBody = lostWifi;
                                                                  notDone.soundName = @"alert.aiff";
                                                                  [[UIApplication sharedApplication] presentLocalNotificationNow:notDone];
                                                                  [self cancelDownloads];                                     }
                                                          }
                                                      }];



    }

    return self;
}

- (void)resumeDownloads
{
    if(queue.operationCount > 0) {
        // Already downloading, return
        NSAssert(false, @"Should not resume an already running queue");
        return;
    }
    
    if ([[SVPlaybackManager sharedInstance] playbackState] == kPlaybackStatePlaying && [[SVPlaybackManager sharedInstance] isStreaming]) {
        LOG_DOWNLOADS(2, @"Not resuming downloads since we're currently streaming");
        return;
    }

    LOG_DOWNLOADS(2, @"Resuming downloads");
    cancelling = NO;

    NSManagedObjectContext *localContext = [PodsterManagedDocument defaultContext];
    [localContext performBlock:^{
        NSArray *downloads = [SVDownload MR_findAllSortedBy:@"position" ascending:YES inContext:localContext];
        for (SVDownload *download in downloads) {
            // HACK: This should retrigger the download
            [self downloadEntry:download.entry manualDownload:NO];
        }

    }];
}
- (void)cancelDownloads
{
    cancelling = YES;
    LOG_DOWNLOADS(1, @"Cancelling downloads");

    [queue cancelAllOperations];

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
                                                     ascending:YES
                                                     inContext:[PodsterManagedDocument defaultContext]];
    return nextUp;
}

- (void)downloadEntry:(SVPodcastEntry *)entry manualDownload:(BOOL)isManualDownload
{
    LOG_DOWNLOADS(2, @"Downloading entry %@", entry);
    NSParameterAssert(entry);
    NSAssert(!entry.downloadCompleteValue, @"This entry is already downloaded");

    NSManagedObjectContext *localContext = [PodsterManagedDocument defaultContext];
    SVDownload *lastDownload = [SVDownload MR_findFirstWithPredicate:nil
                                                            sortedBy:@"position"
                                                           ascending:YES inContext:localContext];
    NSInteger position = 0;
    if (lastDownload) {
        position = lastDownload.positionValue + 1;
    }
    // Create the download database object
    __block SVDownload *download = nil;

    [localContext performBlockAndWait:^{

        SVPodcastEntry *localEntry = [entry MR_inContext:localContext];
        download = localEntry.download;
        localEntry.download.positionValue = position;
        if (!download) {

            download = [SVDownload MR_createInContext:localContext];
            download.manuallyTriggeredValue = isManualDownload;
            localEntry.download = download;
            download.filePath = [localEntry downloadFilePathForBasePath:[self downloadsPath]];
            download.stateValue = SVDownloadStatePending;
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:download.filePath] && download.entry.downloadCompleteValue){
            //Download already existed, file exists, and entry is marked as download.
            // Nothing to see here
            NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");
            return;
        }

    }];

    // perform the operation if needed
    if ([[SVPodcatcherClient sharedInstance] networkReachabilityStatus] == AFNetworkReachabilityStatusReachableViaWiFi ||
            [[SVSettings sharedInstance] downloadOn3g]) {


        SVDownloadOperation *op = [[SVDownloadOperation alloc] initWithDownloadObjectID:download.objectID
                                                                               filePath:[entry downloadFilePathForBasePath:[self downloadsPath]]];

        __block UIBackgroundTaskIdentifier background_task; //Create a task object

        background_task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
            [[UIApplication sharedApplication] endBackgroundTask: background_task]; //Tell the system that we are done with the tasks
            background_task = UIBackgroundTaskInvalid; //Set the task to be invalid
            UILocalNotification *notDone = [[UILocalNotification alloc] init];
            notDone.alertBody = NSLocalizedString(@"Podster can only download for 10 minutes in the background. Please re-open it to continue.", @"Podster can only download for 10 minutes in the background. Please re-open it to continue.");
            notDone.soundName = @"alert.aiff";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notDone];

        }];

        op.completionBlock = ^void() {
            if (queue.operationCount == 0) {
                if(!op.isCancelled) {
                    UILocalNotification *downloadedNotification = [[UILocalNotification alloc] init];
                    downloadedNotification.alertBody = NSLocalizedString(@"All downloads have completed", @"All downloads have completed");
                    downloadedNotification.soundName = @"alert.aiff";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:downloadedNotification];
                }
                [localContext performBlock:^{
                    download.stateValue = SVDownloadStateFailed;
                    download.entry.podcast.isDownloadingValue = NO;
                }];
            }

            [[UIApplication sharedApplication] endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        };

        [queue addOperation:op];
    } else {
        LOG_DOWNLOADS(2, @"Queued download but did not start it since we're not on wifi");
    }
}

- (void)deleteFileForEntry:(SVPodcastEntry *)entry
{
    NSString *path = [entry downloadFilePathForBasePath:[self downloadsPath]];
    if (![path isEqualToString:entry.localFilePath]) {
        NSAssert(false, @"should match");
    }

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if(error != nil) {
        LOG_DOWNLOADS(0, @"Error deleting entry: %@", error);
        NSAssert(error == nil, @"Failure deleting entry");
    }

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
    int result = setxattr([downloadsPath fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
    NSAssert(result == 0, @"Did not set no-backup attribute correctly");
}
@end
