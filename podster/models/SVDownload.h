#import "_SVDownload.h"
typedef enum {
    SVDownloadStatePending = 0,
    SVDownloadStateDownloading = 1,
    SVDownloadStatePaused = 2,
    SVDownloadStateFailed = 3
} SVDownloadState;
@interface SVDownload : _SVDownload {}
// Custom logic goes here.
@property (strong) MKNetworkOperation *downloadOperation;
@end
