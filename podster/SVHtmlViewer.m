//
// Created by j-stevan@interactive.msnbc.com on 6/24/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SVHtmlViewer.h"
#import "NSString+MW_HTML.h"
#import "NativeWebView.h"


@implementation SVHtmlViewer {
    NativeWebView *webView;
}
@synthesize html = _html;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-gradient.jpg"]];
        [self addSubview:imageView];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        webView = [[NativeWebView alloc] initWithFrame:self.bounds];
        webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        webView.backgroundColor = [UIColor clearColor];
        webView.delegate = self;
        webView.opaque = NO;
        [self addSubview:webView];
    }

    return self;
}

- (void)setHtml:(NSString *)aHtml {
    if (_html != aHtml) {
        aHtml = [aHtml mutableCopy];

        NSString *myDescriptionHTML = [NSString stringWithFormat:@"<html> \n"
                                                                         "<head> \n"
                                                                         "<meta name = \"viewport\" content = \"width = 320,"
                                                                         "initial-scale = 2.3, user-scalable = no\">"
                                                                         "<style type=\"text/css\"> \n"
                                                                         "body {font-family: \"%@\"; font-size: %@; color:#fff;}\n"
                                                                         "img { max-width: 280;} \n"
                                                                         "a { color:#9af} \n"
                                                                         "</style> \n"
                                                                         "</head> \n"
                                                                         "<body>%@</body> \n"
                                                                         "</html>", @"HelveticaNeue", [NSNumber numberWithInt:15], [aHtml stringWithNewLinesAsBRs]];
        myDescriptionHTML = [myDescriptionHTML stringByReplacingOccurrencesOfString:@"\"white\"" withString:@"\"black\""];
        [webView loadHTMLString:@"Test" baseURL:nil];
        [webView loadHTMLString:myDescriptionHTML
                            baseURL:nil];
        webView.backgroundColor = [UIColor clearColor];
        _html = aHtml;
    }
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSURL *requestURL = [request URL];
    if ( ( [ [ requestURL scheme ] isEqualToString: @"http" ] || [ [ requestURL scheme ] isEqualToString: @"https" ] || [ [ requestURL scheme ] isEqualToString: @"mailto" ])
            && ( navigationType == UIWebViewNavigationTypeLinkClicked ) ) {
        [Flurry logEvent:@"UserTappedLinkFromShowNotes"];
        return ![ [ UIApplication sharedApplication ] openURL: requestURL ];
    }
    return YES;
}
@end