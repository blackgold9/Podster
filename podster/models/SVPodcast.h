#import "_SVPodcast.h"
#import "ActsAsPodcast.h"
@class MWFeedInfo;

@interface SVPodcast : _SVPodcast<ActsAsPodcast> {}
-(void)populateWithDictionary:(NSDictionary *)dictionary;

- (void)populateWithPodcast:(id <ActsAsPodcast>)podcast;

- (void)getNewEpisodes:(void (^)(BOOL))complete;

// Used when installing the app fresh and restoring old subscriptions
+ (void)fetchAndSubscribeToPodcastWithId:(NSNumber *)podcastId shouldNotify:(BOOL)shouldNotify;

// Downloads the various images neccesary for displaying the podcast
- (void)downloadOfflineImageData;
- (void)subscribe;
- (void)unsubscribe;

@end
