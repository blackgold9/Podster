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

- (void)awakeFromInsert
{
    LOG_GENERAL(2, @"Initially creating podcast core data object");
    [super awakeFromInsert];
    self.nextItemDate = [NSDate distantPast];
    self.downloadCountValue = 0;
}
- (void)updateNewEpisodeCount
{
    NSUInteger newCount = 0;
    if (self.isSubscribedValue) {
        if (self.subscribedDate == nil) {
            self.subscribedDate = [NSDate date];
        }
        newCount = [SVPodcastEntry MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"%K == %@ && %K > %@ && %K == false", SVPodcastEntryRelationships.podcast, self, SVPodcastEntryAttributes.datePublished, self.subscribedDate, SVPodcastEntryAttributes.played] inContext:self.managedObjectContext];
    }   
    LOG_GENERAL(2, @"New episode count for %@ : %d", self.title, newCount);
    if (self.unlistenedSinceSubscribedCountValue != newCount) {
        self.unlistenedSinceSubscribedCountValue = newCount;        
    }
    
}
- (void)awakeFromFetch
{
    [self updateNewEpisodeCount];
    if (self.isSubscribedValue) {
        SVPodcastEntry *entry = nil;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"played == NO"];
        
        
        if (self.items.count > 0) {
            
            NSArray *sortedItems = [self.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SVPodcastEntryAttributes.datePublished ascending:NO]]];
            sortedItems = [sortedItems filteredArrayUsingPredicate:predicate];
            entry = [sortedItems objectAtIndex:0];
        }
        if(entry) {            
            self.nextItemDate = entry.datePublished;
        } else {
            self.nextItemDate = [NSDate distantPast];
        }
    }
    
}

- (void)downloadOfflineImageData
{
    
    if (self.smallLogoURL != nil) {
        NSURLRequest *gridRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.smallLogoURL]];
        //    AFHTTPRequestOperation *gridOp = AFHTTPRe        
        //        AFHTTPRequestOperation *gridOp = AFH 
        AFHTTPRequestOperation *gridOp = [[AFHTTPRequestOperation alloc] initWithRequest:gridRequest];
        [gridOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.managedObjectContext performBlock:^{
                
                
                self.gridSizeImageData = responseObject; 
                LOG_GENERAL(2, @"Downloaded grid image offline data");
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            LOG_GENERAL(2, @"Failed to download grid image data for offline store");
        }];
        [gridOp start];
    }   
    
    if (self.thumbLogoURL != nil) {
        NSURLRequest *listSizeRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.thumbLogoURL]];
        //    AFHTTPRequestOperation *gridOp = AFHTTPRe        
        //        AFHTTPRequestOperation *gridOp = AFH 
        AFHTTPRequestOperation *listImageOp = [[AFHTTPRequestOperation alloc] initWithRequest:listSizeRequest];
        [listImageOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.managedObjectContext performBlock:^{
                self.listSizeImageData = responseObject; 
                LOG_GENERAL(2, @"Downloaded list image offline data");
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            LOG_GENERAL(2, @"Failed to download list image data for offline store");
        }];
        [listImageOp start];
    }
    
    if (self.logoURL != nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.logoURL]];
        //    AFHTTPRequestOperation *gridOp = AFHTTPRe        
        //        AFHTTPRequestOperation *gridOp = AFH 
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.managedObjectContext performBlock:^{
                self.fullIsizeImageData = responseObject; 
                LOG_GENERAL(2, @"Downloaded list image offline data");
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            LOG_GENERAL(2, @"Failed to download list image data for offline store");
        }];
        [op start];
    }
    
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
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}

- (SVPodcastEntry *)firstUnplayedInPodcastOrder
{
    NSManagedObjectContext *context = self.managedObjectContext;
    __block SVPodcastEntry *entry = nil;
    [context performBlockAndWait:^{
        NSPredicate *isChild = [NSPredicate predicateWithFormat:@"podcast == %@ && played == NO", self];
        entry = [SVPodcast MR_findFirstWithPredicate:isChild 
                                            sortedBy:SVPodcastEntryAttributes.datePublished
                                           ascending:!self.sortNewestFirstValue inContext:[PodsterManagedDocument defaultContext]];
        
    }];
    
    return entry;
}
- (void)updateNextItemDate
{
    
}

+ (void)fetchAndSubscribeToPodcastWithId:(NSNumber *)podcastId
{
        [[SVPodcatcherClient sharedInstance] fetchPodcastWithId:podcastId
                                                   onCompletion:^void(NSArray *podcasts) {

                                                       if (podcasts.count > 0) {
                                                           NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
                                                           [context performBlock:^{
                                                               SVPodcast *localPodcast = [SVPodcast MR_createInContext:context];
                                                               
                                                               
                                                               [localPodcast populateWithPodcast:[podcasts objectAtIndex:0]];
                                                               [[SVPodcatcherClient sharedInstance] subscribeToFeedWithId:podcastId
                                                                                                             onCompletion:^void() {
                                                                                                                 [context performBlock:^void() {
                                                                                                                     DDLogInfo(@"Successfully subscribed to podcast %@", localPodcast);
                                                                                                                     [localPodcast subscribe];
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
- (void)updateNextItemDateAndDownloadIfNeccesary:(BOOL)shouldDownload
{
    DDLogInfo(@"Calculating next item for %@", self.title);
    [self.managedObjectContext performBlock:^{
        
        
        if (self.isSubscribedValue) {
            SVPodcastEntry *entry = nil;
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"played == NO"];
            
            
            if (self.items.count > 0) {
                
                NSArray *sortedItems = [self.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SVPodcastEntryAttributes.datePublished ascending:NO]]];
                sortedItems = [sortedItems filteredArrayUsingPredicate:predicate];

                if (sortedItems.count > 0) {
                    entry = [sortedItems objectAtIndex:0];
                }
            }
            if(entry) {
                DDLogVerbose(@"Had a qualified entry. Date: %@", entry.datePublished);
                self.nextItemDate = entry.datePublished;
                // If item hasn't been listened to
                if (!entry.playedValue && entry.download == nil && !entry.downloadCompleteValue && shouldDownload) {
                    LOG_GENERAL(2, @"Queing entry for download");
                    // If the entry hasn't been played yet and it hasn't been downloaded, queue it for download
                    [[SVDownloadManager sharedInstance] downloadEntry:entry manualDownload:NO];
                }
                [[self managedObjectContext] save:nil];
            } else {
                DDLogVerbose(@"No qualified entry. Setting date to the distant past");
                self.nextItemDate = [NSDate distantPast];
            }
        }
        
        // Cleanup downloads
        NSPredicate *needsDeletingPredicate = [NSPredicate predicateWithFormat:@"played == YES && downloadComplete == YES"];
        NSSet *needDeleting = [self.items filteredSetUsingPredicate:needsDeletingPredicate];
        DDLogInfo(@"Cleaning up. Deleting %d items", needDeleting.count);
        for (SVPodcastEntry *toDelete in needDeleting) {
            [[SVDownloadManager sharedInstance] deleteFileForEntry:toDelete];
            toDelete.downloadCompleteValue = NO;
        }
    }];
}

- (void)getNewEpisodes:(void (^)(BOOL))complete
{
    NSDate *syncDate = [NSDate date];
    [self.managedObjectContext performBlockAndWait:^{
        SVPodcastEntry *entry;
        if (self.items.count > 0) {
            entry = [[self.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"datePublished" ascending:NO]]] objectAtIndex:0];
        }    
        
        DDLogInfo(@"Getting new items %@", isUpdatingFromV1 ? @"updatingfromv1" : @"normally");
        [[SVPodcatcherClient sharedInstance] getNewItemsForFeedWithId:self.podstoreId
                                                     withLastSyncDate:entry == nil || isUpdatingFromV1 ? [NSDate distantPast] : entry.datePublished
                                                             complete:^void(id response) {
                                                                 [self.managedObjectContext performBlock:^void() {
                                                                     self.lastSynced = syncDate;
                                                                     NSArray *episodes = response;
                                                                     if (episodes) {
                                                                         DDLogInfo( @"Added %d episodes to %@", episodes.count, self.title);
                                                                     }
                                                                     NSMutableDictionary *upgradeLookupByGUID;
                                                                     if(isUpdatingFromV1) {
                                                                         upgradeLookupByGUID = [NSMutableDictionary dictionary];
                                                                         for(SVPodcastEntry *item in self.items) {
                                                                             [upgradeLookupByGUID setObject:item forKey:item.guid];
                                                                         }
                                                                     }
                                                                     
                                                                     BOOL isFirst = YES;
                                                                     for (NSDictionary *episode in episodes) {
                                                                         NSDictionary *data = [episode objectForKey:@"feed_item"];
                                                                         NSString *guid = [data objectForKey:@"guid"];
                                                                         SVPodcastEntry *entry;
                                                                         
                                                                         if (isUpdatingFromV1 && [upgradeLookupByGUID objectForKey:guid]!= nil) {
                                                                             // If we're updating from v1, and this is an existing episode, update the podstoreid
                                                                             entry = [upgradeLookupByGUID objectForKey:guid];
                                                                             NSNumber *entryId= [data objectForKey:@"id"];
                                                                             entry.podstoreIdValue = [entryId intValue];
                                                                         } else {
                                                                             // Completely new item, create it,add it, be happy
                                                                             entry = [SVPodcastEntry MR_createInContext:self.managedObjectContext];
                                                                             
                                                                             [entry populateWithDictionary:episode];
                                                                             
                                                                             
                                                                             [self addItemsObject:entry];
                                                                         }
                                                                         
                                                                         if (isFirst) {
                                                                             self.nextItemDate = entry.datePublished;
                                                                             isFirst = NO;
                                                                         }         
                                                                         
                                                                         
                                                                     }                            
                                                                     
                                                                     [self updateNewEpisodeCount];
                                                                     complete(YES);
                                                                 }];
                                                             } onError:^void(NSError *error) {
                                                                 complete(NO);
                                                             }];
        
    }];
}

- (void)updateFromV1:(void (^)(void))complete
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
                                                               complete();
                                                               isUpdatingFromV1 = NO;
                                                           }];
                                                           
                                                       }];
                                                       
                                                       
                                                   } onError:^void(NSError *error) {
                                                       complete();
                                                       isUpdatingFromV1 = NO;
                                                   }];     
    
    
}

@end
