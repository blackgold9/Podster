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
#import "SVPodcastSearchResult.h"
#import "UIDevice+IdentifierAddition.h"

@implementation SVPodcatcherClient
+ (id)sharedInstance
{
    static SVPodcatcherClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[SVPodcatcherClient alloc] initWithHostName:@"podstore.herokuapp.com" customHeaderFields:nil];
      //  client = [[SVPodcatcherClient alloc] initWithHostName:@"localhost:3000" customHeaderFields:nil];
    });
    
    return client;
}

-(MKNetworkOperation *)findFeedsOnWebPage:(NSString *)pageURL onCompletion:(FeedListResponeBlock)completion onError:(MKNKErrorBlock)errorBlock
{
    NSString *feedFinderURL = @"feeds/feeds_from_page/%@/json";
    MKNetworkOperation *op = [[MKNetworkOperation alloc] initWithURLString:[NSString stringWithFormat:feedFinderURL, [pageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] params:nil httpMethod:@"GET"];
    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSArray *returnedData = [completedOperation responseJSON];
        completion(returnedData);
    } onError:^(NSError *error) {
        LOG_NETWORK(1, @"FindFeedsOnWebPage faild with error: %@", error);
        errorBlock(error);
    }];

    [self enqueueOperation:op];
    
    return op;
}

- (MKNetworkOperation *)categoriesInLanguage:(NSString *)language
                                onCompletion:(CategoryResponseBlock)completion 
                                     onError:(MKNKErrorBlock)errorBlock {
    NSString *path = @"categories.json";
    MKNetworkOperation *op = [self operationWithPath:path];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
               NSArray *returnedData = [completedOperation responseJSON];
               NSMutableArray *categories = [NSMutableArray array];
               for(NSDictionary *dict in returnedData) {
                  SVCategory *cat = [SVCategory new];
                   if ([dict valueForKey:@"name"] != [NSNull null]) {
                       cat.name = [dict valueForKey:@"name"];
                   }
                   cat.name = cat.name ? [cat.name gtm_stringByUnescapingFromHTML] : @"Debug: No Title";
                   cat.categoryId = [[dict valueForKey:@"id"] integerValue];
                   [categories addObject:cat];
               }
               completion(categories);
           } onError:^(NSError *error) {
               LOG_NETWORK(1, @"categoriesInLanguage failed with error: %@", error);
               errorBlock(error);
           }];
    
    [self enqueueOperation:op];
    
    return op;

}

-(MKNetworkOperation *)podcastsByCategory:(NSInteger)categoryId
                       startingAtIndex:(NSInteger)start
                                 limit:(NSInteger)limit
                          onCompletion:(PodcastListResponeBlock)completion 
                               onError:(MKNKErrorBlock)errorBlock
{
    NSString *feedFinderURL = [NSString stringWithFormat:@"categories/%d/feeds.json?start=%d&limit=%d", categoryId, start, limit];
    MKNetworkOperation *op = [self operationWithPath:feedFinderURL];    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
           NSArray *returnedData = [completedOperation responseJSON];
           NSMutableArray *podcasts = [NSMutableArray array];
           for(NSDictionary *dict in returnedData) {
               SVPodcastSearchResult *result = [SVPodcastSearchResult new];
               [result populateWithDictionary:dict];
               [podcasts addObject:result];
           }
        
           completion(podcasts);
       } onError:^(NSError *error) {
           LOG_NETWORK(1, @"feedsByCategory faild with error: %@", error);
           errorBlock(error);
       }];
    
    [self enqueueOperation:op];
    
    return op;
}

-(MKNetworkOperation *)searchForPodcastsMatchingQuery:(NSString *)query
                                         onCompletion:(PodcastListResponeBlock)completion 
                                              onError:(MKNKErrorBlock)errorHandler
{
    NSParameterAssert(query);
    NSParameterAssert(completion);
    NSParameterAssert(errorHandler);
    NSString *queryPath = [NSString stringWithFormat:@"feeds.json?query=%@", [query urlEncodedString]];
    MKNetworkOperation *op = [self operationWithPath:queryPath];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSArray *returnedData = [completedOperation responseJSON];
        NSMutableArray *podcasts = [NSMutableArray array];
        for(NSDictionary *dict in returnedData) {
            SVPodcastSearchResult *result = [SVPodcastSearchResult new];
            [result populateWithDictionary:dict];
            [podcasts addObject:result];
        }
        
        completion(podcasts);
    } onError:^(NSError *error) {
        errorHandler(error);
    }];
    
    [self enqueueOperation:op];
    return op;
}

-(MKNetworkOperation *)downloadAndPopulatePodcastWithFeedURL:(NSString *)feedURL
                                                   inContext:(NSManagedObjectContext *)context
                                                onCompletion:(void (^)(void))onComplete
                                                     onError:(MKNKErrorBlock)onError
{
    NSParameterAssert(feedURL);
    NSParameterAssert(context);

    NSManagedObjectContext *localContext= [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = context;
   
    MKNetworkOperation *op = [self operationWithURLString:feedURL];
    [op onCompletion:^void(MKNetworkOperation *completedOperation) {
        [SVFeedParser parseData:[completedOperation responseData]
                     forPodcastAtURL:feedURL
                      inContext:localContext
                     onComplete:^{
                         [localContext save];
                         onComplete();
                     } onError:^(NSError *error) {
                         LOG_PARSING(2, @"Failure occured while parsing podcast: %@", error);
                         onError(error);
                     }];

    } onError:^void(NSError *error) {
        LOG_NETWORK(1, @"A network error occured while trying to download a podcast feed");
    }];
    [self enqueueOperation:op];
    return op;

}
#pragma mark - push related
-(MKNetworkOperation *)registerForPushNotificationsWithToken:(NSString *)token
                                          andDeviceIdentifer:(NSString *)deviceId
                                                onCompletion:(void (^)(void))onComplete
                                                     onError:(MKNKErrorBlock)onError;
{ 
    NSParameterAssert(token);
    NSParameterAssert(deviceId);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:token, @"deviceToken",  deviceId, @"deviceId",@"ios", @"platform", nil];
    MKNetworkOperation *op = [self operationWithPath:@"devices/register.json" 
                                              params:params 
                                          httpMethod:@"POST"];    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        onComplete();
    } onError:^(NSError *error) {
        LOG_NETWORK(1, @"registerForPushNotification failed with error: %@", error);
        onError(error);
    }];
    
    [self enqueueOperation:op];
    
    return op;

    
}
 
-(MKNetworkOperation *)notifyOfSubscriptionToFeed:(NSString *)feedURL 
                                     withDeviceId:(NSString *)deviceId
                                     onCompletion:(void (^)(void))completion 
                                          onError:(MKNKErrorBlock)onError
{
    NSParameterAssert(feedURL);
    NSParameterAssert(deviceId);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:feedURL, @"feedUrl",  deviceId, @"deviceId", nil];
    MKNetworkOperation *op = [self operationWithPath:@"devices/subscribe.json" 
                                              params:params 
                                          httpMethod:@"POST"];    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        completion();
    } onError:^(NSError *error) {
        LOG_NETWORK(1, @"subscribe failed with error: %@", error);
        onError(error);
    }];
    
    [self enqueueOperation:op];
    
    return op;
}


@end
