//
//  SVGPodderClient.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^TagListResponseblock)(NSArray *tags);
typedef void (^PodcastListResponseBlock )(NSArray *podcasts);
@interface SVGPodderClient : MKNetworkEngine
+(id)sharedInstance;
-(MKNetworkOperation *)getTopTagsWithLimit:(NSUInteger)limit
                              onCompletion:(TagListResponseblock)completion
                                   onError:(MKNKErrorBlock)error;

-(MKNetworkOperation *)getPodcastsForTag:(NSString *)tag
                                   withLimit:(NSUInteger)limit
                              onCompletion:(TagListResponseblock)completion
                                   onError:(MKNKErrorBlock)error;
-(MKNetworkOperation *)searchForPodcastsMatchingQuery:(NSString *)query
                            onCompletion:(TagListResponseblock)completion
                                 onError:(MKNKErrorBlock)error;
@end
