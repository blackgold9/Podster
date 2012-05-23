//
//  SVDownloadManager.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SVPodcast;
@class SVPodcastEntry;
@class SVDownload;
@interface SVDownloadManager : NSObject
+ (id)sharedInstance;

- (void)downloadEntry:(SVPodcastEntry *)entry manualDownload:(BOOL)isManualDownload;

- (void)deleteFileForEntry:(SVPodcastEntry *)entry;

- (void)resumeDownloads;
- (void)cancelDownload:(SVDownload *)download;

- (void)downloadPendingEntries;
@end
