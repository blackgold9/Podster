#import "SVPodcastEntry.h"
#import "SVPodcast.h"
@implementation SVPodcastEntry

// Custom logic goes here.
-(NSString *)identifier
{
    NSParameterAssert(self.guid);
    return [[self.podcast.feedURL stringByAppendingFormat:@":%@", self.guid] md5];
}
@end
