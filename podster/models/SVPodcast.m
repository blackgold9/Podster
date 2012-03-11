#import "SVPodcast.h"
#import "NSDictionary+safeGetters.h"
#import "MWFeedInfo.h"
#import "SVPodcastEntry.h"
#import "NSString+MD5Addition.h"
@implementation SVPodcast
-(void)updatePodcastWithFeedInfo:(MWFeedInfo *)info
{
    NSString *captializedTitle = [[info title] capitalizedString];
    if (!self.title || ![self.title isEqualToString:captializedTitle]) {
        self.title = captializedTitle;
    }
    
    if (!self.summary || ![self.summary isEqualToString:info.summary]) {
        self.summary = info.summary;
    }
    if (info.imageURL != nil && self.logoURL == nil) {
        self.logoURL = info.imageURL;
    }

    if (!self.author || ![self.author isEqualToString:info.author]) {
        self.author = info.author; 
    }
    
    if (!self.websiteURL || [self.websiteURL isEqualToString:info.link]) {
        self.websiteURL = info.link;
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
    self.subtitle = [dictionary stringForKey:@"subtitle"];
    self.websiteURL = [dictionary stringForKey:@"website_url"];

    self.logoURL = [dictionary stringForKey:@"logo"];
    
    self.smallLogoURL = [dictionary stringForKey:@"logo_small"];
    self.tinyLogoURL = [dictionary stringForKey:@"logo_tiny"];
    self.thumbLogoURL = [dictionary stringForKey:@"logo_thumb"];    
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}

- (SVPodcastEntry *)firstUnplayed
{
    NSManagedObjectContext *context = self.managedObjectContext;
    __block SVPodcastEntry *entry = nil;
    [context performBlockAndWait:^{
        NSPredicate *isChild = [NSPredicate predicateWithFormat:@"podcast == %@", self];
        entry = [SVPodcast findFirstWithPredicate:isChild 
                                 sortedBy:SVPodcastEntryAttributes.datePublished
                                ascending:!self.sortNewestFirstValue];
        
    }];
    
    return entry;
}

@end
