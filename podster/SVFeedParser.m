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
@interface SVFeedParser ()
@property (nonatomic, copy) MKNKErrorBlock errorCallback;
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
}
@synthesize errorCallback, completionCallback;
+ (id)parseData:(NSData *)data
forPodcastAtURL:(NSString *)feedURL
             inContext:(NSManagedObjectContext *)context
            onComplete:(CompletionBlock)complete
               onError:(MKNKErrorBlock)error
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
    parser->feedParser = [[MWFeedParser alloc] initWithFeedData:data textEncodingName:@"NSUnicodeStringEncoding"];
    parser->feedParser.delegate = parser;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [parser->feedParser parse];
    });


    return parser;
}
-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    [localContext performBlockAndWait:^void() {

        localPodcast = [SVPodcast findFirstWithPredicate:        [NSPredicate predicateWithFormat:@"feedURL == %@", feedURL]
                                             inContext:localContext];
        if (!localPodcast) {
            localPodcast = [SVPodcast createInContext:localContext];
        }
        
        [localPodcast updatePodcastWithFeedInfo:info];
    }];
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    if (item.enclosures.count == 0) {
        [parser stopParsing];
        NSError *badFeed = [[NSError alloc] initWithDomain:@"SVParsing" code:100 userInfo:[NSDictionary dictionaryWithObject:@"This podcast feed appears invalid" forKey:NSLocalizedDescriptionKey]];
        failed = YES;
        dispatch_async(originalQueue, ^void() {
            self.errorCallback(badFeed);
        });
        //TODO: Report parsing error with url
        return;
    }
    [localContext performBlock:^void() {
        LOG_PARSING(4, @"Processing feed item %@", item);
        NSString *guid = item.identifier;
        if (!guid) {
            guid = [item.enclosures.lastObject objectForKey:@"url"];
        }
        NSAssert(guid != nil, @"Guid should not be nil at this point");
        NSPredicate *matchesGuid = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastEntryAttributes.guid, guid];
        NSPredicate *inPodcast =[NSPredicate predicateWithFormat:@"%K == %@", SVPodcastEntryRelationships.podcast, localPodcast ];
        SVPodcastEntry *episode = [SVPodcastEntry findFirstWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:matchesGuid,inPodcast,nil]]
                                                               inContext:localContext];
        if (episode) {
            //Items are date ordered, so we don't need to reparse stuff
            LOG_PARSING(2, @"Hit an item we already know about. Aborting.");
            [parser stopParsing];
            return;
        } else {
            LOG_PARSING(2, @"Episode did not exist matching %@. Creaitng one.", item);
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
        episode.durationValue = [item.duration secondsFromDurationString];
        episode.podcast = localPodcast;
        [localContext save];
        if (localContext.parentContext) {
            [localContext.parentContext performBlock:^{
                [localContext.parentContext save];
            }];
        }
    }];
}

-(void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    dispatch_async(originalQueue, ^void() {
        self.errorCallback(error);
    });

    LOG_PARSING(1, @"Parsing feed \"%@\" failed with error: %@", parser.url, error);
}

-(void)feedParserDidStart:(MWFeedParser *)parser
{
    LOG_PARSING(2, @"Started parsing feed");
}

-(void)feedParserDidFinish:(MWFeedParser *)parser
{
    if (!failed) {
        
        [localContext performBlock:^void() {
            LOG_PARSING(2, @"Saving local context");
            [localContext MR_saveWithErrorHandler:^(NSError *error) {
                self.errorCallback(error);
                LOG_PARSING(0, @"Could not save parsed feed data. Core data reported error: %@", error);
            }];
            dispatch_async(originalQueue, ^void() {
                self.completionCallback();
            });
        }];
    }
}

@end
