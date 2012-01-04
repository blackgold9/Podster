#import "SVPodcast.h"

@implementation SVPodcast

// Custom logic goes here.
-(void)populateWithGPodderDictionary:(NSDictionary *)dictionary
{

    self.title = [dictionary valueForKey:@"title"];
    self.title = [self.title capitalizedString];
    
    self.summary = [dictionary valueForKey:@"description"];
    self.feedURL = [dictionary valueForKey:@"url"];
    self.websiteURL = [dictionary valueForKey:@"website"];
    if ([dictionary objectForKey:@"logo_url"] != [NSNull null]) {
        self.logoURL = [dictionary valueForKey:@"logo_url"];        
    }

}
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}

@end
