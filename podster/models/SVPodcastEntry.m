#define kDownloadsDirectory @"PodcatcherDownloads"
#import "SVPodcastEntry.h"
#import "SVPodcast.h"
#import "NSString+MW_HTML.h"
#import "SVDownloadManager.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
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
    id theGuid = [data objectForKey:@"guid"];
    if (theGuid != [NSNull null]) {
        self.guid = theGuid;
    }
    
    self.podstoreId = [data objectForKey:@"id"];
}

-(NSString *)downloadsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:kDownloadsDirectory];
    
}

- (NSString *)localFilePath
{
    NSString *basePath = [self downloadsPath];
    
    NSString *filePath = [basePath stringByAppendingPathComponent:[[self podstoreId] stringValue]];
    return [filePath stringByAppendingPathExtension:[[[[self mediaURL] pathExtension] componentsSeparatedByString:@"?"] objectAtIndex:0]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@:%@", self.podcast.title, self.title, self.podstoreId];
}


@end
