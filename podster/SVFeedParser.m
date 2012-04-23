//
//  SVFeedParser.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVFeedParser.h"
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
#import "NSString+MD5Addition.h"
#import "_SVPodcast.h"
#import "SVPodcastModalView.h"
@interface SVFeedParser ()
@property (nonatomic, copy) SVErrorBlock errorCallback;
@property (nonatomic, copy) CompletionBlock completionCallback;
@end
@implementation SVFeedParser {
    BOOL failed;
    SVPodcast *podcast;
    NSManagedObjectContext *localContext;
    MWFeedParser *feedParser;
    dispatch_queue_t originalQueue;
    BOOL isFirstItem;
    NSInteger itemsParsed;
    NSString *etag;
    NSString *cachingLastModified;
}
@synthesize errorCallback, completionCallback;

+ (id)parseData:(NSData *)data withETag:(NSString *)etag andLastModified:(NSString *)cachingLastModified forPodcast:(SVPodcast *)podcast onComplete:(CompletionBlock)complete onError:(SVErrorBlock)error
{
    NSParameterAssert(podcast);
    NSParameterAssert(data);

    SVFeedParser *parser = [SVFeedParser new];
    parser->originalQueue = dispatch_get_current_queue();
    parser.completionCallback = complete;
    parser.errorCallback = error;
    parser->localContext = podcast.managedObjectContext;
    parser->podcast = podcast;
    parser->failed = NO;
    parser->itemsParsed = 0;
    parser->etag = etag;
    parser->cachingLastModified = cachingLastModified;
    parser->feedParser = [[MWFeedParser alloc] initWithFeedData:data textEncodingName:@"NSUnicodeStringEncoding"];
    parser->feedParser.delegate = parser;
    parser->isFirstItem = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [parser->feedParser parse];
    });


    return parser;
}
-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    [localContext performBlockAndWait:^void() {
        [podcast updatePodcastWithFeedInfo:info];
        LOG_GENERAL(2, @"Podcasst currently has %d entries on disk", podcast.items.count);
        if (!podcast.etag || ![podcast.etag isEqualToString:etag]) {
            podcast.etag = etag;
        }
        
        if (!podcast || ![podcast.urlHash isEqualToString:[podcast.feedURL stringFromMD5]]) {
            podcast.urlHash = [podcast.feedURL stringFromMD5];
        }

    }];
}

- (NSString *)guidForFeedItem:(MWFeedItem *)item{
    NSString *guid;
    if (item.identifier) {
        guid = item.identifier;
        LOG_PARSING(2, @"item had guid");
    } else {
        LOG_PARSING(1, @"Item had no guid, using mediaurl");
        if (item.enclosures.count > 0) {
                guid = [item.enclosures.lastObject objectForKey:@"url"];
        } else {
            NSAssert(false, @"Should never have item with no identifier");
        }
    }


    return guid;
}
-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{

      
    [localContext performBlockAndWait:^void() {
        if (item.enclosures.count == 0) {
            [FlurryAnalytics logEvent:@"ParsedItemHadNoEnclosure" withParameters:[NSDictionary dictionaryWithObject:podcast.feedURL
                                                                                                             forKey:@"URL"]];
            return;
        }
        LOG_PARSING(4, @"Processing feed item %@", item);
        NSString *guid = [self guidForFeedItem:item];
        NSAssert(guid != nil, @"Guid should not be nil at this point");

        SVPodcastEntry *episode;
        for (SVPodcastEntry *current in podcast.items) {
            if ([current.guid isEqualToString:guid]) {
                episode = current;
                break;
            }
        }

        BOOL abort = NO;
        if (episode) {
            //Items are date ordered, so we don't need to reparse stuff
            // We will always reparse the latest thing in case there is a correction
            LOG_PARSING(2, @"Hit an item we already know about. Aborting after processing it.");
            abort = YES;
        } else {
            LOG_PARSING(2, @"Episode did not exist matching %@ - %@ in context %@. Creaitng one.", item.title, item.identifier, localContext);
            
            // Only update lastUpdated if it's a new episode
            if (isFirstItem && item.date) {
                podcast.lastUpdated = item.date;
                LOG_PARSING(2, @"Updating next item date");
                podcast.nextItemDate = item.date;                                                
            }
            episode = [SVPodcastEntry MR_createInContext:localContext];
            [podcast addItemsObject:episode];
        }
        
        NSParameterAssert(episode);
        episode.title = item.title;
        NSParameterAssert(episode.title);
        episode.summary = item.summary;
        episode.mediaURL = [item.enclosures.lastObject objectForKey:@"url"];
        NSParameterAssert(episode.mediaURL);
        episode.guid = guid;

        NSParameterAssert(episode.guid);
        episode.imageURL = item.imageURL;
        episode.datePublished = item.date;
        //ssepisode.content = item.content;
        episode.durationValue = [item.duration secondsFromDurationString];



        if (!abort) {
            // Only update unseen count if we aren't already aborting
            // if we ARE aborting, it means we already knew about this, we're just updating to be safe
            podcast.unseenEpsiodeCountValue ++;
        }
        
        itemsParsed += 1;
//        if (itemsParsed % 20 == 0){
//                [localContext save:nil];
//        } else {
//            LOG_PARSING(4, @"Skipping parent save");
//        }
        
        // Don't parse more than 100 items
        if (itemsParsed >= 100) {
            LOG_GENERAL(2, @"Hit the 100 item limit, stopping parsing");
            [parser stopParsing];
        }
        
        if (abort) {
            [parser stopParsing];
            return;
        }
    }];
    
    isFirstItem = NO;
}

-(void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    dispatch_async(originalQueue, ^void() {
        self.errorCallback(error);
    });
    
    [FlurryAnalytics logEvent:@"ParsingFailed"
               withParameters:[NSDictionary dictionaryWithObject:podcast.feedURL forKey:@"URL"]];
    LOG_PARSING(1, @"Parsing feed \"%@\" failed with error: %@", parser.url, error);
}

-(void)feedParserDidStart:(MWFeedParser *)parser
{
    LOG_PARSING(2, @"Started parsing feed");
}

-(void)feedParserDidFinish:(MWFeedParser *)parser
{
    LOG_PARSING(2, @"Done parsing");
    if (!failed) {
        
        [localContext performBlock:^void() {
            LOG_PARSING(2, @"Saving local context");
            NSError *error = nil;
            [localContext save:&error];
            if (error) {
                
                dispatch_async(originalQueue, ^void() {
                    self.errorCallback(error);
                });
                LOG_PARSING(0, @"Could not save parsed feed data. Core data reported error: %@", error);
            }
            
            dispatch_async(originalQueue, ^void() {
                self.completionCallback();
            });        
        }];
    }
}

@end
