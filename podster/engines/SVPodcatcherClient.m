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
#import "SVFeedParser.h"
#import "AFNetworking.h"
#import "SVPodcastSearchResult.h"
#import "NSString+URLEncoding.h"
#import "AFNetworkActivityIndicatorManager.h"
@implementation SVPodcatcherClient
+ (id)sharedInstance
{
    static SVPodcatcherClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [NSURL URLWithString:@"http://podstore.herokuapp.com"];
        client = [[SVPodcatcherClient alloc] initWithBaseURL:url];
            [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    });
    
    return client;
}
-(id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];

    return self;
}
-(void)findFeedsOnWebPage:(NSString *)pageURL onCompletion:(FeedListResponeBlock)completion onError:(SVErrorBlock)errorBlock
{
    NSString *feedFinderURL = @"feeds/feeds_from_page/%@/json";

    [self getPath:[NSString stringWithFormat:feedFinderURL, [pageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *returnedData = responseObject;
        completion(returnedData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        LOG_NETWORK(1, @"FindFeedsOnWebPage faild with error: %@", error);
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
              LOG_NETWORK(1, @"categoriesInLanguage failed with error: %@", error);
              errorBlock(error);
          }];
}

-(void)podcastsByCategory:(NSInteger)categoryId
          startingAtIndex:(NSInteger)start
                    limit:(NSInteger)limit
             onCompletion:(PodcastListResponeBlock)completion 
                  onError:(SVErrorBlock)errorBlock
{
    NSString *feedFinderURL = [NSString stringWithFormat:@"categories/%d/feeds.json?start=%d&limit=%d", categoryId, start, limit];
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
              LOG_NETWORK(1, @"feedsByCategory faild with error: %@", error);
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

    NSString *queryPath = [NSString stringWithFormat:@"feeds.json?query=%@", AFURLEncodedStringFromStringWithEncoding(query, NSUTF8StringEncoding)];
    [self getPath:queryPath parameters:nil
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
               errorHandler(error);
          }];
}

-(void)downloadAndPopulatePodcastWithFeedURL:(NSString *)feedURL
                           withLowerPriority:(BOOL)lowPriority
                                   inContext:(NSManagedObjectContext *)context
                                onCompletion:(void (^)(void))onComplete
                                     onError:(SVErrorBlock)onError
{
    NSParameterAssert(feedURL);
    NSParameterAssert(context);
    NSDictionary *loggingParamters = [NSDictionary dictionaryWithObject:feedURL forKey:@"FeedURL"];
    [FlurryAnalytics logEvent:@"ParsingFeed" withParameters:loggingParamters timed:YES];
    NSManagedObjectContext *localContext= [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = context;
    
    NSURLRequest *request = [self requestWithMethod:@"GET" path:feedURL parameters:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request 
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                          [SVFeedParser parseData:responseObject
                                                                                  forPodcastAtURL:feedURL
                                                                                        inContext:localContext
                                                                                       onComplete:^{
                                                                                           
                                                                                           [FlurryAnalytics endTimedEvent:@"ParsingFeed" 
                                                                                                           withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Success"]];
                                                                                           [localContext save];
                                                                                           onComplete();
                                                                                       } onError:^(NSError *error) {
                                                                                           LOG_PARSING(2, @"Failure occured while parsing podcast: %@", error);
                                                                                           
                                                                                           [FlurryAnalytics endTimedEvent:@"ParsingFeed" 
                                                                                                           withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"Success"]];
                                                                                           [FlurryAnalytics logError:@"ParsingError" message:[error localizedDescription] error:error];
                                                                                           onError(error);
                                                                                       }];
                                                                          
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          LOG_NETWORK(1, @"A network error occured while trying to download a podcast feed");
                                                                          
                                                                      }];
    
    operation.queuePriority = lowPriority ? NSOperationQueuePriorityLow : NSOperationQueuePriorityNormal;
    [self enqueueHTTPRequestOperation:operation];
}
#pragma mark - push related
-(void)registerForPushNotificationsWithToken:(NSString *)token
                          andDeviceIdentifer:(NSString *)deviceId
                                onCompletion:(void (^)(void))onComplete
                                     onError:(SVErrorBlock)onError;
{ 
    NSParameterAssert(token);
    NSParameterAssert(deviceId);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:token, @"deviceToken",  deviceId, @"deviceId",@"ios", @"platform", nil];
    
    [self postPath:@"devices/create.json" parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               onComplete();
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               LOG_NETWORK(1, @"registerForPushNotification failed with error: %@", error);
               onError(error);
               
           }];
}
 
- (void)notifyOfSubscriptionToFeed:(NSString *)feedURL 
                                     withDeviceId:(NSString *)deviceId
                                     onCompletion:(void (^)(void))completion 
                                          onError:(SVErrorBlock)onError
{
    NSParameterAssert(feedURL);
    NSParameterAssert(deviceId);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:feedURL, @"feedUrl",  deviceId, @"deviceId", nil];
    
    [self postPath:@"subscriptions/create.json" 
        parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 completion();
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               LOG_NETWORK(1, @"subscribe failed with error: %@", error);
               onError(error);
           }];
}

-(void)notifyOfUnsubscriptionFromFeed:(NSString *)feedURL 
                         withDeviceId:(NSString *)deviceId
                         onCompletion:(void (^)(void))completion 
                              onError:(SVErrorBlock)onError
{
    NSParameterAssert(feedURL);
    NSParameterAssert(deviceId);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:feedURL, @"feedUrl",  deviceId, @"deviceId", nil];
   
    [self postPath:@"subscriptions/destroy.json"  parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               completion();               
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               LOG_NETWORK(1, @"unsubscribe failed with error: %@", error);
               onError(error);
           }];
}


@end
