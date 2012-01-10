#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
#import "MWFeedInfo.h"
@implementation SVPodcast
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info
{
    self.title = [[info title] capitalizedString];
    self.summary = info.summary;
    self.logoURL = info.imageURL;
}
// Custom logic goes here.
-(void)populateWithDictionary:(NSDictionary *)dictionary
{

    self.title = [dictionary stringForKey:@"title"];
    self.title = [self.title capitalizedString];
    NSParameterAssert(self.title);
    self.summary = [dictionary stringForKey:@"summary"];
    self.feedURL = [dictionary stringForKey:@"feed_url"];
    NSParameterAssert(self.feedURL);
    self.websiteURL = [dictionary stringForKey:@"website_url"];
    self.logoURL = [dictionary stringForKey:@"image_url"];        

}
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}

@end
