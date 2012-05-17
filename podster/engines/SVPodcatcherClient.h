//
//  SVPodcatcherClient.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@class SVPodcast;

typedef void (^CategoryResponseBlock)(NSArray *categories);
typedef void (^PodcastListResponeBlock)(NSArray *podcasts);
typedef void (^FeedResponseBlock)(NSString *result);
typedef void (^PodcastItemsResponseBlock)(NSArray *entries);
typedef void (^SVErrorBlock)(NSError *error);

@interface SVPodcatcherClient : AFHTTPClient
+(id)sharedInstance;
-(void)categoriesInLanguage:(NSString *)language
                               onCompletion:(CategoryResponseBlock)completion
                                    onError:(SVErrorBlock)error;

-(void)searchForPodcastsMatchingQuery:(NSString *)query
                                         onCompletion:(PodcastListResponeBlock)completion
                                              onError:(SVErrorBlock)error;

- (void)fetchPodcastWithId:(NSNumber *)podstoreId
              onCompletion:(PodcastListResponeBlock)completion
                   onError:(SVErrorBlock)error;

- (void)subscribeToFeedWithId:(NSNumber *)feedId onCompletion:(void (^)())completion onError:(SVErrorBlock)onError;

- (void)changeNotificationSetting:(BOOL)shouldNotify
                   forFeedWithId:(NSNumber *)feedId
                     onCompletion:(void (^)())completion
                          onError:(SVErrorBlock)onError;

-(void)unsubscribeFromFeedWithId:(NSNumber *)podstoreId 
                    onCompletion:(void (^)(void))completion 
                         onError:(SVErrorBlock)onError;
- (void)getNewItemsForFeedWithId:(NSNumber *)podstoreId withLastSyncDate:(NSDate *)lastSycned complete:(void (^)(id))onComplete onError:(SVErrorBlock)onError;


- (void)subscribeToFeedWithURL:(NSString *)feedURL shouldNotify:(BOOL)notify onCompletion:(void (^)(id))completion onError:(SVErrorBlock)onError;


-(void)findFeedFromLink:(NSString *)pageURL 
           onCompletion:(FeedResponseBlock)completion
                onError:(SVErrorBlock)errorBlock;

-(void)podcastsByCategory:(NSInteger)categoryId
                       startingAtIndex:(NSInteger)start
                                 limit:(NSInteger)limit
                          onCompletion:(PodcastListResponeBlock)completion 
                               onError:(SVErrorBlock)errorBlock;


- (void)registerWithDeviceId:(NSString *)deviceId notificationToken:(NSString *)token onCompletion:(void (^)(id))onComplete onError:(SVErrorBlock)onError;

- (void)featuredPodcastsForLanguage:(NSString *)language
                       onCompletion:(PodcastListResponeBlock)completion 
                            onError:(SVErrorBlock)errorBlock;

@end
