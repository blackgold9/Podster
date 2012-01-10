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
    SVPodcast *localPodcast;
    NSManagedObjectContext *localContext;
    BOOL shouldSaveParentContext;
    MWFeedParser *feedParser;
    dispatch_queue_t originalQueue;
}
@synthesize errorCallback, completionCallback;
+ (id)parseData:(NSData *)data
     forPodcast:(SVPodcast *)podcast
             inContext:(NSManagedObjectContext *)context
            onComplete:(CompletionBlock)complete
               onError:(MKNKErrorBlock)error
{
    NSParameterAssert(podcast);
    NSParameterAssert(context);
    NSParameterAssert(data);
    NSAssert([podcast managedObjectContext]== context, @"Context should match at this point");
    SVFeedParser *parser = [SVFeedParser new];
    parser->originalQueue = dispatch_get_current_queue();
    parser.completionCallback = complete;
    parser.errorCallback = error;
    parser->localContext = context;
parser->localPodcast = podcast;
    parser->feedParser = [[MWFeedParser alloc] initWithFeedData:data textEncodingName:@"NSUnicodeStringEncoding"];
    parser->feedParser.delegate = parser;
    [parser->feedParser parse];

    return parser;
}
-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    [localContext performBlock:^void() {
        [localPodcast updatePodcastWithFeedInfo:info];
    }];
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    if (item.enclosures.count == 0) {
        //TODO: Report parsing error with url
        return;
    }
    [localContext performBlockAndWait:^void() {
        LOG_PARSING(4, @"Processing feed item %@", item);
        NSPredicate *matchesGuid = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastEntryAttributes.guid, item.identifier];
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
        NSParameterAssert(episode.guid);
        episode.imageURL = item.imageURL;
        episode.datePublished = item.date;
        episode.duration = item.duration;
        episode.podcast = localPodcast;
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

@end
