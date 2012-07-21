//
// Created by svanter on 7/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NativeWebView.h"


@implementation NativeWebView {

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    }

    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];

    if (self)
    {
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    for (UIView *subview in self.scrollView.subviews)
    {
        if ([subview isKindOfClass:[UIImageView class]])
        {
            subview.hidden = YES;
        }
    }
}

@end