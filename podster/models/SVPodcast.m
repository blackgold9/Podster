#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
#import "SVPodcastEntry.h"
#import "NSString+MD5Addition.h"
#import "SVDownloadManager.h"
#import "_SVPodcastEntry.h"
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation SVPodcast {
    BOOL isUpdatingFromV1;
}

// Custom logic goes here.
-(void)populateWithDictionary:(NSDictionary *)dictionary
{
    self.title = [dictionary stringForKey:@"title"];
    self.title = [self.title capitalizedString];
    NSParameterAssert(self.title);
    self.summary = [dictionary stringForKey:@"summary"];
    self.feedURL = [dictionary stringForKey:@"feed_url"];
    self.author = [dictionary stringForKey:@"author"];
    NSParameterAssert(self.feedURL);
    self.subtitle = [dictionary stringForKey:@"subtitle"];
    self.websiteURL = [dictionary stringForKey:@"website_url"];
    
    self.logoURL = [dictionary stringForKey:@"logo"];
    
    self.smallLogoURL = [dictionary stringForKey:@"logo_small"];
    self.tinyLogoURL = [dictionary stringForKey:@"logo_tiny"];
    self.thumbLogoURL = [dictionary stringForKey:@"logo_thumb"];
    self.podstoreId = [dictionary objectForKey:@"id"];
}

- (void)populateWithPodcast:(id<ActsAsPodcast>)podcast
{
    self.title =podcast.title;
    self.summary = podcast.summary;
    self.logoURL = podcast.logoURL;
    self.feedURL = podcast.feedURL;
    self.thumbLogoURL = [podcast thumbLogoURL];
    self.smallLogoURL = [podcast smallLogoURL];
    self.tinyLogoURL = [podcast tinyLogoURL];
    self.podstoreId = [podcast podstoreId];
}

- (void)updateNewEpisodeCount
{

        @try {                        
            SVPodcast *podcast = self;
            NSUInteger newCount = 0;
            NSAssert(self.isSubscribed, @"IsSubscribed should have a value");
            NSNumber *subscribedNumber= [self isSubscribed];
            BOOL subscribed = [subscribedNumber boolValue];
            
            if (subscribed) {
                if (podcast.subscribedDate == nil) {
                    podcast.subscribedDate = [NSDate date];
                }
                newCount = [SVPodcastEntry MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"%K == %@ && %K > %@ && %K == false && %K == 0", SVPodcastEntryRelationships.podcast, self, SVPodcastEntryAttributes.datePublished, self.subscribedDate, SVPodcastEntryAttributes.played, SVPodcastEntryAttributes.positionInSeconds] inContext:podcast.managedObjectContext];
            }   
            if (self.unlistenedSinceSubscribedCountValue != newCount) {
                self.unlistenedSinceSubscribedCountValue = newCount;        
            }
        }
        @catch (NSException *exception) {
            DDLogError(@"EXCEPTION: %@", exception);
        }
        @finally {
            
        }
       
}
- (void)downloadImageDataWithURLString:(NSString *)imageURL forKeyPath:(NSString *)keyPath
{
    if ([self valueForKey:keyPath] == nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.managedObjectContext performBlock:^{

                [self setValue:responseObject forKey:keyPath];
                DDLogVerbose(@"Downloaded %@ offline data", keyPath);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"Failed to download %@ offline data", keyPath);
        }];
        [op start];
    }
}

- (void)downloadOfflineImageData
{
    [self downloadImageDataWithURLString:self.smallLogoURL
                              forKeyPath:@"gridSizeImageData"];
    [self downloadImageDataWithURLString:self.thumbLogoURL
                              forKeyPath:@"listSizeImageData"];
    [self downloadImageDataWithURLString:self.logoURL
                              forKeyPath:@"fullIsizeImageData"];
}

- (void)subscribe
{
    self.subscribedDate = [NSDate date];
    self.isSubscribedValue = YES;
    [self downloadOfflineImageData];
}

- (void)unsubscribe
{
    self.subscribedDate = nil;
    self.isSubscribedValue = NO;
    self.shouldNotifyValue = NO;
    [self deleteOfflineImageData];
}

- (void)deleteOfflineImageData
{
    self.gridSizeImageData = nil;
    self.fullIsizeImageData = nil;
    self.listSizeImageData = nil;
}

+ (void)fetchAndSubscribeToPodcastWithId:(NSNumber *)podcastId shouldNotify:(BOOL)shouldNotify
{
    // First, we grab the data
    [[SVPodcatcherClient sharedInstance] fetchPodcastWithId:podcastId
                                               onCompletion:^void(NSArray *podcasts) {
                                                   NSAssert(podcasts.count == 1, @"There should be 1 podcast returned");
                                                   if (podcasts.count > 0) {
                                                       NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
                                                       [context performBlock:^{
                                                           // Then we make a new podcast in the data store
                                                           SVPodcast *localPodcast = [SVPodcast MR_createInContext:context];
                                                           [localPodcast populateWithPodcast:[podcasts objectAtIndex:0]];

                                                           // Now that we have the podcast populated. Subscribe on the
                                                           [[SVPodcatcherClient sharedInstance] subscribeToFeedWithId:podcastId
                                                                                                         onCompletion:^void() {
                                                                                                             [context performBlock:^void() {
                                                                                                                 DDLogInfo(@"Successfully subscribed to podcast %@", localPodcast);
                                                                                                                 [localPodcast subscribe];

                                                                                                                 // Now that we're subscribed, request notifications if necessary
                                                                                                                 if (shouldNotify){
                                                                                                                     [[SVPodcatcherClient sharedInstance] changeNotificationSetting:shouldNotify forFeedWithId:podcastId
                                                                                                                                                                       onCompletion:^{

                                                                                                                                                                       }
                                                                                                                                                                            onError:^(NSError *error) {                                                                                                                                                                                DDLogError(@"Failed to subscribe to notifications. Error: %@", error);                                                                                                                                                                            }];
                                                                                                                 }
                                                                                                             }];


                                                                                                         } onError:^void(NSError *error) {
                                                               DDLogError(@"Failed to subscribe to podcast %@", localPodcast);
                                                           }];
                                                       }];
                                                   }
                                               } onError:^void(NSError *error) {
        DDLogError(@"Failed to fetch podcast with id %@", podcastId);
    }];
}

- (void)getNewEpisodes:(void (^)(BOOL))complete
{
    DDLogWarn(@"Getting new episodes");
    NSAssert(self.title != nil, @"The podcast should have a title by now");
    NSDate *syncDate = [NSDate date];
    [self.managedObjectContext performBlock:^{
        if (self.updatingValue) {
            DDLogVerbose(@"Aborting since we are already updating");
            return;
        }
        
        self.updatingValue = YES;

        //// Force permanent ids to be obtained. This is so that we're not dealing with temp ids later and screwing up relationships
        if([[self objectID] isTemporaryID]) {  
            [[self managedObjectContext] obtainPermanentIDsForObjects:[NSArray arrayWithObject:self] error:nil];
        }
        
        NSNumber *podstoreId = self.podstoreId;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            context.parentContext = self.managedObjectContext;
            
            // Find the last entry that belongs to this podcast, if it exists
            SVPodcastEntry *entry;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"podcast == %@",  self];
            NSFetchRequest *request = [SVPodcastEntry MR_requestAllSortedBy:SVPodcastEntryAttributes.datePublished
                                                                  ascending:NO
                                                              withPredicate:predicate
                                                                  inContext:context];        
            [request setIncludesPendingChanges:YES];
            [request setReturnsObjectsAsFaults:NO];
            [request setFetchLimit:1];
            
            NSArray *fetched = [context executeFetchRequest:request error:nil];

            NSAssert(fetched.count < 2, @"There should be at most 1 item in there");
            entry = [fetched lastObject];
            if(!entry) {
                DDLogWarn(@"Did NOT find previous entry");
            }
            
            DDLogInfo(@"Getting new items %@", isUpdatingFromV1 ? @"updatingfromv1" : @"normally");
            __weak SVPodcast *weakSelf = self;
            NSAssert([self.podstoreId integerValue] != 0, @"The id should not be 0");
            [[SVPodcatcherClient sharedInstance] getNewItemsForFeedWithId:podstoreId
                                                         withLastSyncDate:entry == nil || isUpdatingFromV1 ? [NSDate distantPast] : entry.datePublished
                                                                 complete:^void(id response) {
                                                                     NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                                                                     childContext.parentContext = self.managedObjectContext;
                                                                     [childContext performBlock:^void() {
                                                                         // TODO: simplyify this confusing mess
                                                                         SVPodcast *localPodcast = [self MR_inContext:childContext];
                                                                         localPodcast.lastSynced = syncDate;
                                                                         NSArray *episodes = response;
                                                                         if (episodes) {
                                                                             DDLogInfo( @"Added %d episodes to %@", episodes.count, localPodcast.title);
                                                                         }
                                                                         
                                                                         NSMutableDictionary *upgradeLookupByGUID;
                                                                         if(isUpdatingFromV1) {
                                                                             upgradeLookupByGUID = [NSMutableDictionary dictionary];
                                                                             for(SVPodcastEntry *item in localPodcast.items) {
                                                                                 [upgradeLookupByGUID setObject:item forKey:item.guid];
                                                                             }
                                                                         }
                                                                         
                                                                         for (NSDictionary *episode in episodes) {
                                                                             NSDictionary *data = [episode objectForKey:@"feed_item"];
                                                                             NSString *guid = [data objectForKey:@"guid"];
                                                                             SVPodcastEntry *localEntry;
                                                                             
                                                                             if (isUpdatingFromV1 && [upgradeLookupByGUID objectForKey:guid]!= nil) {
                                                                                 // If we're updating from v1, and this is an existing episode, update the podstoreid
                                                                                 localEntry = [upgradeLookupByGUID objectForKey:guid];
                                                                                 NSNumber *entryId= [data objectForKey:@"id"];
                                                                                 localEntry.podstoreIdValue = [entryId intValue];
                                                                             } else {
                                                                                 // Completely new item, create it,add it, be happy
                                                                                 localEntry = [SVPodcastEntry MR_createInContext:childContext];
                                                                                 
                                                                                 [localEntry populateWithDictionary:episode];                                                                                                                                                          
                                                                                 [localPodcast addItemsObject:localEntry];
                                                                             }
                                                                             
                                                                             
                                                                         }                            
                                                                         
                                                                         [localPodcast updateNewEpisodeCount];
                                                                         
                                                                         NSError *error;
                                                                         [childContext save:&error];
                                                                         
                                                                         NSAssert(error == nil, @"There should be no error. Got %@", error);
                                                                         
                                                                         [weakSelf.managedObjectContext performBlock:^{
                                                                             weakSelf.updatingValue = NO;
                                                                         }];
                                                                         if (error) {
                                                                             DDLogError(@"There was a problem updating this podcast %@ - %@", localPodcast, error);
                                                                             complete(NO); 
                                                                         } else {
                                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                                 complete(YES);                                                                         
                                                                             });
                                                                         }
                                                                         
                                                                         
                                                                     }];
                                                                 } onError:^void(NSError *error) {
                                                                     weakSelf.updatingValue = NO;
                                                                     [[weakSelf managedObjectContext] refreshObject:weakSelf mergeChanges:NO];
                                                                     complete(NO);
                                                                 }];    
            
        });
    }];
    
}

- (void)updateFromV1:(void (^)(BOOL success))complete
{
    isUpdatingFromV1 = YES;
    NSManagedObjectContext *context = self.managedObjectContext;
    [[SVPodcatcherClient sharedInstance] subscribeToFeedWithURL:self.feedURL
                                                   shouldNotify:NO
                                                   onCompletion:^void(id innerResponse) {
                                                       NSDictionary *dict = innerResponse;
                                                       NSDictionary *subDict = [dict objectForKey:@"subscription"];
                                                       NSNumber *feedId = [subDict objectForKey:@"feed_id"];
                                                       [context performBlock:^void() {
                                                           self.podstoreIdValue = [feedId intValue];
                                                           [self getNewEpisodes:^(BOOL succes) {
                                                               complete(YES);
                                                               isUpdatingFromV1 = NO;
                                                           }];
                                                           
                                                       }];                                                                                                              
                                                   } onError:^void(NSError *error) {
                                                       complete(NO);
                                                       isUpdatingFromV1 = NO;
                                                   }];         
}

@end
