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
    __block NSMutableArray *currentDownloads;
    dispatch_group_t completionGroup;
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
        completionGroup = dispatch_group_create();
        currentProgressPercentage = 0;
        operationLookup = [NSMutableDictionary dictionary];
        maxConcurrentDownloads = 2;
        currentDownloads = [NSMutableArray array];
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
            // HACK: This should re-trigger the download
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
        NSString *title = entry.podcast.title.length > 100 ? [[entry.podcast.title substringToIndex:97] stringByAppendingString:@"..."] : entry.podcast.title;

        BOOL hasTitle  = NO;
        for (NSString *currentTitle in currentDownloads) {
            if ([currentTitle isEqualToString:title]) {
                hasTitle = YES;
                DDLogWarn(@"WARNING: Attempting to add a title to the download list that was already downloading");
                break;
            }
        }

        if (!hasTitle) {
            [currentDownloads addObject:title];
        }

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
            DDLogWarn(@"Attempting to download a file that was already downloaded");
            //  NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");

            return;
        }


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
                dispatch_group_leave(completionGroup);
                dispatch_async(dispatch_get_main_queue(), ^void() {
                    [[UIApplication sharedApplication] endBackgroundTask: background_task];
                                    background_task = UIBackgroundTaskInvalid;
                });

            };


            if (queue.operationCount ==0) {
                dispatch_group_notify(completionGroup, dispatch_get_main_queue(), ^{
                          DDLogVerbose(@"Empty queue block triggered");
                          if(!cancelling && currentDownloads.count > 0) {
                              DDLogVerbose(@"Queue was in progress when it was emptied");
                              UILocalNotification *downloadedNotification = [[UILocalNotification alloc] init];
                              if (currentDownloads.count > 1) {

                                      DDLogVerbose(@"Downloaded: %@", [currentDownloads componentsJoinedByString:@", "]);

                                  downloadedNotification.alertBody = [NSString stringWithFormat: NSLocalizedString(@"\"%@\" and %d other podcasts have finished downloading", @"%@ and %d other podcasts finished downloading"), [currentDownloads objectAtIndex:0], currentDownloads.count];
                              } else {
                                  downloadedNotification.alertBody = [NSString stringWithFormat: NSLocalizedString(@"\"%@\" has finished downloading",@"\"%@\" has finished downloading"), [currentDownloads objectAtIndex:0]];
                              }
                              downloadedNotification.soundName = @"alert.aiff";
                              [[UIApplication sharedApplication] presentLocalNotificationNow:downloadedNotification];
                              [currentDownloads removeAllObjects];

                          }  else {
                              cancelling = NO;
                          }

                      });

                [queue addOperation:op];
                            dispatch_group_enter(completionGroup);

            }
        } else {
            LOG_DOWNLOADS(2, @"Queued download but did not start it since we're not on wifi");
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
        NSAssert(error == nil, @"Failure deleting entry");
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
@end
