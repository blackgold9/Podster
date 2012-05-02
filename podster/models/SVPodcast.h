#import "_SVPodcast.h"
#import "ActsAsPodcast.h"
@class MWFeedInfo;

@interface SVPodcast : _SVPodcast<ActsAsPodcast> {}
-(void)populateWithDictionary:(NSDictionary *)dictionary;
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info;

- (void)updateNextItemDateAndDownloadIfNeccesary:(BOOL)shouldDownload;

- (void)getNewEpisodes:(void (^)(BOOL))complete;

- (SVPodcastEntry *)firstUnplayedInPodcastOrder;
- (void)downloadOfflineImageData;
- (void)subscribe;
- (void)unsubscribe;
- (void)updateFromV1:(void (^)(void))complete;
@end
