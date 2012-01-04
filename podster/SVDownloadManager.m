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
#import "SVSubscription.h"
#include <sys/xattr.h>

@interface SVDownloadManager()
-(NSString *)downloadsPath;
-(void)ensureDownloadsDirectory;
@end
@implementation SVDownloadManager
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
    }
    
    return self;
}
- (NSArray *)entriesMarkedForDownload
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markedForDownload == YES"];
    NSArray *markedForDownload = [SVPodcastEntry MR_findAllSortedBy:SVPodcastEntryAttributes.datePublished
                                                        ascending:NO
                                                    withPredicate:predicate];
    return markedForDownload;
}

- (NSArray *)autoDownloadEntriesForSubscription:(SVSubscription *)subscription
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"podcast == %@", subscription.podcast];
    NSArray *items = [SVPodcastEntry MR_findAllSortedBy:SVPodcastEntryAttributes.datePublished
                                           ascending:subscription.newestFirstValue
                                       withPredicate:predicate];

    NSUInteger numberToFetch = MAX([subscription.autoDownloadCount unsignedIntegerValue], items.count);
    return [items subarrayWithRange:NSMakeRange(0, numberToFetch)];
}


-(void)downloadEntry:(SVPodcastEntry *)entry
{
    NSMutableSet *entries = [NSMutableSet set];
    NSArray *subscriptions = [SVSubscription MR_findAll];

   for(SVSubscription *subscription in subscriptions) {

   }

}

- (NSArray *)downloadQueue
{
    SVSubscription *sub = nil;
    return nil;
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
