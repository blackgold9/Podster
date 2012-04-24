#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
#import "MWFeedInfo.h"
#import "SVPodcastEntry.h"
#import "NSString+MD5Addition.h"
#import "SVDownloadManager.h"
#import "_SVPodcastEntry.h"
@implementation SVPodcast
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info
{
    NSString *captializedTitle = [[info title] capitalizedString];
    if (!self.title || ![self.title isEqualToString:captializedTitle]) {
        self.title = captializedTitle;
    }
    
    if (!self.summary || ![self.summary isEqualToString:info.summary]) {
        self.summary = info.summary;
    }
    if (info.imageURL != nil && self.logoURL == nil) {
        self.logoURL = info.imageURL;
    }

    if (!self.author || ![self.author isEqualToString:info.author]) {
        self.author = info.author; 
    }
    
    if (!self.websiteURL || [self.websiteURL isEqualToString:info.link]) {
        self.websiteURL = info.link;
    }
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

}

- (void)deleteOfflineImageData
{
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



- (void)updateNextItemDateAndDownloadIfNeccesary:(BOOL)shouldDownload
{

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
            // If item hasn't been listened to
            if (!entry.playedValue && entry.download == nil && !entry.downloadCompleteValue && shouldDownload) {
                LOG_GENERAL(2, @"Queing entry for download");
                // If the entry hasn't been played yet and it hasn't been downloaded, queue it for download
                [[SVDownloadManager sharedInstance] downloadEntry:entry manualDownload:NO];
            }
            [[self managedObjectContext] save:nil];
        } else {
            self.nextItemDate = [NSDate distantPast];
        }
    }

    // Cleanup downloads
    NSPredicate *needsDeletingPredicate = [NSPredicate predicateWithFormat:@"played == YES && downloadComplete == YES"];
    NSSet *needDeleting = [self.items filteredSetUsingPredicate:needsDeletingPredicate];
    LOG_DOWNLOADS(2, @"Deleting %d items", needDeleting.count);
    for (SVPodcastEntry *toDelete in needDeleting) {
        [[SVDownloadManager sharedInstance] deleteFileForEntry:toDelete];
        toDelete.downloadCompleteValue = NO;
    }


}

- (void)getNewEpisodes:(void (^)(BOOL))complete
{
    NSDate *syncDate = [NSDate date];
    [[SVPodcatcherClient sharedInstance] getNewItemsForFeedWithId:self.podstoreId
                                                 withLastSyncDate:self.lastSynced == nil ? [NSDate distantPast] : self.lastSynced
                                                         complete:^void(id response) {
                                                                [self.managedObjectContext performBlock:^void() {
                                                                    self.lastSynced = syncDate;
                                                                    NSArray *episodes = response;
                                                                    BOOL isFirst = YES;
                                                                    for (NSDictionary *episode in episodes) {
                                                                        SVPodcastEntry *newEntry = [SVPodcastEntry MR_createInContext:self.managedObjectContext];

                                                                        [newEntry populateWithDictionary:episode];
                                                                        if (isFirst) {
                                                                            self.nextItemDate = newEntry.datePublished;
                                                                            isFirst = NO;
                                                                        }
                                                                        
                                                                        [self addItemsObject:newEntry];
                                                                    }

                                                                    complete(YES);
                                                                }];
                                                         } onError:^void(NSError *error) {
        complete(NO);
        // handle it;
    }];
}
- (NSUInteger)downloadedEpisodes
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = YES && %K= %@",SVPodcastEntryAttributes.downloadComplete, SVPodcastEntryRelationships.podcast, self];
    NSUInteger count = [SVPodcastEntry MR_countOfEntitiesWithPredicate:predicate inContext:self.managedObjectContext];
    LOG_GENERAL(2, @"Podcast has %d downloaded episodes", count);
    return count;
}


@end
