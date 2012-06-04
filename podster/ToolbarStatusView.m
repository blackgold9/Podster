//
//  ToolbarStatusView.m
//  podster
//
//  Created by Vanterpool, Stephen on 6/3/12.
//  Copyright (c) 2012 Amazon. All rights reserved.
//

#import "ToolbarStatusView.h"

@implementation ToolbarStatusView
{
    UIActivityIndicatorView *_spinner;
    UILabel *_titleLabel;
    UILabel *_subTitleLabel;
    BOOL _showing;
    BOOL _animating;
}

- (id)initWithFrame:(CGRect)frame title:(NSString *)title subTitle:(NSString *)subTitle showing:(BOOL)showing animating:(BOOL)animating
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self setAnimating:animating];
        [self setShowing:showing];
    }
    
    return self;
}

-(void)setShowing:(BOOL)showing
{
    if (showing != _showing) {
        _showing = showing;
        [self setNeedsLayout];
    }    
}

- (BOOL)isShowing
{
    return _showing;
}

- (void)setAnimating:(BOOL)animating
{
    if (animating != _animating) {
        _animating = animating;
        [self setNeedsLayout];
    }
}

- (BOOL)isAnimating
{
    return _animating;
}

-(void)layoutSubviews
{
    if (_showing) {
        self.hidden = NO;
        
        CGFloat subTitleHeight = 13.0f;
        _spinner.frame = CGRectMake(0, 0, self.frame.size.height, self.frame.size.height);
        BOOL hasTwoLines = _subTitleLabel.text != nil;
        CGFloat titleHeight = hasTwoLines ? self.frame.size.height - subTitleHeight : self.frame.size.height;
        _titleLabel.frame = CGRectMake(self.frame.size.height + 5, 
                                       0,
                                       self.frame.size.width - self.frame.size.height + 5,
                                       titleHeight);
        if (hasTwoLines) {
            _subTitleLabel.hidden = NO;
            _subTitleLabel.frame = CGRectMake(_titleLabel.frame.origin.x, titleHeight, _titleLabel.frame.size.width, subTitleHeight);
        } else {
            _subTitleLabel.hidden = YES;
        }    
        
    } else {
        self.hidden = YES;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
