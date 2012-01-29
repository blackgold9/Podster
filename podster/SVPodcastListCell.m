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
#import "UILabel+VerticalAlign.h"
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
    CGSize maxSize = CGSizeMake(self.titleLabel.frame.size.width, self.contentView.frame.size.height);
    CGSize titleSize = [[podcast title] sizeWithFont:self.titleLabel.font constrainedToSize:maxSize];
    CGRect frame = self.titleLabel.frame;
    self.titleLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, titleSize.height);
    CGFloat bottomOfTitleLabel = CGRectGetMaxY(self.titleLabel.frame);
    if  (self.contentView.frame.size.height - bottomOfTitleLabel >= 20) {
                self.summaryLabel.hidden = NO;
        // Enough space for the summary label
        self.summaryLabel.text = [podcast summary];
        self.summaryLabel.numberOfLines = 3;
        CGSize summarySize = [[podcast summary] sizeWithFont:self.summaryLabel.font constrainedToSize:CGSizeMake(self.summaryLabel.frame.size.width,  self.contentView.frame.size.height - bottomOfTitleLabel - 5)];
        self.summaryLabel.frame = CGRectMake(self.summaryLabel.frame.origin.x, bottomOfTitleLabel + 1, self.summaryLabel.frame.size.width, summarySize.height);
        
        
    } else {
        self.summaryLabel.hidden = YES;
    }
       self.logoImageView.backgroundColor = [UIColor grayColor];
    if ([podcast thumbLogoURL] != nil) {
    NSURL *imageURL = [NSURL URLWithString:[@"http://" stringByAppendingString:[podcast thumbLogoURL]]];
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
