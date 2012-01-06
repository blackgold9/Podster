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
#import "SVSubscription.h"
#include <sys/xattr.h>

@interface SVDownloadManager()
-(NSString *)downloadsPath;
-(void)ensureDownloadsDirectory;
@end
@implementation SVDownloadManager {
    NSMutableArray *downloads;
    NSInteger currentProgressPercentage;
    MKNetworkEngine *downloadEngine;
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
        downloads = [NSMutableArray array];
        [self ensureDownloadsDirectory];
        currentProgressPercentage = 0;
        downloadEngine = [[MKNetworkEngine alloc] initWithHostName:nil
                                                customHeaderFields:nil];
    }
    
    return self;
}

-(void)downloadEntry:(SVPodcastEntry *)entry
{
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
    
    [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        SVPodcastEntry *localEntry = [entry MR_inContext:localContext];
        SVDownload *download = localEntry.download;
        localEntry.download.positionValue = position;
        if (!download) {
            localEntry.download = [SVDownload MR_createEntity];
        }
        download.filePath = [[self downloadsPath] stringByAppendingPathComponent:[localEntry identifier]];
        MKNetworkOperation *op = [downloadEngine operationWithURLString:entry.mediaURL];
        if (headers){ 
            NSLog(@"Set custom headers: %@", headers);
            [op addHeaders:headers];
        }
        
        [op setDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath append:YES]];
        [op onDownloadProgressChanged:^(double progress) {
            NSInteger percentage = (NSInteger)(progress * 100);
            if (currentProgressPercentage != percentage) {
                currentProgressPercentage = percentage;
                NSLog(@"Download Progress: %d" , currentProgressPercentage);
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[entry identifier], @"identifier",[NSNumber numberWithDouble:progress], @"progress",  nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadProgressChanged" object:nil userInfo:info];
                [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
                    localEntry.download.progressValue = progress;  
                } saveParentContext:NO];
            }
        }];
        
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            [downloads removeObject:download];
            [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *innerContext) {
                localEntry.downloadCompleteValue = YES;
                [localEntry.download MR_deleteInContext:innerContext];                
            }];
        } onError:^(NSError *error) {
            NSLog(@"Download failed with Error: %@", error);
        }];

                
  
        [downloadEngine enqueueOperation:op];
        [downloads addObject:localEntry.download];
    }];

}

- (NSArray *)downloadQueue
{
    
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
