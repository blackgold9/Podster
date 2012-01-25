//
//  SVPodcastListCell.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastListCell.h"
#import "ActsAsPodcast.h"
#import "SVPodcatcherClient.h"
#import "SVPodcast.h"
#import <QuartzCore/QuartzCore.h>
@implementation SVPodcastListCell
{
    MKNetworkOperation *op;
}
@synthesize titleLabel = _titleLabel;
@synthesize summaryLabel = _summaryLabel;
@synthesize logoImageView = _logoImageView;
+ (NSString *)cellIdentifier {
    return NSStringFromClass([self class]);
   }

-(void)prepareForReuse
{
    if (op) {
        [op cancel];
        op = nil;
        LOG_NETWORK(3, @"Cancelled network operation");;

    }
    self.logoImageView.image = nil;
    [super prepareForReuse];
}

+ (id)cellForTableView:(UITableView *)tableView fromNib:(UINib *)nib {
    NSString *cellID = [self cellIdentifier];
    UITableViewCell *cell = [tableView 
                             dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        NSArray *nibObjects = [nib instantiateWithOwner:nil options:nil];
		
        NSAssert2(([nibObjects count] > 0) && 
                  [[nibObjects objectAtIndex:0] isKindOfClass:[self class]],
                  @"Nib '%@' does not appear to contain a valid %@", 
                  [self nibName], NSStringFromClass([self class]));
        
        cell = [nibObjects objectAtIndex:0];
    }
    return cell;    
}

#pragma mark -
#pragma mark Nib support

+ (UINib *)nib {
    NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
    return [UINib nibWithNibName:[self nibName] bundle:classBundle];
}

+ (NSString *)nibName {
    return [self cellIdentifier];
}

-(void)bind:(id<ActsAsPodcast>)podcast
{
    
    self.titleLabel.text = [podcast title];
    self.summaryLabel.text = [podcast summary];
    self.logoImageView.backgroundColor = [UIColor grayColor];
    if ([podcast logoURL] != nil) {
    NSURL *imageURL = [NSURL URLWithString:[podcast thumbLogoURL]];
    op = [[SVPodcatcherClient sharedInstance] imageAtURL:imageURL
                                       onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                                           if ([[url absoluteString] isEqualToString:[imageURL absoluteString]]) {
                                               if(!isInCache) {
                                                   LOG_NETWORK(3, @"Image was not cached");
                                                   CATransition *transition = [CATransition animation];
                                                   
                                                   
                                                   [self.logoImageView.layer addAnimation:transition forKey:nil];
                                               } else {
                                                   LOG_NETWORK(3, @"Image was cached");                                                   
                                               }

                                               self.logoImageView.image = fetchedImage;
                                               if (!fetchedImage) {
                                                   LOG_NETWORK(1, @"Error loading image for url: %@", url);
                                               }
                                           }
                                       }];
    }

}
@end
