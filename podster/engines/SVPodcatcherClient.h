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

- (void)subscribeToFeedWithId:(NSNumber *)feedId onCompletion:(void (^)())completion onError:(SVErrorBlock)onError;

- (void)changeNotificationSetting:(BOOL)shouldNotify
                   forFeedWithURL:(NSString *)feedURL 
                     onCompletion:(void (^)())completion
                          onError:(SVErrorBlock)onError;

- (void)notifyOfUnsubscriptionFromFeed:(NSString *)feedURL                                    
                                          onCompletion:(void(^)(void))completion
                                               onError:(SVErrorBlock)error;

- (void)subscribeToFeedWithURL:(NSString *)feedURL shouldNotify:(BOOL)notify onCompletion:(void (^)(id))completion onError:(SVErrorBlock)onError;

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

-(void)downloadAndPopulatePodcast:(SVPodcast *)podcast
                           withLowerPriority:(BOOL)lowPriority
                                   inContext:(NSManagedObjectContext *)localContext
                                onCompletion:(void (^)(void))onComplete
                                     onError:(SVErrorBlock)onError;

- (void)registerWithDeviceId:(NSString *)deviceId notificationToken:(NSString *)token onCompletion:(void (^)(id))onComplete onError:(SVErrorBlock)onError;

- (void)featuredPodcastsForLanguage:(NSString *)language
                       onCompletion:(PodcastListResponeBlock)completion 
                            onError:(SVErrorBlock)errorBlock;
- (void)updateDeviceReceipt:(NSString *)receipt
               onCompletion:(void (^)(BOOL))onComplete
                    onError:(SVErrorBlock)onError;
- (void)updatePodcastsToDirectMode:(void (^)(BOOL success))complete;
@end
