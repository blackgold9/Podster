//
//  SVPodcatcherClient.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SVPodcatcherClient.h"
#import "SVPodcast.h"
#import "SVCategory.h"
#import "GTMNSString+HTML.h"
#import "SVPodcastEntry.h"
#import "AFNetworking.h"
#import "SVPodcastSearchResult.h"
#import "NSString+URLEncoding.h"
#import "AFNetworkActivityIndicatorManager.h"

static const int ddLogLevel = LOG_LEVEL_INFO;
@implementation SVPodcatcherClient
+ (id)sharedInstance
{
    static SVPodcatcherClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [NSURL URLWithString:@"http://api.podsterapp.com/api/v1/"];
        client = [[SVPodcatcherClient alloc] initWithBaseURL:url];

        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    });
    
    return client;
}

- (NSString *)countryCode
{
    NSLocale *current = [NSLocale currentLocale];
    NSString *code = [(NSString *)[current objectForKey:NSLocaleCountryCode] lowercaseString];
    DDLogInfo(@"Making call with country code %@",code);
    return code;
}
-(id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self registerHTTPOperationClass:[AFXMLRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];

    
    return self;
}
-(void)findFeedFromLink:(NSString *)pageURL onCompletion:(FeedResponseBlock)completion onError:(SVErrorBlock)errorBlock
{
    NSDictionary *params = [NSDictionary dictionaryWithObject:pageURL forKey:@"url"];
    [self postPath: @"feeds/feed_from_link.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *data = responseObject ;
        if ([data objectForKey:@"found_feed"] != [NSNull null]) {
            NSString *url = [data objectForKey:@"found_feed"];
            completion(url);
        } else {
            completion(nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        errorBlock(error);
    }];
}

- (void)categoriesInLanguage:(NSString *)language
                onCompletion:(CategoryResponseBlock)completion 
                     onError:(SVErrorBlock)errorBlock {
    
    [self getPath:@"categories.json" 
       parameters:nil 
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *returnedData = responseObject;
              NSMutableArray *categories = [NSMutableArray array];
              for(NSDictionary *dict in returnedData) {
                  SVCategory *cat = [SVCategory new];
                  if ([dict valueForKey:@"name"] != [NSNull null]) {
                      cat.name = [dict valueForKey:@"name"];
                  }
                  cat.name = cat.name ? [cat.name gtm_stringByUnescapingFromHTML] : @"Debug: No Title";
                  cat.categoryId = [[dict valueForKey:@"id"] integerValue];
                  [categories addObject:cat];
                  if ([dict valueForKey:@"image_url"] != [NSNull null]) {
                      cat.imageURL =[NSURL URLWithString:[dict valueForKey:@"image_url"]];
                  }
              }
              completion(categories);
          } 
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              DDLogError(@"categoriesInLanguage failed with error: %@", error);
              errorBlock(error);
          }];
}

-(void)podcastsByCategory:(NSInteger)categoryId
          startingAtIndex:(NSInteger)start
                    limit:(NSInteger)limit
             onCompletion:(PodcastListResponeBlock)completion 
                  onError:(SVErrorBlock)errorBlock
{
    
    NSString *feedFinderURL = [NSString stringWithFormat:@"categories/%d/feeds.json?cc=%@&start=%d&limit=%d", categoryId,[self countryCode], start, limit];
    [self getPath:feedFinderURL
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *returnedData = responseObject;
              NSMutableArray *podcasts = [NSMutableArray array];
              for(NSDictionary *dict in returnedData) {
                  SVPodcastSearchResult *result = [SVPodcastSearchResult new];
                  [result populateWithDictionary:dict];
                  [podcasts addObject:result];
              }
              
              completion(podcasts);
          } 
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              DDLogError(@"feedsByCategory faild with error: %@", error);
              errorBlock(error);
          }];
}

- (void)featuredPodcastsForLanguage:(NSString *)language
                       onCompletion:(PodcastListResponeBlock)completion 
                            onError:(SVErrorBlock)errorBlock
{
    NSString *feedFinderURL = [NSString stringWithFormat:@"feeds/featured.json"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //  if (language) {
    [params setObject:[self countryCode] forKey:@"cc"];
    // }
    NSString *deviceId = [[SVSettings sharedInstance] deviceId];
    [params setObject:deviceId forKey:@"deviceId"];
    [self getPath:feedFinderURL
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              NSMutableArray *featured = [NSMutableArray array];
              for(NSDictionary *groupDict in (NSArray *)responseObject) {
                  NSDictionary *innerGroup = [groupDict objectForKey:@"featuredgroup"];
                  NSMutableDictionary *bucketDict = [NSMutableDictionary dictionary];
                  [bucketDict setValue:[innerGroup valueForKey:@"name"] forKey:@"name"];
                  NSArray *podcastDicts = [innerGroup valueForKey:@"feeds"];
                  NSMutableArray *podcasts = [NSMutableArray array];
                  
                  for (NSDictionary *podcastDict in podcastDicts) {
                      SVPodcastSearchResult *result = [SVPodcastSearchResult new];
                      [result populateWithDictionary:podcastDict];
                      [podcasts addObject:result];
                      
                  }
                  [bucketDict setValue:podcasts forKey:@"feeds"];
                  [featured addObject:bucketDict];
                  
              }
              
              completion(featured);
          } 
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              DDLogError(@"feedsByCategory faild with error: %@", error);
              errorBlock(error);
          }];
    
}



-(void)searchForPodcastsMatchingQuery:(NSString *)query
                         onCompletion:(PodcastListResponeBlock)completion 
                              onError:(SVErrorBlock)errorHandler
{
    NSParameterAssert(query);
    NSParameterAssert(completion);
    NSParameterAssert(errorHandler);

       [self getPath:@"feeds.json" parameters:@{@"cc":[self countryCode], @"query": query}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *returnedData = responseObject;
              NSMutableArray *podcasts = [NSMutableArray array];
              for(NSDictionary *dict in returnedData) {
                  SVPodcastSearchResult *result = [SVPodcastSearchResult new];
                  [result populateWithDictionary:dict];
                  [podcasts addObject:result];
              }
              dispatch_async(dispatch_get_main_queue(), ^{
                  completion(podcasts);
              });
              
          } 
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  errorHandler(error);
              });
              
          }];
}

- (void)updateExistingEpisodesToDirectModeForPodcast:(SVPodcast *)podcast
{
    
}

#pragma mark - push related
- (void)registerWithDeviceId:(NSString *)deviceId 
           notificationToken:(NSString *)token
                onCompletion:(void (^)(id))onComplete onError:(SVErrorBlock)onError
{ 
    NSParameterAssert(deviceId);
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:  deviceId, @"deviceId",@"ios", @"platform",version, @"version", nil];
    if (token) {
        [params setValue:token forKey:@"deviceToken"];
    }
    if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
        [params setValue:@"true" forKey:@"PremiumMode"];
    }
    
    [self postPath:@"devices/create.json" parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   onComplete(responseObject);
               });
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   DDLogError(@"registerForPushNotification failed with error: %@", error);
                   onError(error);                   
               });               
           }];
}

- (void)subscribeToFeedWithURL:(NSString *)feedURL 
                  shouldNotify:(BOOL)notify
                  onCompletion:(void (^)(id))completion
                       onError:(SVErrorBlock)onError
{
    NSParameterAssert(feedURL);
    NSString *deviceId = [[SVSettings sharedInstance] deviceId];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:feedURL, @"feedUrl",  deviceId, @"deviceId", [NSNumber numberWithBool:notify], @"should_notify", nil];
    
    [self postPath:@"subscriptions.json" 
        parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               completion(responseObject);
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               DDLogError(@"subscribe failed with error: %@", error);
               [Flurry logError:@"NetworkFeedSubscribeFailed" message:[error localizedDescription] error:error];
               if (onError) {
                   onError(error);
               }
           }];
}

- (void)fetchPodcastWithId:(NSNumber *)feedId onCompletion:(PodcastListResponeBlock)completion onError:(SVErrorBlock)errorHandler
{
    NSParameterAssert(feedId);
    NSParameterAssert(completion);
    NSParameterAssert(errorHandler);

    if (!feedId) {
        [self returnMissingParameterErrorWithName:@"feedId" errorHandler:errorHandler];
        return;
    }
    
    NSString *queryPath = [NSString stringWithFormat:@"feeds.json?cc=%@&feedId=%@", [self countryCode], feedId];
    [self getPath:queryPath parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *returnedData = responseObject;
              NSMutableArray *podcasts = [NSMutableArray array];
              for(NSDictionary *dict in returnedData) {
                  SVPodcastSearchResult *result = [SVPodcastSearchResult new];
                  [result populateWithDictionary:dict];
                  [podcasts addObject:result];
              }
              dispatch_async(dispatch_get_main_queue(), ^{
                  completion(podcasts);
              });

          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  errorHandler(error);
              });

          }];
}

- (void)subscribeToFeedWithId:(NSNumber *)feedId
                      onCompletion:(void (^)())completion
                           onError:(SVErrorBlock)onError
{
    NSParameterAssert(feedId);
    NSString *deviceId = [[SVSettings sharedInstance] deviceId];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:feedId, @"feedId",  deviceId, @"deviceId", nil];
    
    [self postPath:@"subscriptions"
        parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               completion();
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               DDLogError(@"subscribe failed with error: %@", error);
               [Flurry logError:@"NetworkFeedSubscribeFailed" message:[error localizedDescription] error:error];
               if (onError) {
                   onError(error);
               }
           }];
}

- (void)changeNotificationSetting:(BOOL)shouldNotify
                   forFeedWithId:(NSNumber *)feedId
                     onCompletion:(void (^)())completion
                          onError:(SVErrorBlock)onError
{
    NSParameterAssert(feedId);
    if (!feedId) {
        [self returnMissingParameterErrorWithName:@"feedId" errorHandler:onError];
        return;
    }
    
    NSString *deviceId = [[SVSettings sharedInstance] deviceId];
    [self postPath:@"subscriptions/update.json"
        parameters:[NSDictionary dictionaryWithObjectsAndKeys:deviceId, @"deviceId", feedId, @"feedId", shouldNotify ? @"true" : @"false",@"should_notify", nil]
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (completion) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       completion();
                   });
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//               DDLogError(@"Request: %@ failed with error %@", [[operation request] URL], error);
               if (onError) {
                   onError(error);
               }
           }];
}


-(void)unsubscribeFromFeedWithId:(NSNumber *)podstoreId 
                         onCompletion:(void (^)(void))completion 
                              onError:(SVErrorBlock)onError
{
    NSParameterAssert(podstoreId);
    if (podstoreId == nil) {
        [self returnMissingParameterErrorWithName:@"podstoreId" errorHandler:onError];
        return;
    }
    NSString *deviceId = [[SVSettings sharedInstance] deviceId];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:podstoreId, @"feedId",  deviceId, @"deviceId", nil];
    
    [self postPath:@"subscriptions/destroy.json"  parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               completion();
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               DDLogError(@"unsubscribe failed with error: %@", error);
               onError(error);
           }];
}



- (void)getNewItemsForFeedWithId:(NSNumber *)podstoreId
                withLastSyncDate:(NSDate *)lastSycned
                        complete:(void (^)(id))onComplete
                         onError:(SVErrorBlock)onError
{
    NSParameterAssert(podstoreId);
    NSParameterAssert([podstoreId integerValue] != 0);
    if (podstoreId == nil) {
        [self returnMissingParameterErrorWithName:@"podstoreId" errorHandler:onError];
        return;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    DDLogVerbose(@"Getting newitems for %@ withlast modifided: %@", podstoreId, lastSycned);
    [parameters setObject:podstoreId forKey:@"feed_id"];
    [parameters setObject:[NSNumber numberWithInt:100] forKey:@"limit"];
    if (lastSycned) {
        [parameters setObject:lastSycned forKey:@"after"];
    }


    [self getPath:@"feed_items"
       parameters:parameters
          success:^void(AFHTTPRequestOperation *operation, id responseObject) {
              onComplete(responseObject);
          } failure:^void(AFHTTPRequestOperation *operation, NSError *error) {
        onError(error);

    }];

}

#pragma mark - private

- (void)returnMissingParameterErrorWithName:(NSString *)name
                               errorHandler:(SVErrorBlock)errorBlock
{
    if (name == nil || errorBlock == nil) {
        return;
    } 
    
NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"A required paramter was missing", NSLocalizedDescriptionKey,
                      name, @"Paramter", nil];
errorBlock([NSError errorWithDomain:@"Podster" code:400 userInfo:info]);
    
}
@end
