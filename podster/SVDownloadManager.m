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

@interface SVDownloadManager ()
- (NSString *)downloadsPath;

- (void)ensureDownloadsDirectory;
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
    NSDate *downloadStartedDate;
    //    UIBackgroundTaskIdentifier background_task;
}
+ (id)sharedInstance {
    static SVDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SVDownloadManager alloc] init];
        
    });
    
    return manager;
}

- (id)init {
    self = [super init];
    if (self) {
        [self ensureDownloadsDirectory];
        //        background_task = UIBackgroundTaskInvalid;
        downloading = NO;
        completionGroup = dispatch_group_create();
        currentProgressPercentage = 0;
        operationLookup = [NSMutableDictionary dictionary];
        maxConcurrentDownloads = 2;
        queue = [NSOperationQueue new];
        [queue setMaxConcurrentOperationCount:maxConcurrentDownloads];
        queue.name = @"com.vantertech.podster.downloads";
        [queue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
        NSString *lostWifi = NSLocalizedString(@"Downloads have been paused because you lost WI-FI connectivity", @"Downloads have been paused because you lost WI-FI connectivity");
        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification
                                                          object:nil queue:nil usingBlock:^void(NSNotification *note) {
                                                              AFNetworkReachabilityStatus status = [[SVPodcatcherClient sharedInstance] networkReachabilityStatus];
                                                              if (status == AFNetworkReachabilityStatusReachableViaWiFi || [[SVSettings sharedInstance] downloadOn3g]) {
                                                                  [self downloadPendingEntries];
                                                              } else {
                                                                  DDLogInfo(@"Lost WIFI signal");
                                                                  BOOL wasDownloading = queue.operationCount > 0;
                                                                  if (wasDownloading && ![[SVSettings sharedInstance] downloadOn3g]) {
                                                                      UILocalNotification *notDone = [[UILocalNotification alloc] init];
                                                                      notDone.alertBody = lostWifi;
                                                                      notDone.soundName = @"alert.aiff";
                                                                      [[UIApplication sharedApplication] presentLocalNotificationNow:notDone];
                                                                      [self cancelDownloads];
                                                                  }
                                                              }
                                                          }];
        
    }
    
    return self;
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == queue && [keyPath isEqualToString:@"operations"]) {
        if ([queue.operations count] == 0) {
            // Do something here when your queue has completed
            DDLogVerbose(@"The last download has completed");
            @synchronized (self) {
                downloading = NO;
                cancelling = NO;
                downloadStartedDate = nil;
            }
            
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

- (void)cancelDownloads {
    cancelling = YES;
    DDLogInfo(@"Cancelling downloads");
    
    [queue cancelAllOperations];
    
}

- (void)cancelDownload:(SVDownload *)download {
    for (SVDownloadOperation *op in queue.operations) {
        if ([[op.downloadObjectID URIRepresentation] isEqual:[download.objectID URIRepresentation]]) {
            [op cancel];
            [self deleteFileForEntry:download.entry];
            break;
        }
    }
}

- (void)downloadEntry:(SVPodcastEntry *)entry
       manualDownload:(BOOL)isManualDownload
            inContext:(NSManagedObjectContext *)localContext {

        NSAssert(entry != nil, @"There should be an entry here");

        DDLogVerbose( @"Downloading entry %@", entry);

        if (entry.download) {
            [self startDownload:entry.download];
            return;
        }
        
        
        SVDownload *lastDownload = [SVDownload MR_findFirstWithPredicate:nil
                                                                sortedBy:@"position"
                                                               ascending:YES
                                                               inContext:localContext];
        NSInteger position = 0;
        if (lastDownload) {
            position = lastDownload.positionValue + 1;
        }
        
        DDLogVerbose(@"Download queue position for this download is %d", position);
        
        
        SVDownload *download = entry.download;
        if (!download && !entry.downloadCompleteValue) {
            download = [SVDownload MR_createInContext:localContext];
            [localContext obtainPermanentIDsForObjects:@[download] error:nil];
            download.manuallyTriggeredValue = isManualDownload;
            entry.download = download;
            download.entry = entry;

            NSAssert(entry != nil, @"Entry should not be nil");
                        NSAssert(download != nil, @"Download should not be nil");
            NSAssert(entry.download != nil, @"Entry should have download");
            NSAssert(download.entry != nil, @"download should have entry");
            download.stateValue = SVDownloadStatePending;
            entry.download.positionValue = position;
            [self startDownload:download];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:[download.entry localFilePath]] && download.entry.downloadCompleteValue) {
            NSAssert(false, @"Should not have been able to start downloading a file that is already downloaded");
        }

    
}

- (void)deleteFileForEntry:(SVPodcastEntry *)entry {
    DDLogInfo(@"Checking for file to delete");
    NSString *pathToDelete = [entry localFilePath];
    
    
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToDelete]) {
        DDLogInfo(@"Deleting File: %@", pathToDelete);
        [[NSFileManager defaultManager] removeItemAtPath:pathToDelete error:&error];
        if (error != nil) {
            DDLogWarn( @"Error deleting entry: %@", error);
        }
    } else {
        DDLogInfo(@"There was no file to delete");
    }
}

- (NSString *)downloadsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:kDownloadsDirectory];
    
}

- (void)disableBackupForPath:(NSString *)path {
    DDLogInfo(@"Setting do-not-backup for %@", path);
    const char *attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr([path fileSystemRepresentation], attrName, &attrValue, sizeof(attrValue), 0, 0);
    NSAssert(result == 0, @"Did not set no-backup attribute correctly");
    
}

- (void)ensureDownloadsDirectory {
    NSString *downloadsPath = [self downloadsPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsPath]) {
        
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadsPath
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        [self disableBackupForPath:downloadsPath];
    }
}

- (void)startDownload:(SVDownload *)download {
    __block NSString *mediaURLString;
    __block NSString *filePath;
    [download.managedObjectContext performBlockAndWait:^{
        mediaURLString = download.entry.mediaURL;
        filePath = [download.entry localFilePath];
           }];
    BOOL isVideo = NO;
    isVideo |= [mediaURLString rangeOfString:@"m4v" options:NSCaseInsensitiveSearch].location != NSNotFound;
    isVideo |= [mediaURLString rangeOfString:@"mov" options:NSCaseInsensitiveSearch].location != NSNotFound;
    isVideo |= [mediaURLString rangeOfString:@"mp4" options:NSCaseInsensitiveSearch].location != NSNotFound;
    if ([[SVPodcatcherClient sharedInstance] networkReachabilityStatus] == AFNetworkReachabilityStatusReachableViaWiFi ||
        ([[SVSettings sharedInstance] downloadOn3g] && !isVideo)) {
        SVDownloadOperation *op = [[SVDownloadOperation alloc] initWithEntryId:download.entry.podstoreId
                                                                               filePath:filePath];
        
        SVPodcastEntry *entry = download.entry;
        op.completionBlock = ^void() {
            dispatch_group_leave(completionGroup);
            dispatch_async(dispatch_get_main_queue(), ^void() {
                [self downloadCompletedWithObjectId:entry.objectID];
            });
        };
        
        [queue addOperation:op];
        dispatch_group_enter(completionGroup);
        
    }
}

- (void)downloadCompletedWithObjectId:(NSManagedObjectID *)entryId {
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    
    NSInteger pendingDownloads = queue.operationCount;
    [context performBlock:^{
        SVPodcastEntry *entry = (SVPodcastEntry *)[context existingObjectWithID:entryId error:nil];
        NSAssert(entry != nil, @"Entry should not be nil");
        DDLogInfo(@"Download completed for podcast: %@ - Entry: %@. Remaining in queue: %d", entry.podcast.title, entry.title, pendingDownloads);
    }];
    
}


// REDUX Attempt
- (NSUInteger)numberOfItemsToDownloadAutomaticallyForPodcast:(SVPodcast *)podcast {
    return podcast.downloadsToKeepValue;
}

- (NSSet *)entriesThatShouldBeDownloadedInContext:(NSManagedObjectContext *)context {
    NSMutableSet *needingDownload = [NSMutableSet set];
    
    NSArray *subscribedPodcasts = [SVPodcast MR_findByAttribute:SVPodcastAttributes.isSubscribed
                                                      withValue:[NSNumber numberWithBool:YES]
                                                     andOrderBy:SVPodcastAttributes.title
                                                      ascending:YES
                                                      inContext:context];
    
    for (SVPodcast *podcast in subscribedPodcasts) {
        [needingDownload addObjectsFromArray:[self entriesToBeDownloadedForPodcast:podcast
                                                                         inContext:context]];
    }
    
    return needingDownload;
}

- (NSArray *)entriesToBeDownloadedForPodcast:(SVPodcast *)podcast inContext:(NSManagedObjectContext *)context {
    NSPredicate *isInPodcast = [NSPredicate predicateWithFormat:@"podcast == %@ && %K == NO", podcast, SVPodcastEntryAttributes.played];
    NSArray *entries = [SVPodcastEntry MR_findAllSortedBy:SVPodcastEntryAttributes.datePublished
                                                ascending:NO
                                            withPredicate:isInPodcast
                                                inContext:context];
    
    
    NSUInteger max = [self numberOfItemsToDownloadAutomaticallyForPodcast:podcast];
    if (entries.count > max) {
        return [entries subarrayWithRange:NSMakeRange(0, max)];
    } else {
        return entries;
    }
}

- (NSSet *)entriesNotInSet:(NSSet *)set inContext:(NSManagedObjectContext *)context {
    NSArray *ids = [set valueForKey:@"podstoreId"];
    NSPredicate *hasDownloadCompleteOrInProgress = [NSPredicate predicateWithFormat:@"(%K != nil || %K == YES)", SVPodcastEntryRelationships.download, SVPodcastEntryAttributes.downloadComplete];
    NSPredicate *notInSet = [NSPredicate predicateWithFormat:@"NOT (podstoreId IN %@)", ids];
    NSPredicate *compound = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:notInSet, hasDownloadCompleteOrInProgress, nil]];
    
    NSArray *entriesNotInSet = [SVPodcastEntry MR_findAllWithPredicate:compound
                                                             inContext:context];
    return [NSSet setWithArray:entriesNotInSet];
}

- (void)deleteDownloadsForEntriesNotInSet:(NSSet *)entries inContext:(NSManagedObjectContext *)context {
    DDLogVerbose(@"Determining what needs to be cancelled/deleted");
    NSSet *entriesNeedingDeletion = [self entriesNotInSet:entries inContext:context];
    NSAssert(![entriesNeedingDeletion intersectsSet:entries], @"The entries needing deletion should not intersect the entries we expect to download");
    
    DDLogInfo(@"Found %d entries needing deletion", entriesNeedingDeletion.count);
    [self deleteFilesForEntries:[entriesNeedingDeletion allObjects]
                      inContext:context];
    
}

- (void)deleteFilesForEntries:(NSArray *)entriesNeedingDeletion
                    inContext:(NSManagedObjectContext *)context {
    for (SVPodcastEntry *entry in entriesNeedingDeletion) {
        DDLogVerbose(@"Deleting %@", entry);
        
        entry.downloadCompleteValue = NO;
        entry.podcast.isDownloadingValue = NO;
        if (entry.download) {
            [self cancelDownload:entry.download];
            [context deleteObject:entry.download];
        }
        entry.downloadCompleteValue = NO;
        [self deleteFileForEntry:entry];
        
    }
}

- (void)downloadPendingEntries {
    @synchronized (self) {
        NSTimeInterval elapsedTimeSinceLastDownload = 0;
        if (downloadStartedDate != nil) {
            elapsedTimeSinceLastDownload = [[NSDate date] timeIntervalSinceDate:downloadStartedDate];
        }

        NSTimeInterval oneHour = 60 * 60;
        if (!downloading || elapsedTimeSinceLastDownload > oneHour) {
            if (elapsedTimeSinceLastDownload > oneHour) {
                DDLogInfo(@"Timing out previous download operation");
            }
            
            downloading = YES;
            downloadStartedDate = [NSDate date];
            
        } else {
            DDLogVerbose(@"Donwload manager was busy. Cancelling");
            return;
        }
    }
    
    if (queue) {
        [queue cancelAllOperations];
        DDLogVerbose(@"Cancelling all current download operations");
    }
    
    [queue setSuspended:YES];
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *context) {
        DDLogVerbose(@"Figuring out what entries should be present");
        NSSet *shouldBePresent = [self entriesThatShouldBeDownloadedInContext:context];
        DDLogVerbose(@"Done");
        DDLogVerbose(@"Deleting the downloads managed objects for all other items");
        [self deleteDownloadsForEntriesNotInSet:shouldBePresent
                                      inContext:context];
        DDLogVerbose(@"Done");
        
//        // Get all the files on disk
//        DDLogVerbose(@"Getting list of downloaded files");
//        NSMutableSet *fileNamesToDelete = [NSMutableSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self downloadsPath] error:nil]];
//        DDLogVerbose(@"done");
//        NSMutableSet *pathsToDelete = [NSMutableSet set];
//        NSString *downloadPath = [self downloadsPath];
//        for(NSString *string in fileNamesToDelete) {
//            [pathsToDelete addObject:[downloadPath stringByAppendingPathComponent:string]];
//        }
//        
//        if (shouldBePresent.count > 0) {
//            // Figure out which ones we want to keep
//            NSSet *filesWeWant = [shouldBePresent valueForKey:@"localFilePath"];
//            
//            // Remove the files we want from the files to delete
//            [pathsToDelete minusSet:filesWeWant];
//        }
//        
//        DDLogInfo(@"Deleting %lu files", pathsToDelete.count);
//        for(NSString *path in pathsToDelete) {
//            DDLogVerbose(@"Deleting %@", path);
//            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
//        }
//        
        // Push changesup

        NSError *error;
        if (error) {
            DDLogError(@"Error obtaining permanent IDs: %@", error);
        }
        DDLogInfo(@"Going through %d items that we want stored", shouldBePresent.count);
        for (SVPodcastEntry *entry in shouldBePresent) {
            NSAssert(entry != nil, @"Entry should exist");

            if (!entry.downloadCompleteValue) {
                if (entry.download) {
                    [self startDownload:entry.download];
                } else {
                    [self downloadEntry:entry manualDownload:NO inContext:context];
                }
            } else {
                DDLogVerbose(@"Skipping entry that was already on downloaded/on disk");
            }
        }
             
        
    } completion:^{
        if (queue.operationCount == 0) {
            // No items to download, end here
            @synchronized (self) {
                
                if (downloading) {
                    downloading = NO;
                }
            }
            
        }
     
        [queue setSuspended:NO];
        
        
    }];
}

@end
