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
    textView.frame = self.contentView.frame; //CGRectInset(self.contentView.frame, 10, 10);
    textView.text = [podcast summary];    
}

@end
