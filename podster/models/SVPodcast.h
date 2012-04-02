#import "_SVPodcast.h"
#import "ActsAsPodcast.h"
@class MWFeedInfo;

@interface SVPodcast : _SVPodcast<ActsAsPodcast> {}
-(void)populateWithDictionary:(NSDictionary *)dictionary;
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info;

- (void)updateNextItemDateAndDownloadIfNeccesary:(BOOL)shouldDownload;
- (SVPodcastEntry *)firstUnplayedInPodcastOrder;
@end
