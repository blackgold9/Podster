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

- (void)populateWithDictionary:(NSDictionary *)dict
{
    NSDictionary *data = [dict objectForKey:@"feed_item"];
    self.title =  [data objectForKey:@"title"];
    self.summary = [data objectForKey:@"plain_summary"];
    self.rawSummary = [data objectForKey:@"raw_summary"];
    self.isVideoValue = [(NSNumber *)[data objectForKey:@"is_video"] boolValue];
    self.mediaURL = [data objectForKey:@"content_url"];
    self.webURL = [data objectForKey:@"link"];
    if ([data objectForKey:@"duration"] != [NSNull null]) {
        self.durationValue =[[data objectForKey:@"duration"] secondsFromDurationString];
    }

    self.datePublished = [[data objectForKey:@"published_date"] dateFromRailsDate];
    self.guid = [data objectForKey:@"guid"];
}


- (NSString *)downloadFilePathForBasePath:(NSString *)basePath
{
    NSAssert(basePath != nil, @"Must have base path");
    NSString *filePath = [basePath stringByAppendingPathComponent:[self identifier]];
    return [filePath stringByAppendingPathExtension:[self.mediaURL pathExtension]];
}
@end
