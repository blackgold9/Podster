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
#import "SVPodcatcherClient.h"
#import <sys/xattr.h>
static const int ddLogLevel = LOG_LEVEL_INFO;
@implementation SVDownloadOperation {
    BOOL _isExecuting;
    BOOL _isFinished;
    AFHTTPRequestOperation *networkOp;
    NSInteger currentProgressPercentage;
    UIBackgroundTaskIdentifier task;
    NSString *filePath;
    long long initialSize;
    SVDownload *download;
}
@synthesize downloadObjectID;
-(id)initWithDownloadObjectID:(NSManagedObjectID *)objectId
             filePath:(NSString *)path
{
    self = [super init];
    if (self) {
        NSParameterAssert(objectId);
        NSParameterAssert(path);

        self.downloadObjectID = objectId;
        filePath = [path copy];
        
    }
    return self;
}
- (void)downloadProgressChanged:(double)progress forDownload:(SVDownload *)localDownload
{
    NSInteger percentage = MIN(100,(NSInteger)(progress * 100));
    if (currentProgressPercentage != percentage) {
        currentProgressPercentage = percentage;
        DDLogVerbose(@"Download Progress: %d for entry: %@" , currentProgressPercentage, localDownload.entry.title);
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[localDownload.entry podstoreId], @"podstoreId", [NSNumber numberWithDouble:progress], @"progress",  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadProgressChanged" object:nil userInfo:info];
        [[NSManagedObjectContext MR_defaultContext] performBlock: ^{

            localDownload.stateValue = SVDownloadStateDownloading;
                localDownload.entry.podcast.downloadPercentageValue = percentage;
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
    DDLogInfo(@"Download Operation Complete. Ending background task");
    [[UIApplication sharedApplication] endBackgroundTask: task]; //Tell the system that we are done with the tasks
    task = UIBackgroundTaskInvalid; //Set the task to be invalid
}

-(void)start
{
    task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
        [[UIApplication sharedApplication] endBackgroundTask: task]; //Tell the system that we are done with the tasks
        task = UIBackgroundTaskInvalid; //Set the task to be invalid
        UILocalNotification *notDone = [[UILocalNotification alloc] init];
        notDone.alertBody = NSLocalizedString(@"Podster can only download for 10 minutes in the background. Please re-open it to continue.", @"Podster can only download for 10 minutes in the background. Please re-open it to continue.");
        notDone.soundName = @"alert.aiff";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notDone];
        
    }];

  //  dispatch_semaphore_t semaphore =  dispatch_semaphore_create(0);
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_defaultContext];

    __block SVDownload *theDownload;
    [localContext performBlockAndWait:^{
        theDownload = (SVDownload *)[localContext objectWithID:self.downloadObjectID];
        NSAssert(theDownload.entry != nil, @"the download should have an entry");
        DDLogInfo(@"Downloading %@ - %@  at URL: %@", theDownload.entry.podcast.title, theDownload.entry.title, theDownload.entry.mediaURL);
        NSAssert(!theDownload.entry.downloadCompleteValue, @"This entry is already downloaded");
               
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        theDownload.stateValue = SVDownloadStateDownloading;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:theDownload.entry.mediaURL]];
               
        __block BOOL alreadyDownloaded = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[theDownload.entry localFilePath]] ){
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:NULL];
            NSNumber *size = [attributes objectForKey:NSFileSize];
            if (theDownload.entry.contentLengthValue <= [size integerValue]) {
                // We're done here.
                alreadyDownloaded = YES;
                [localContext performBlockAndWait:^{
                    DDLogInfo(@"Downloading file %@ complete. Setting DownloadComplete = YES", [theDownload.entry localFilePath]);
                    SVPodcastEntry *entry = theDownload.entry;
                    entry.downloadCompleteValue = YES;                
                    entry.podcast.downloadCount = [NSNumber numberWithUnsignedInteger:[entry.podcast.items filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"downloadComplete = YES && played == NO"]].count];
                    DDLogVerbose(@"Podcast %@ now has %d completed downloads", entry.podcast.title, entry.podcast.downloadCountValue);
                    if (theDownload) {
                        [theDownload MR_deleteInContext:localContext];
                        entry.download = nil;
                    }
                    [self done];
                    
                }];
                DDLogInfo(@"Podcast was already downloaded. Completing");
            } else {
                initialSize = [size longLongValue];
                [request setValue:[NSString stringWithFormat:@"bytes=%lld-", initialSize] forHTTPHeaderField:@"Range"];
                DDLogInfo(@"Resuming download at %lld bytes", initialSize);
            }
        } else {
            initialSize = 0;
        }
        if (alreadyDownloaded) {
            return;
        }

         AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];

        [op setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath append:YES]];
        [op setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
            return nil;
        }];
        [op setDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            double progress =  [[NSNumber numberWithDouble:initialSize + totalBytesRead] doubleValue] / [[NSNumber numberWithDouble:totalBytesExpectedToRead] doubleValue];
            [self downloadProgressChanged:progress
                              forDownload:theDownload];
        }];      
        
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self downloadComplete];
                        
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self downloadFailed:error];
            
        }];
        networkOp = op;
        [op start];
       
    }];
    
    download = theDownload;
}

- (void)downloadComplete
{
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
       
            SVDownload *localDownload = (SVDownload *)[localContext objectRegisteredForID:self.downloadObjectID];
            NSAssert(localDownload.entry != nil, @"download should have an etnry");
            SVPodcastEntry *entry = localDownload.entry;
            NSAssert(entry != nil, @"There should be an entry");
            DDLogInfo(@"Downloading file %@ complete. Setting DownloadComplete = YES", [entry localFilePath]);
            
            entry.downloadCompleteValue = YES;
            entry.podcast.downloadCount = [NSNumber numberWithUnsignedInteger:[entry.podcast.items filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"downloadComplete = YES && played == NO"]].count];
            DDLogVerbose(@"Podcast %@ now has %d completed downloads", entry.podcast.title, entry.podcast.downloadCountValue);
            if (localDownload) {
                entry.download = nil;
                [localDownload MR_deleteInContext:localContext];
            }
          } completion:^{
        [self done];
    }];

}

- (void)downloadFailed:(NSError *)error
{
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        [localContext performBlockAndWait:^{
        SVDownload *localDownload = [download MR_inContext:localContext];
       // DDLogError(@"Failed to download episode: %@ with error %@", localDownload.entry.title, error);
        localDownload.stateValue = SVDownloadStateFailed;
        [localDownload MR_deleteInContext:localContext];
        }];
    } completion:^{
        [self done];
    }];
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

- (void)disableBackupForPath:(NSString *)path
{
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    DDLogVerbose(@"Disabling backup for %@", path);
    int result = setxattr([path fileSystemRepresentation], attrName, &attrValue, sizeof(attrValue), 0, 0);       
    NSAssert(result == 0, @"Did not set no-backup attribute correctly");
    
}
@end
