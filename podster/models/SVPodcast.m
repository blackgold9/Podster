#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
@implementation SVPodcast

// Custom logic goes here.
-(void)populateWithGPodderDictionary:(NSDictionary *)dictionary
{

    self.title = [dictionary stringForKey:@"title"];
    self.title = [self.title capitalizedString];
    NSParameterAssert(self.title);
    self.summary = [dictionary stringForKey:@"description"];
    self.feedURL = [dictionary stringForKey:@"url"];
    NSParameterAssert(self.feedURL);
    self.websiteURL = [dictionary stringForKey:@"website"];
    self.logoURL = [dictionary stringForKey:@"logo_url"];        

}
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}

@end
