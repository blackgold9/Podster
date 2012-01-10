#import "_SVPodcast.h"

@class MWFeedInfo;

@interface SVPodcast : _SVPodcast {}
-(void)populateWithDictionary:(NSDictionary *)dictionary;
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info;
@end
