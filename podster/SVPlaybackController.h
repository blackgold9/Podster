//
//  SVPlaybackController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVPlaybackController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *skipForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *skipBackButton;
- (IBAction)playTapped:(id)sender;
@property (weak, nonatomic) IBOutletCollection(UIView) NSArray *chromeViews;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsedLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

+(NSString *)formattedStringRepresentationOfSeconds:(NSInteger)seconds;
@end
