//
// Created by blackgold9 on 6/13/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SVInsetLabel.h"


@implementation SVInsetLabel {

}

@synthesize insets;

- (void)drawTextInRect:(CGRect)rect
{
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.insets)];
}

- (void)resizeHeightToFitText
{
    CGRect frame = [self bounds];
    CGFloat textWidth = frame.size.width - (self.insets.left + self.insets.right);

    CGSize newSize = [self.text sizeWithFont:self.font constrainedToSize:CGSizeMake(textWidth, 1000000) lineBreakMode:self.lineBreakMode];
    frame.size.height = newSize.height + self.insets.top + self.insets.bottom;
    self.frame = frame;
}

@end