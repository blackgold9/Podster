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
#import "GADBannerView.h"
#import <CoreLocation/CoreLocation.h>
NSString *const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString *const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

@implementation BannerViewController {

    GADBannerView *_bannerView;
    UIViewController *_contentController;
    BOOL shouldHideAd;
}

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (id)initWithContentViewController:(UIViewController *)contentController {
    self = [super init];
    if (self != nil) {
        if (![[SVSettings sharedInstance] premiumModeUnlocked]) {

            _bannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(GAD_SIZE_320x50)];
            [_bannerView setAdUnitID:@"c4ab1f3b218f441f"];
            _bannerView.delegate = self;
            _bannerView.rootViewController = self;
            // Initiate a generic request to load it with an ad.
            GADRequest *request = [GADRequest request];

            if ([CLLocationManager locationServicesEnabled]) {
                            CLLocationManager *locationManager = [[CLLocationManager alloc] init];
                [request setLocationWithLatitude:locationManager.location.coordinate.latitude
                                       longitude:locationManager.location.coordinate.longitude
                                        accuracy:locationManager.location.horizontalAccuracy];
            }
            
            [request.keywords addObject:@"Podcast"];
            [request.keywords addObject:@"Podcasts"];
            [request.keywords addObject:@"Radio"];
#if DEBUG
            request.testing = YES;
#endif
            [_bannerView loadRequest:request];
            _contentController = contentController;
            shouldHideAd = NO;

        }

        _contentController = contentController;
    }
    return self;
}

- (UIViewController *)contentController {
    return _contentController;
}


- (void)viewDidLoad {
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

        if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
            [_bannerView removeFromSuperview];
            _bannerView.delegate = nil;
            _bannerView = nil;
        }

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}


- (void)becameActive {
    // Hide the ad when coming back from the background. It's probably blank at this point. 
    // After this next layout, it will reset shouldHideAd to NO
    shouldHideAd = YES;
    [self.view setNeedsLayout];
//    [self.view layoutIfNeeded];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self viewDidLayoutSubviews];
}

- (void)viewDidDisappear:(BOOL)animated {
    _bannerView.delegate = nil;
    [super viewDidDisappear:animated];
}

// Sent when an ad request loaded an ad.  This is a good opportunity to add this
// view to the hierarchy if it has not yet been added.  If the ad was received
// as a part of the server-side auto refreshing, you can examine the
// hasAutoRefreshed property of the view.
- (void)adViewDidReceiveAd:(GADBannerView *)view {
    id adWebView = [[view subviews] objectAtIndex:0];

    if ([adWebView isKindOfClass:[UIWebView class]]) {
        UIWebView *webView = adWebView;
        webView.scrollView.scrollsToTop = NO;
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];

}

// Sent when an ad request failed.  Normally this is because no network
// connection was available or no ads were available (i.e. no fill).  If the
// error was received as a part of the server-side auto refreshing, you can
// examine the hasAutoRefreshed property of the view.
- (void)             adView:(GADBannerView *)view
didFailToReceiveAdWithError:(GADRequestError *)error {
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)viewDidLayoutSubviews {
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = _bannerView.frame;
    if (_bannerView && !shouldHideAd &&
            [_bannerView mediatedAdView]) {

        bannerFrame.size = _bannerView.mediatedAdView.frame.size;
        contentFrame.size.height -= _bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }

    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
    shouldHideAd = NO;
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    [FlurryAnalytics logEvent:@"AdsFullscreenShown"];
    //Pause playback?
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    // Resume playback?
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}
@end
