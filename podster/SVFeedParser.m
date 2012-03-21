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
@interface SVFeedParser ()
@property (nonatomic, copy) SVErrorBlock errorCallback;
@property (nonatomic, copy) CompletionBlock completionCallback;
@end
@implementation SVFeedParser {
    BOOL failed;
    SVPodcast *localPodcast;
    NSManagedObjectContext *localContext;
    BOOL shouldSaveParentContext;
    MWFeedParser *feedParser;
    NSString *feedURL;
    dispatch_queue_t originalQueue;
    BOOL isFirstItem;
    NSInteger itemsParsed;
    NSString *etag;
    NSString *cachingLastModified;
}
@synthesize errorCallback, completionCallback;

+ (id)parseData:(NSData *)data
       withETag:(NSString *)etag
andLastModified:(NSString *)cachingLastModified
forPodcastAtURL:(NSString *)feedURL
             inContext:(NSManagedObjectContext *)context
            onComplete:(CompletionBlock)complete
               onError:(SVErrorBlock)error
{
    NSParameterAssert(feedURL);
    NSParameterAssert(context);
    NSParameterAssert(data);

    SVFeedParser *parser = [SVFeedParser new];
    parser->originalQueue = dispatch_get_current_queue();
    parser.completionCallback = complete;
    parser.errorCallback = error;
    parser->localContext = context;
    parser->feedURL = feedURL;
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

    NSAssert(localContext != [PodsterManagedDocument defaultContext], @"We should not be using the main context here");
    [localContext performBlock:^void() {

        localPodcast = [SVPodcast MR_findFirstWithPredicate:        [NSPredicate predicateWithFormat:@"feedURL == %@", feedURL]
                                             inContext:localContext];
        if (!localPodcast) {

            localPodcast = [SVPodcast MR_createInContext:localContext];
            localPodcast.feedURL = feedURL; 
            localPodcast.urlHash = [localPodcast.feedURL stringFromMD5];
        } 
        
        NSAssert(localPodcast.feedURL != nil, @"There should be a feedURL");        
        [localPodcast updatePodcastWithFeedInfo:info];
        if (!localPodcast.etag || ![localPodcast.etag isEqualToString:etag]) {
            localPodcast.etag = etag;
        }
        
        if (!localPodcast || ![localPodcast.urlHash isEqualToString:[localPodcast.feedURL stringFromMD5]]) {
            localPodcast.urlHash = [localPodcast.feedURL stringFromMD5];
        }

    }];
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    if (item.enclosures.count == 0) {
        [FlurryAnalytics logEvent:@"ParsedItemHadNoEnclosure" withParameters:[NSDictionary dictionaryWithObject:feedURL
                                                                                                         forKey:@"URL"]];
        return;
    }
      
    [localContext performBlockAndWait:^void() {
        LOG_PARSING(4, @"Processing feed item %@", item);
        NSString *guid = item.identifier;
        if (!guid) {
            guid = [item.enclosures.lastObject objectForKey:@"url"];
        }
        NSAssert(guid != nil, @"Guid should not be nil at this point");
        NSPredicate *matchesGuid = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastEntryAttributes.guid, guid];
        NSPredicate *inPodcast =[NSPredicate predicateWithFormat:@"%K == %@", SVPodcastEntryRelationships.podcast, localPodcast ];
        SVPodcastEntry *episode = [SVPodcastEntry MR_findFirstWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:matchesGuid,inPodcast,nil]]
                                                               inContext:localContext];
        BOOL abort = NO;
        if (episode) {
            //Items are date ordered, so we don't need to reparse stuff
            // We will always reparse the latest thing in case there is a correction
            LOG_PARSING(2, @"Hit an item we already know about. Aborting after processing it.");
            abort = YES;
        } else {
            LOG_PARSING(2, @"Episode did not exist matching %@. Creaitng one.", item);
            
            // Only update lastUpdated if it's a new episode
            if (isFirstItem) {
                localPodcast.lastUpdated = item.date;
                localPodcast.nextItemDate = item.date;
                
            }
            episode = [SVPodcastEntry MR_createInContext:localContext];
        }
        
        NSParameterAssert(episode);
        episode.title = item.title;
        NSParameterAssert(episode.title);
        episode.summary = item.summary;
        episode.mediaURL = [item.enclosures.lastObject objectForKey:@"url"];
        NSParameterAssert(episode.mediaURL);
        episode.guid = item.identifier;
        if(!item.identifier) {
            episode.guid = episode.mediaURL;
        }
        NSParameterAssert(episode.guid);
        episode.imageURL = item.imageURL;
        episode.datePublished = item.date;
        episode.content = item.content;
        episode.durationValue = [item.duration secondsFromDurationString];
        episode.podcast = localPodcast;

        if (!abort) {
            // Only update unseen count if we aren't already aborting
            // if we ARE aborting, it means we already knew about this, we're just updating to be safe
            localPodcast.unseenEpsiodeCountValue ++;
        }
        
        itemsParsed += 1;
        if (itemsParsed % 20 == 0){
                [localContext save:nil];
        } else {
            LOG_PARSING(4, @"Skipping parent save");
        }
        
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
               withParameters:[NSDictionary dictionaryWithObject:feedURL forKey:@"URL"]];
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
