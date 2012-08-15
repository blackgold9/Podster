//
//  SVDownloadOperation.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDownload.h"

static NSString *const SVDownloadProgressChangedNotification = @"SVDownloadProgressChanged";
static NSString *const SVDownloadStatusChangedNotification = @"SVDownloadStatusChangedNotification";

@interface SVDownloadOperation : NSOperation;

@property (copy) NSManagedObjectID *downloadObjectID;
@property (nonatomic, assign) double progressPercentage;
@property (nonatomic, assign) SVDownloadState downloadStatus;
-(id)initWithEntryId:(NSNumber *)entryId
            filePath:(NSString *)path;
@end
