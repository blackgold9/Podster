//
//  SVPodcastModalView.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastModalView.h"


#import "ActsAsPodcast.h"
#import "NSAttributedString+HTML.h"
@implementation SVPodcastModalView {
    UIView *backgroundView;
    UILabel *titleLabel;
    //DTAttributedTextView *textView;
    UITextView *textView;

}
@synthesize podcast;
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//        [self addSubview:backgroundView];
//        titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//        titleLabel.textAlignment = UITextAlignmentCenter;
//        [self addSubview:titleLabel];
        
        titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
       // textView = [[DTAttributedTextView alloc] initWithFrame:CGRectZero];
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        textView.backgroundColor = [UIColor clearColor];
        textView.textColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:15];
        textView.indicatorStyle = UIScrollViewIndicatorStyleWhite;

        [self addSubview:textView];
    }
    
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
   // UIFont *titleFont = titleLabel.font;
 //   CGFloat centerX = self.contentView.center.x;
    //CGRect insetRect = CGRectInset(contentView.frame, 10, 10);
  //  CGSize textSize = [[self.podcast title] sizeWithFont:titleFont constrainedToSize:CGSizeMake(insetRect.size.width, 100)];
//    titleLabel.frame = CGRectMake(insetRect.origin.x, insetRect.origin.y, textSize.width, textSize.height);
//    titleLabel.text = [podcast title];
//    titleLabel.center = CGPointMake(centerX, titleLabel.center.y);
//
   // CGFloat bottomOfLabel = CGRectGetMaxY(titleLabel.frame);
    
    textView.frame = self.contentView.frame; //CGRectInset(self.contentView.frame, 10, 10);
    //CGRectIntegral( CGRectMake(titleLabel.frame.origin.x, bottomOfLabel + 20, insetRect.size.width, contentView.frame.size.height - 10 - bottomOfLabel));
//    textView.attributedString = [[NSAttributedString alloc] initWithString:[podcast summary]];
    textView.text = [podcast summary];

    
}


@end
