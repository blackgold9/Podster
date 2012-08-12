#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
#import "SVPodcastEntry.h"
#import "NSString+MD5Addition.h"
#import "SVDownloadManager.h"
#import "_SVPodcastEntry.h"
#import "PodcastImage.h"
static const int ddLogLevel = LOG_LEVEL_INFO;

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
    
    
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        SVPodcast *podcast = [self MR_inContext:localContext];
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
        
    }];
}
- (void)downloadImageDataWithURLString:(NSString *)imageURL forKeyPath:(NSString *)keyPath
{
    if ([self valueForKey:keyPath] == nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.managedObjectContext performBlock:^{
                PodcastImage *theImage = [self valueForKey:keyPath];
                if ([self valueForKey:keyPath] == nil) {
                    theImage = [PodcastImage MR_createInContext:self.managedObjectContext];
                    [self setValue:theImage forKey:keyPath];
                }
                theImage.imageData = responseObject;
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
                              forKeyPath:@"gridImage"];
    [self downloadImageDataWithURLString:self.thumbLogoURL
                              forKeyPath:@"listImage"];
    [self downloadImageDataWithURLString:self.logoURL
                              forKeyPath:@"fullImage"];
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
    [self.gridImage MR_deleteInContext:self.managedObjectContext];
    [self.fullImage MR_deleteInContext:self.managedObjectContext];
    [self.listImage MR_deleteInContext:self.managedObjectContext];
}

+ (void)fetchAndSubscribeToPodcastWithId:(NSNumber *)podcastId shouldNotify:(BOOL)shouldNotify
{
    // First, we grab the data
    [[SVPodcatcherClient sharedInstance] fetchPodcastWithId:podcastId
                                               onCompletion:^void(NSArray *podcasts) {

                                                   if (podcasts.count > 0) {
                                                
                                                       NSManagedObjectContext *context = [NSManagedObjectContext MR_rootSavingContext];
                                                       [context performBlock:^{
                                                           // Then we make a new podcast in the data store
                                                           SVPodcast *localPodcast = [SVPodcast MR_createInContext:context];
                                                           [localPodcast populateWithPodcast:[podcasts objectAtIndex:0]];
                                                           [localPodcast subscribe];
                                                           [context MR_save];
                                                           
                                                           // Now that we have the podcast populated. Subscribe on the
                                                           [[SVPodcatcherClient sharedInstance] subscribeToFeedWithId:podcastId
                                                                                                         onCompletion:^void() {
                                                                                                             [context performBlock:^void() {
                                                                                                                 DDLogInfo(@"Successfully subscribed to podcast %@", localPodcast);
                                                                                                               
                                                                                                                 
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
                                                   } else {
                                                       DDLogWarn(@"There was no podcast returned for ID: %@", podcastId);
                                                   }
                                               } onError:^void(NSError *error) {
                                                   DDLogError(@"Failed to fetch podcast with id %@", podcastId);
                                               }];
}

@end
