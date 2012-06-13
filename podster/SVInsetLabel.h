//
// Created by blackgold9 on 6/13/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface SVInsetLabel : UILabel
@property (nonatomic, assign) UIEdgeInsets insets;
- (void)resizeHeightToFitText;
@end