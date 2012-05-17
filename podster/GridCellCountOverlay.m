//
//  GridCellCountOverlay.m
//  podster
//
//  Created by Vanterpool, Stephen on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GridCellCountOverlay.h"

@implementation GridCellCountOverlay
{
    UIImageView *flagImageView;
    UILabel *countLabel;
    UIEdgeInsets margins;
    NSUInteger count;
    
}
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        margins = UIEdgeInsetsMake(5, 5, 5, 5);
        flagImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flag2.png"]]; 
        flagImageView.frame = CGRectMake(margins.left, margins.top, 20, 20);
        flagImageView.clipsToBounds = YES;
        flagImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;        
        [self addSubview:flagImageView];
        
        countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(flagImageView.frame) + 5, 
                                                               0,
                                                               self.frame.size.width - CGRectGetMaxX(flagImageView.frame) + 5 , 
                                                               self.frame.size.height)];
        countLabel.font = [UIFont systemFontOfSize:17];
        countLabel.backgroundColor = [UIColor clearColor];
        countLabel.textColor = [UIColor whiteColor];
        countLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:countLabel];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        margins = UIEdgeInsetsMake(5, 5, 5, 5);
        flagImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flag2.png"]]; 
        flagImageView.frame = CGRectMake(margins.left, margins.top, 20, 20);
        flagImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;        
        [self addSubview:flagImageView];
        
        countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(flagImageView.frame) + 5, 0, 20, self.frame.size.height)];
        countLabel.font = [UIFont systemFontOfSize:19];
        countLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:countLabel];
        
    }
    
    return self;
}


- (void)setCount:(NSUInteger)theCount
{
    count = theCount;
    countLabel.text = [NSString stringWithFormat:@"%d", count];
    LOG_GENERAL(3, @"%@ - %@", NSStringFromCGRect(countLabel.frame), countLabel.text);
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize textSize = [countLabel.text sizeWithFont:countLabel.font
                                  constrainedToSize:CGSizeMake(100, 20) 
                                      lineBreakMode:UILineBreakModeWordWrap];
    CGSize calculatedSize =  CGSizeMake(CGRectGetMaxX(flagImageView.frame) + 5 + textSize.width + margins.right, size.height);
    LOG_GENERAL(2, @"Overlay calculated size: %@", NSStringFromCGSize(calculatedSize));
    return calculatedSize;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                               byRoundingCorners:UIRectCornerBottomLeft
                                                     cornerRadii:CGSizeMake(10, 10)];    
    [path setLineWidth:1.0];
    [[UIColor colorWithWhite:0.0 alpha:0.8] setFill];
    [[UIColor colorWithWhite:0.7 alpha:0.8] setStroke];
    
    [path fill];
    [path stroke];
}

@end
