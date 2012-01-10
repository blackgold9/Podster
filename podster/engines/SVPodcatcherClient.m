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
@implementation SVPodcatcherClient
+ (id)sharedInstance
{
    static SVPodcatcherClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[SVPodcatcherClient alloc] initWithHostName:@"podstore.herokuapp.com" customHeaderFields:nil];
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
               SVPodcast *podcast = [[SVPodcast alloc] initWithEntity:[SVPodcast entityDescription] insertIntoManagedObjectContext:nil];
               [podcast populateWithDictionary:dict];
               [podcasts addObject:podcast];
           }
           completion(podcasts);
       } onError:^(NSError *error) {
           LOG_NETWORK(1, @"feedsByCategory faild with error: %@", error);
           errorBlock(error);
       }];
    
    [self enqueueOperation:op];
    
    return op;
}

-(MKNetworkOperation *)downloadAndPopulatePodcastWithFeedURL:(SVPodcast *)podcast
                                                   inContext:(NSManagedObjectContext *)context
                                                onCompletion:(void (^)(void))onComplete
                                                     onError:(MKNKErrorBlock)onError
{
    NSParameterAssert(podcast);
    NSParameterAssert(context);
    NSAssert(podcast.feedURL, @"The podcast did not have a feed url");
    NSAssert(podcast.managedObjectContext == context, @"The podcast should be in supplied context");

    NSManagedObjectContext *localContext= [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    localContext.parentContext = context;
         SVPodcast *localPodcast = [podcast inContext:localContext];
   
    MKNetworkOperation *op = [self operationWithURLString:podcast.feedURL];
    [op onCompletion:^void(MKNetworkOperation *completedOperation) {
        [SVFeedParser parseData:[completedOperation responseData]
                     forPodcast:localPodcast
                      inContext:localContext
                     onComplete:^{
                            onComplete();
                     } onError:^(NSError *error) {

        }];

    } onError:^void(NSError *error) {
        LOG_NETWORK(1, @"A network error occured while trying to download a podcast feed");
    }];
    [self enqueueOperation:op];
    return op;

}

        


@end
