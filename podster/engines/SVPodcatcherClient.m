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
    //[self setDefaultHeader:@"Accept" value:@"application/json"];

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

-(void)topPodcastsStartingAtIndex:(NSInteger)start
                            limit:(NSInteger)limit
                     onCompletion:(PodcastListResponeBlock)completion 
                          onError:(SVErrorBlock)errorBlock
{
    NSString *feedFinderURL = [NSString stringWithFormat:@"feeds.json?start=%d&limit=%d", start, limit];
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

- (void)featuredPodcastsForLanguage:(NSString *)language
                       onCompletion:(PodcastListResponeBlock)completion 
                            onError:(SVErrorBlock)errorBlock
{
    NSString *feedFinderURL = [NSString stringWithFormat:@"feeds/featured.json"];
    [self getPath:feedFinderURL
       parameters:nil
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
    LOG_GENERAL(2,@">>>>> %@", NSStringFromSelector(_cmd) );
    NSDictionary *loggingParamters = [NSDictionary dictionaryWithObject:feedURL forKey:@"FeedURL"];
    [FlurryAnalytics logEvent:@"ParsingFeed" withParameters:loggingParamters timed:YES];
    NSManagedObjectContext *localContext= [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = context;
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:feedURL parameters:nil];
   
    [localContext performBlock:^{
        
        LOG_GENERAL(2, @"Fetching podcast in local context");        
        SVPodcast *podcast = [SVPodcast findFirstWithPredicate:[NSPredicate predicateWithFormat:@"feedURL == %@", feedURL]
                                           inContext:localContext];


    if (podcast && podcast.etag) {       
        [request setValue:podcast.etag forHTTPHeaderField:@"If-None-Match"];
    }

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request 
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {

                                                                          NSString *returnedETag = [[[operation response] allHeaderFields] valueForKey:@"ETag"];
                                                                          NSString *cachingLastModified = [[[operation response] allHeaderFields] valueForKey:@"Last-Modified"];
                                                                          LOG_NETWORK(3, @"Returned ETag: %@", returnedETag );
                                                                          [SVFeedParser parseData:responseObject
                                                                                         withETag:returnedETag
                                                                                  andLastModified:cachingLastModified
                                                                                  forPodcastAtURL:feedURL
                                                                                        inContext:localContext
                                                                                       onComplete:^{
                                                                                           LOG_GENERAL(2, @"Parssing complete");
                                                                                           [FlurryAnalytics endTimedEvent:@"ParsingFeed" 
                                                                                                           withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Success"]];
                                                                                           [localContext save:nil];
                                                                                           onComplete();
                                                                                       } onError:^(NSError *error) {
                                                                                           LOG_PARSING(2, @"Failure occured while parsing podcast: %@", error);
                                                                                           
                                                                                           [FlurryAnalytics endTimedEvent:@"ParsingFeed" 
                                                                                                           withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"Success"]];
                                                                                           [FlurryAnalytics logError:@"ParsingError" message:[error localizedDescription] error:error];
                                                                                           onError(error);
                                                                                       }];
                                                                          
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          if ([[operation response] statusCode] == 304) {
                                                                              // This is a valid case
                                                                              LOG_NETWORK(2, @"Feed has not changed (Server returned 304");
                                                                              [FlurryAnalytics logEvent:@"FeedNotChangedYAY"];
                                                                              onComplete();
                                                                          } else {
                                                                          
                                                                              LOG_NETWORK(1, @"A network error occured while trying to download a podcast feed. %@", error);
                                                                              [FlurryAnalytics logError:@"Downloading a feed failed" message:[error localizedDescription] error:error];
                                                                          }
                                                                          
                                                                      }];
    
    operation.queuePriority = lowPriority ? NSOperationQueuePriorityLow : NSOperationQueuePriorityNormal;
    [self enqueueHTTPRequestOperation:operation];
    }];
}

#pragma mark - push related
-(void)registerForPushNotificationsWithToken:(NSString *)token
                          andDeviceIdentifer:(NSString *)deviceId
                                onCompletion:(void (^)(void))onComplete
                                     onError:(SVErrorBlock)onError;
{ 
    NSParameterAssert(token);
    NSParameterAssert(deviceId);
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:token, @"deviceToken",  deviceId, @"deviceId",@"ios", @"platform",version, @"version", nil];
    
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
               [FlurryAnalytics logEvent:@"FeedNotificationsSubscribed" withParameters:params];
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               LOG_NETWORK(1, @"subscribe failed with error: %@", error);
               [FlurryAnalytics logError:@"FeedNotificationsSubscribed" message:[error localizedDescription] error:error];
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

               [FlurryAnalytics logEvent:@"FeedNotificationsUnsubscribed" withParameters:params];
           } 
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               LOG_NETWORK(1, @"unsubscribe failed with error: %@", error);
               onError(error);
               [FlurryAnalytics logError:@"FeedNotificationsUnsubscribed" message:[error localizedDescription] error:error];
           }];
}


@end
