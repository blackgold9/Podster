//
//  SVPodcatcherClient.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKNetworkEngine.h"
#import "MWFeedParser.h"

@class SVPodcast;

typedef void (^CategoryResponseBlock)(NSArray *categories);
typedef void (^PodcastListResponeBlock)(NSArray *podcasts);
typedef void (^FeedListResponeBlock)(NSArray *feedURLs);
typedef void (^PodcastItemsResponseBlock)(NSArray *entries);

@interface SVPodcatcherClient : MKNetworkEngine<MWFeedParserDelegate>
+(id)sharedInstance;
-(MKNetworkOperation *)categoriesInLanguage:(NSString *)language
                               onCompletion:(CategoryResponseBlock)completion
                                    onError:(MKNKErrorBlock)error;

-(MKNetworkOperation *)searchForPodcastsMatchingQuery:(NSString *)query
                                         onCompletion:(PodcastListResponeBlock)completion
                                              onError:(MKNKErrorBlock)error;

- (MKNetworkOperation *)notifyOfUnsubscriptionFromFeed:(NSString *)feedURL
                                          withDeviceId:(NSString *)deviceId
                                          onCompletion:(void(^)(void))completion
                                               onError:(MKNKErrorBlock)error;

- (MKNetworkOperation *)notifyOfSubscriptionToFeed:(NSString *)feedURL
                                      withDeviceId:(NSString *)deviceId
                                      onCompletion:(void(^)(void))completion
                                           onError:(MKNKErrorBlock)error;

- (MKNetworkOperation *)getAppConfigWithLanguage:(NSString *)language
                                   onCompletion:(void(^)(void))completion
                                         onError:(MKNKErrorBlock)error;

- (MKNetworkOperation *)findFeedsOnWebPage:(NSString *)pageURL
                              onCompletion:(FeedListResponeBlock)completion
                                   onError:(MKNKErrorBlock)error;
-(MKNetworkOperation *)podcastsByCategory:(NSInteger)categoryId
                       startingAtIndex:(NSInteger)start
                                 limit:(NSInteger)limit
                          onCompletion:(PodcastListResponeBlock)completion 
                               onError:(MKNKErrorBlock)errorBlock;

-(MKNetworkOperation *)downloadAndPopulatePodcastWithFeedURL:(NSString *)feedURL
                                                   inContext:(NSManagedObjectContext *)context
                                                onCompletion:(void (^)(void))onComplete
                                                     onError:(MKNKErrorBlock)onError;

-(MKNetworkOperation *)registerForPushNotificationsWithToken:(NSString *)token
                                          andDeviceIdentifer:(NSString *)deviceId
                                                onCompletion:(void (^)(void))onComplete
                                                     onError:(MKNKErrorBlock)onError;

#pragma mark - podcast downloading

@end
