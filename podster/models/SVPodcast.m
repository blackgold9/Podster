#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
#import "MWFeedInfo.h"
@implementation SVPodcast
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info
{
    self.title = [[info title] capitalizedString];
    self.summary = info.summary;
    if (info.imageURL) {
        self.logoURL = info.imageURL;
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
    NSParameterAssert(self.feedURL);
    self.websiteURL = [dictionary stringForKey:@"website_url"];
    if ([[dictionary objectForKey:@"image"] objectForKey:@"url"] != [NSNull null]) {
        self.logoURL = [[dictionary objectForKey:@"image"] objectForKey:@"url"];
        self.smallLogoURL = [[[dictionary objectForKey:@"image"] objectForKey:@"small"] objectForKey:@"url"];
        self.tinyLogoURL =  [[[dictionary objectForKey:@"image"] objectForKey:@"tiny"] objectForKey:@"url"];
        self.thumbLogoURL =  [[[dictionary objectForKey:@"image"] objectForKey:@"thumb"] objectForKey:@"url"];
    }
}
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}

@end
