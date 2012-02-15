//
//  PodcastGridself.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PodcastGridCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Hex.h"
#import "ActsAsPodcast.h"
@implementation PodcastGridCell

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
        //        view.layer.masksToBounds = NO;
        //        //view.layer.cornerRadius = 8;
        //        view.layer.shadowColor = [UIColor whiteColor].CGColor;
        //        view.layer.shadowOpacity = 0.5;
        //        view.layer.shadowOffset = CGSizeMake(0, 0);
        //        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
        //        view.layer.shadowRadius = 3;
        view.layer.borderColor = [[UIColor colorWithRed:0.48 green:0.48 blue:0.52  alpha:1] CGColor];
        view.layer.borderWidth = 2;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 10,10)];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
        titleLabel.numberOfLines = 0;
        titleLabel.tag = 1907;
        titleLabel.opaque = NO;
        [view addSubview:titleLabel];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        imageView.tag = 1906;
        imageView.backgroundColor = [UIColor clearColor];
        [view addSubview:imageView];
        
        UILabel *newCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 25, 20)];
        newCountLabel.backgroundColor = [UIColor colorWithHex:0x0066a4];
        newCountLabel.hidden = YES;
        newCountLabel.tag = 1908;
        newCountLabel.textColor =[UIColor whiteColor];
        newCountLabel.adjustsFontSizeToFitWidth = YES;
        newCountLabel.minimumFontSize = 13;
        
        newCountLabel.textAlignment = UITextAlignmentLeft;
        newCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
        
        UIImageView *countOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grid-count-overlay.png"]];
        countOverlay.tag = 1909;
        [view addSubview:countOverlay];
        
        [view addSubview:newCountLabel];
        self.contentView = view;
    }
    
    return self;
}

-(void)bind:(id<ActsAsPodcast>)podcast
  fadeImage:(BOOL)fadeImage
{
    UILabel *label = (UILabel *)[self viewWithTag:1907];
    UIImageView *imageView = (UIImageView *)[self.contentView viewWithTag:1906];
    label.text = podcast.title;
    NSString *logoString = podcast.smallLogoURL;
    if (!logoString) {
        logoString = podcast.logoURL;
    }
    if(logoString) {
        NSURL *imageURL = [NSURL URLWithString: logoString];
        [imageView setImageWithURL:imageURL 
                  placeholderImage:nil
                        shouldFade:fadeImage];
    } else {
        // Clear rhe image if there is no logo 
        imageView.image = nil; 
    }
    
    UILabel *countLabel = (UILabel *)[self viewWithTag:1908];
    UIImageView *countOverlay = (UIImageView *)[self viewWithTag:1909];
    if ([[podcast unseenEpsiodeCount] integerValue] > 0) {
        countOverlay.hidden = NO;
        countLabel.hidden = NO;
        countLabel.text = [NSString stringWithFormat:@"%d", [[podcast unseenEpsiodeCount] integerValue]];
    } else {
        countLabel.hidden = YES;
        countOverlay.hidden = YES;
    }

}
@end
