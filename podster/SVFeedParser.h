//
//  SVFeedParser.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWFeedParser.h"

@class SVPodcast;

typedef void (^CompletionBlock)(void);
@interface SVFeedParser : NSObject<MWFeedParserDelegate>

+ (id)parseData:(NSData *)data withETag:(NSString *)etag andLastModified:(NSString *)cachingLastModified forPodcast:(SVPodcast *)podcast onComplete:(CompletionBlock)complete onError:(SVErrorBlock)error;
@end
