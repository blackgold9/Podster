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
    dispatch_group_t completionGroup;
    BOOL downloading;
    UIBackgroundTaskIdentifier background_task; 
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
        background_task = UIBackgroundTaskInvalid;
        downloading = NO;
        completionGroup = dispatch_group_create();
        currentProgressPercentage = 0;
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
                                                              DDLogInfo(@"Accquired WIFI signal");
                                                              [self resumeDownloads];
                                                          } else {
                                                              DDLogInfo(@"Lost WIFI signal");
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
    DDLogInfo(@"Resuming downloads");
    if(queue.operationCount > 0) {
        // Already downloading, return
        DDLogWarn(@"Attempted to resume downloads when the queue was already running");
        NSAssert(false, @"Should not resume an already running queue");
        return;
    }

    
    cancelling = NO;

    NSManagedObjectContext *localContext = [PodsterManagedDocument defaultContext];
    [localContext performBlock:^{
        DDLogVerbose(@"Querying pending downloads");
        NSArray *downloads = [SVDownload MR_findAllSortedBy:@"position" ascending:YES inContext:localContext];
        for (SVDownload *download in downloads) {
            [self startDownload:download];
        }

    }];
}
- (void)cancelDownloads
{
    cancelling = YES;
    DDLogInfo(@"Cancelling downloads");

    [queue cancelAllOperations];

}

- (void)downloadEntry:(SVPodcastEntry *)entry manualDownload:(BOOL)isManualDownload
{
    LOG_DOWNLOADS(2, @"Downloading entry %@", entry);
    NSParameterAssert(entry);
    NSAssert(!entry.downloadCompleteValue, @"This entry is already downloaded");
    NSAssert(entry.download == nil, @"There was already a download scheduled");

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

    [localContext performBlock:^{
       
        SVPodcastEntry *localEntry = [entry MR_inContext:localContext];
        download = localEntry.download;
        if (!download) {
            download = [SVDownload MR_createInContext:localContext];
            download.manuallyTriggeredValue = isManualDownload;
            localEntry.download = download;
            download.filePath = [localEntry downloadFilePathForBasePath:[self downloadsPath]];
            download.stateValue = SVDownloadStatePending;
            localEntry.download.positionValue = position;
            [self startDownload:download];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:download.filePath] && download.entry.downloadCompleteValue){
           
           NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");
        }   
    }];

}

- (void)deleteFileForEntry:(SVPodcastEntry *)entry
{
    NSString *path = [entry downloadFilePathForBasePath:[self downloadsPath]];
    if (![path isEqualToString:entry.localFilePath]) {
        NSAssert(false, @"should match");
    }
    
    DDLogInfo(@"Deleting File: %@", path);

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if(error != nil) {
        DDLogError( @"Error deleting entry: %@", error);
    }

}
-(NSString *)downloadsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:kDownloadsDirectory];

}

- (void)disableBackupForPath:(NSString *)path
{
    DDLogInfo(@"Setting do-not-backup for %@", path);
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr([path fileSystemRepresentation], attrName, &attrValue, sizeof(attrValue), 0, 0);       
    NSAssert(result == 0, @"Did not set no-backup attribute correctly");

}

-(void)ensureDownloadsDirectory
{
    NSString *downloadsPath = [self downloadsPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsPath]) {

        [[NSFileManager defaultManager] createDirectoryAtPath:downloadsPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        [self disableBackupForPath:downloadsPath];
    }
}

- (void)startDownload:(SVDownload *)download
{
    if ([[SVPodcatcherClient sharedInstance] networkReachabilityStatus] == AFNetworkReachabilityStatusReachableViaWiFi ||
        [[SVSettings sharedInstance] downloadOn3g]) {
        
        SVDownloadOperation *op = [[SVDownloadOperation alloc] initWithDownloadObjectID:download.objectID
                                                                               filePath:[download.entry downloadFilePathForBasePath:[self downloadsPath]]];
        @synchronized(self){
            // we're not currently downloading, and we will be, so....
            if (!downloading) {
                downloading = YES;
                background_task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
                    [[UIApplication sharedApplication] endBackgroundTask: background_task]; //Tell the system that we are done with the tasks
                    background_task = UIBackgroundTaskInvalid; //Set the task to be invalid
                    UILocalNotification *notDone = [[UILocalNotification alloc] init];
                    notDone.alertBody = NSLocalizedString(@"Podster can only download for 10 minutes in the background. Please re-open it to continue.", @"Podster can only download for 10 minutes in the background. Please re-open it to continue.");
                    notDone.soundName = @"alert.aiff";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notDone];
                    
                }];
            }
        }
        
        SVPodcastEntry *entry = download.entry;
        op.completionBlock = ^void() {
            dispatch_group_leave(completionGroup);
            dispatch_async(dispatch_get_main_queue(), ^void() {
                [[UIApplication sharedApplication] endBackgroundTask: background_task];
                background_task = UIBackgroundTaskInvalid;
                [self downloadCompleted:entry];
            });
            
        };
                       
        [queue addOperation:op];
        dispatch_group_enter(completionGroup);
        
    }
}

- (void)downloadCompleted:(SVPodcastEntry *)entry
{
    NSInteger pendingDownloads = queue.operationCount;
    [entry.managedObjectContext performBlock:^{
        
        DDLogInfo(@"Download completed for podcast: %@ - Entry: %@. Remaining in queue: %d", entry.podcast.title, entry.title, pendingDownloads);
        
        
    }];
    
    if (pendingDownloads == 0) {
        DDLogVerbose(@"It was the last download");
        @synchronized(self) {
            downloading = NO;
            cancelling = NO;
        }
    }
}
@end
