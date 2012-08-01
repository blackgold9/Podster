//
//  SVDownloadOperation.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVDownloadOperation : NSOperation;

@property (copy) NSManagedObjectID *downloadObjectID;
-(id)initWithEntryId:(NSNumber *)entryId
            filePath:(NSString *)path;
@end
