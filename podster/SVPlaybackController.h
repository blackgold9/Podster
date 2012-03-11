//
//  SVPlaybackController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OBSlider;
@interface SVPlaybackController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *skipForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *skipBackButton;
- (IBAction)playTapped:(id)sender;
@property (weak, nonatomic) IBOutletCollection(UIView) NSArray *chromeViews;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *artworkImage;
@property (weak, nonatomic) IBOutlet OBSlider *progressSlider;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsedLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)skipForwardTapped:(id)sender;
- (IBAction)skipBackTapped:(id)sender;

+(NSString *)formattedStringRepresentationOfSeconds:(NSInteger)seconds;
@end
