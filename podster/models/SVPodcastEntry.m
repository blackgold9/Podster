#import "SVPodcastEntry.h"
#import "SVPodcast.h"
#import "NSString+MD5Addition.h"
#import "NSString+MW_HTML.h"
@implementation SVPodcastEntry

- (void)populateWithDictionary:(NSDictionary *)dict
{
    NSDictionary *data = [dict objectForKey:@"feed_item"];
    self.title =  [data objectForKey:@"title"];
    if ([data objectForKey:@"plain_summary"] != [NSNull null]) {
        self.summary = [data objectForKey:@"plain_summary"];
    }
    if ([data objectForKey:@"raw_summary"] != [NSNull null]) {
        self.rawSummary = [data objectForKey:@"raw_summary"];
    }
    
    if (self.summary == nil && self.rawSummary!= nil) {
        self.summary = [self.rawSummary stringByConvertingHTMLToPlainText];
    }
    self.isVideoValue = [(NSNumber *)[data objectForKey:@"is_video"] boolValue];
    self.mediaURL = [data objectForKey:@"content_url"];
    if ([data objectForKey:@"link"] != [NSNull null]) {
        self.webURL = [data objectForKey:@"link"];
    }
    if ([data objectForKey:@"duration"] != [NSNull null]) {
        self.durationValue =[[data objectForKey:@"duration"] secondsFromDurationString];
    }
    
    self.datePublished = [[data objectForKey:@"published_date"] dateFromRailsDate];
    self.guid = [data objectForKey:@"guid"];
    self.podstoreId = [data objectForKey:@"id"];
}


- (NSString *)downloadFilePathForBasePath:(NSString *)basePath
{
    NSAssert(basePath != nil, @"Must have base path");
    NSString *filePath = [basePath stringByAppendingPathComponent:[[self podstoreId] stringValue]];
    return [filePath stringByAppendingPathExtension:[self.mediaURL pathExtension]];
}
@end
