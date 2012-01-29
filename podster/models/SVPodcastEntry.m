#import "SVPodcastEntry.h"
#import "SVPodcast.h"
#import "NSString+MD5Addition.h"
@implementation SVPodcastEntry

// Custom logic goes here.
-(NSString *)identifier
{
    NSParameterAssert(self.guid);
    return [[self.podcast.feedURL stringByAppendingFormat:@":%@", self.guid] stringFromMD5];
}
@end
