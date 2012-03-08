//
//  SVPodcatcherClient.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "MWFeedParser.h"

@class SVPodcast;

typedef void (^CategoryResponseBlock)(NSArray *categories);
typedef void (^PodcastListResponeBlock)(NSArray *podcasts);
typedef void (^FeedResponseBlock)(NSString *result);
typedef void (^PodcastItemsResponseBlock)(NSArray *entries);
typedef void (^SVErrorBlock)(NSError *error);

@interface SVPodcatcherClient : AFHTTPClient<MWFeedParserDelegate>
+(id)sharedInstance;
-(void)categoriesInLanguage:(NSString *)language
                               onCompletion:(CategoryResponseBlock)completion
                                    onError:(SVErrorBlock)error;

-(void)searchForPodcastsMatchingQuery:(NSString *)query
                                         onCompletion:(PodcastListResponeBlock)completion
                                              onError:(SVErrorBlock)error;

- (void)changeNotificationSetting:(BOOL)shouldNotify forFeedWithURL:(NSString *)feedURL onCompletion:(void (^)())completion onError:(SVErrorBlock)onError;

- (void)notifyOfUnsubscriptionFromFeed:(NSString *)feedURL
                                          withDeviceId:(NSString *)deviceId
                                          onCompletion:(void(^)(void))completion
                                               onError:(SVErrorBlock)error;

- (void)notifyOfSubscriptionToFeed:(NSString *)feedURL
                                      withDeviceId:(NSString *)deviceId
                                      onCompletion:(void(^)(void))completion
                                           onError:(SVErrorBlock)error;

- (void)getAppConfigWithLanguage:(NSString *)language
                                   onCompletion:(void(^)(void))completion
                                         onError:(SVErrorBlock)error;

-(void)findFeedFromLink:(NSString *)pageURL 
           onCompletion:(FeedResponseBlock)completion
                onError:(SVErrorBlock)errorBlock;

-(void)podcastsByCategory:(NSInteger)categoryId
                       startingAtIndex:(NSInteger)start
                                 limit:(NSInteger)limit
                          onCompletion:(PodcastListResponeBlock)completion 
                               onError:(SVErrorBlock)errorBlock;

-(void)topPodcastsStartingAtIndex:(NSInteger)start
                            limit:(NSInteger)limit
                     onCompletion:(PodcastListResponeBlock)completion 
                          onError:(SVErrorBlock)errorBlock;

-(void)downloadAndPopulatePodcastWithFeedURL:(NSString *)feedURL
                           withLowerPriority:(BOOL)lowPriority
                                   inContext:(NSManagedObjectContext *)context
                                onCompletion:(void (^)(void))onComplete
                                     onError:(SVErrorBlock)onError;

-(void)registerForPushNotificationsWithToken:(NSString *)token
                                          andDeviceIdentifer:(NSString *)deviceId
                                                onCompletion:(void (^)(void))onComplete
                                                     onError:(SVErrorBlock)onError;

- (void)featuredPodcastsForLanguage:(NSString *)language
                       onCompletion:(PodcastListResponeBlock)completion 
                            onError:(SVErrorBlock)errorBlock;
#pragma mark - podcast downloading

@end
