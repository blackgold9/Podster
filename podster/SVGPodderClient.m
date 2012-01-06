//
//  SVGPodderClient.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGPodderClient.h"
#import "SVPodcast.h"

@implementation SVGPodderClient
+ (id)sharedInstance
{
    static SVGPodderClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[SVGPodderClient alloc] initWithHostName:@"gpodder.net" customHeaderFields:nil];
    });
    
    return client;
}
-(MKNetworkOperation*)getTopTagsWithLimit:(NSUInteger)limit
                             onCompletion:(TagListResponseblock)completionBlock
                                  onError:(MKNKErrorBlock)errorBlock
{
    MKNetworkOperation *op = [self operationWithPath:[NSString stringWithFormat:@"api/2/tags/%i.json", limit]
                                              params:nil 
                                          httpMethod:@"GET"];
    [op onCompletion:^(MKNetworkOperation *completedOperation)
     {
         // the completionBlock will be called twice. 
         // if you are interested only in new values, move that code within the else block
         
         NSArray *tags= [completedOperation responseJSON];  
         
         completionBlock([tags valueForKey:@"tag"]);
         
     }onError:^(NSError* error) {
         if (errorBlock){
             errorBlock(error);
         }
     }];
    
    [self enqueueOperation:op];
    
    return op;
}

-(MKNetworkOperation *)getPodcastsForTag:(NSString *)tag
                               withLimit:(NSUInteger)limit
                            onCompletion:(PodcastListResponseBlock)completionBlock
                                 onError:(MKNKErrorBlock)errorBlock
{
    MKNetworkOperation *op = [self operationWithPath:[NSString stringWithFormat:@"api/2/tag/%@/%i.json", [tag urlEncodedString], limit]
                                              params:nil 
                                          httpMethod:@"GET"];
    [op onCompletion:^(MKNetworkOperation *completedOperation)
     {
         NSMutableArray *podcasts = [NSMutableArray new];
         // the completionBlock will be called twice. 
         // if you are interested only in new values, move that code within the else block
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            context.parentContext = [NSManagedObjectContext defaultContext];
            NSArray *podcastsData= [completedOperation responseJSON]; 
            
            
            for(NSDictionary *podcastDictionary in podcastsData)
            {
                SVPodcast *podcast = [[SVPodcast findAllWithPredicate:[NSPredicate predicateWithFormat:@"feedURL == %@", [podcastDictionary valueForKey:@"url"]] inContext:context] lastObject];

                if (!podcast) {
                    NSLog(@"Had to create new podcast");
                    podcast = [SVPodcast MR_createInContext:context];
                } else {
                    NSLog(@"Podcast already existed");
                }
                
                [podcast populateWithGPodderDictionary:podcastDictionary];
                [podcasts addObject:podcast];
                
                
            }
            [context save:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                for (int index = 0; index < podcasts.count; index++) {
                    SVPodcast *localPodcast = [podcasts objectAtIndex:index];
                    [podcasts replaceObjectAtIndex:index 
                                        withObject:[localPodcast MR_inContext:[NSManagedObjectContext MR_defaultContext]]];
                }

                completionBlock(podcasts);
                [[NSManagedObjectContext MR_defaultContext] performBlock:^{
                    [[NSManagedObjectContext MR_defaultContext] save:nil];
                }];
            });
        });
         
         
     }onError:^(NSError* error) {
         if (errorBlock){
             errorBlock(error);
         }
     }];
    
    [self enqueueOperation:op];
    
    return op;

}

-(MKNetworkOperation *)searchForPodcastsMatchingQuery:(NSString *)query
                                         onCompletion:(PodcastListResponseBlock)completionBlock
                                              onError:(MKNKErrorBlock)errorBlock
{
    MKNetworkOperation *op = [self operationWithPath:[NSString stringWithFormat:@"search.json?q=", [query stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]
                                              params:nil 
                                          httpMethod:@"GET"];
    [op onCompletion:^(MKNetworkOperation *completedOperation)
     {
         // the completionBlock will be called twice. 
         // if you are interested only in new values, move that code within the else block
         
         NSArray *podcastsData= [completedOperation responseJSON]; 
         NSMutableArray *podcasts = [NSMutableArray new];
         for(NSDictionary *podcastDictionary in podcastsData)
         {
             SVPodcast *podcast =  [SVPodcast MR_createEntity];
             [podcast populateWithGPodderDictionary:podcastDictionary];
             [podcasts addObject:podcast];
             
         }
         
         completionBlock(podcasts);
         
     }onError:^(NSError* error) {
         if (errorBlock){
             errorBlock(error);
         }
     }];
    
    [self enqueueOperation:op];
    
    return op;
}
@end
