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
#import "GADBannerView.h"
#import "SVPodcatcherClient.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

@implementation BannerViewController
{
    GADBannerView *_bannerView;
    BOOL _hasAd;
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
            _bannerView = [[GADBannerView alloc] initWithFrame:CGRectMake(0, 0, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height)];
            
            _bannerView.delegate = self;
            _bannerView.adUnitID = @"6d623966567243f6";
            _bannerView.rootViewController = self;
            _hasAd = NO;
        }
        
        _contentController = contentController;
    }
    return self;
}

- (UIViewController *)contentController
{
    return _contentController;
}

- (void)loadView
{
    UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (![[SVSettings sharedInstance] premiumModeUnlocked]) {
        [contentView addSubview:_bannerView];   
    }
    [self addChildViewController:_contentController];
    [contentView addSubview:_contentController.view];
    [_contentController didMoveToParentViewController:self];
    self.view = contentView;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becameActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
   [[NSNotificationCenter defaultCenter] addObserverForName:@"PremiumPurchased" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {

       if([[SVSettings sharedInstance] premiumModeUnlocked]) {
           if([_bannerView superview]) {
               _bannerView.delegate = nil;
               [_bannerView removeFromSuperview];
           }

       } else {

       }

       [self.view setNeedsLayout];
       [self.view layoutIfNeeded];
   }];
}

-(void)requestAd
{
    LOG_GENERAL(2, @"Sending ad request");
    GADRequest *request = [GADRequest request];

    [_bannerView loadRequest:request];
}

-(void)becameActive
{
    [self requestAd];

}
- (void)viewDidUnload
{
    _bannerView.delegate = nil;
    [super viewDidUnload];
}
   
- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    _hasAd= YES;
    LOG_GENERAL(2, @"Ad-View recieved ad");
    if (![_bannerView superview]) {
        LOG_GENERAL(2, @"Adding it to view");
        [self.view addSubview:_bannerView];
  
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
-(void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    _hasAd = NO;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
    
    if (error.code != kGADErrorNoFill){
//        double delayInSeconds = 10.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            LOG_GENERAL(2, @"Requesting ad after failure");
//            [self requestAd];
//        });
        [FlurryAnalytics logError:@"AdLoadFailed" message:[error localizedDescription] error:error];
    }
    
}


- (void)viewDidLayoutSubviews
{   
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = _bannerView.frame;
    if (_hasAd && [_bannerView  superview]) {
        // Ad is on screen/has ad
        bannerFrame.size = [_bannerView mediatedAdView].frame.size;
        contentFrame.size.height -= _bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    
    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
}

-(void)adViewWillPresentScreen:(GADBannerView *)adView
{
    [FlurryAnalytics logEvent:@"AdsFullscreenShown"];
    //Pause playback?
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];

}

-(void)adViewDidDismissScreen:(GADBannerView *)adView
{
    // Resume playback?
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}

@end
