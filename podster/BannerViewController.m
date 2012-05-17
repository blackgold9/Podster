/*     File: BannerViewController.m */
/* Abstract: A container view controller that manages an ADBannerView and a content view controller */
/*  Version: 2.0 */
/*  */
/* Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple */
/* Inc. ("Apple") in consideration of your agreement to the following */
/* terms, and your use, installation, modification or redistribution of */
/* this Apple software constitutes acceptance of these terms.  If you do */
/* not agree with these terms, please do not use, install, modify or */
/* redistribute this Apple software. */
/*  */
/* In consideration of your agreement to abide by the following terms, and */
/* subject to these terms, Apple grants you a personal, non-exclusive */
/* license, under Apple's copyrights in this original Apple software (the */
/* "Apple Software"), to use, reproduce, modify and redistribute the Apple */
/* Software, with or without modifications, in source and/or binary forms; */
/* provided that if you redistribute the Apple Software in its entirety and */
/* without modifications, you must retain this notice and the following */
/* text and disclaimers in all such redistributions of the Apple Software. */
/* Neither the name, trademarks, service marks or logos of Apple Inc. may */
/* be used to endorse or promote products derived from the Apple Software */
/* without specific prior written permission from Apple.  Except as */
/* expressly stated in this notice, no other rights or licenses, express or */
/* implied, are granted by Apple herein, including but not limited to any */
/* patent rights that may be infringed by your derivative works or by other */
/* works in which the Apple Software may be incorporated. */
/*  */
/* The Apple Software is provided by Apple on an "AS IS" basis.  APPLE */
/* MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION */
/* THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS */
/* FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND */
/* OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. */
/*  */
/* IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL */
/* OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF */
/* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS */
/* INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, */
/* MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED */
/* AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), */
/* STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE */
/* POSSIBILITY OF SUCH DAMAGE. */
/*  */
/* Copyright (C) 2011 Apple Inc. All Rights Reserved. */
/*  */

#import "BannerViewController.h"
#import "SVSettings.h"
#import "SVPodcatcherClient.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

@implementation BannerViewController
{

        AdWhirlView *_bannerView;
    UIViewController *_contentController;
}

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}
- (id)initWithContentViewController:(UIViewController *)contentController
{
    self = [super init];
    if (self != nil) {
        if (![[SVSettings sharedInstance] premiumModeUnlocked]) {
            
            _bannerView = [AdWhirlView requestAdWhirlViewWithDelegate:self];
            _bannerView.delegate = self;
            _contentController = contentController;

        }
        
        _contentController = contentController;
    }
    return self;
}

- (UIViewController *)contentController
{
    return _contentController;
}

- (NSString *)adWhirlApplicationKey
{
    return @"91e9936604204bdb96316e8ebbf225ed";

}

- (void)viewDidLoad
{
    UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:contentView];
    if (![[SVSettings sharedInstance] premiumModeUnlocked]) {
        [contentView addSubview:_bannerView];   
    }
    [self addChildViewController:_contentController];
    [contentView addSubview:_contentController.view];
    [_contentController didMoveToParentViewController:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
   [[NSNotificationCenter defaultCenter] addObserverForName:@"PremiumPurchased" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {

       if([[SVSettings sharedInstance] premiumModeUnlocked]) {
           [_bannerView ignoreNewAdRequests];
       } else {
           [_bannerView doNotIgnoreNewAdRequests];
       }

       [self.view setNeedsLayout];
       [self.view layoutIfNeeded];
   }];
}


-(void)becameActive
{        
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];    
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
 
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   
    [self viewDidLayoutSubviews];
}
- (void)viewDidUnload
{
    _bannerView.delegate = nil;
    [super viewDidUnload];
}
   
- (void)viewDidLayoutSubviews
{    
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = _bannerView.frame;
    if ([_bannerView adExists] && ![_bannerView isIgnoringNewAdRequests]) {
        
        bannerFrame.size = [_bannerView actualAdSize];
        contentFrame.size.height -= _bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
}
-(void)adWhirlDidReceiveAd:(AdWhirlView *)adWhirlView
{
    
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

-(void)adWhirlDidFailToReceiveAd:(AdWhirlView *)adWhirlView usingBackup:(BOOL)yesOrNo
{
    
    if (!yesOrNo) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }];
    } else {
        LOG_GENERAL(2, @"Ad Controller failed to receive ad. Going to try fallback: %@", adWhirlView.lastError);
    }
}
-(void)adWhirlDidAnimateToNewAdIn:(AdWhirlView *)adWhirlView
{
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

-(BOOL)adWhirlTestMode
{
#ifdef CONFIGURATION_Release
    return NO;
#else
    return YES;
#endif
}
-(void)adWhirlWillPresentFullScreenModal
{
    [FlurryAnalytics logEvent:@"AdsFullscreenShown"];
    //Pause playback?
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
}

-(void)adWhirlDidDismissFullScreenModal
{
    // Resume playback?
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}
@end
