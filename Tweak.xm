#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>
#import <string.h>

@interface PLManagedAsset : NSObject
- (id)largestAvailableDataRepresentationAndType:(id *)type;
@end

@interface PLPhotoTileViewController : UIViewController
@property(readonly, nonatomic) PLManagedAsset *photo;
- (void)setFullSizeImage:(id)image;
@end

@interface PGGIFPlayer : NSObject {
    CGImageSourceRef _source;
    NSUInteger _frameCount;
    NSUInteger _frameIndex;
    UIImageView *_imageView;
    NSTimer *_timer;
    CGFloat _imageScale;
    BOOL _running;
}
- (id)initWithData:(NSData *)data imageView:(UIImageView *)imageView scale:(CGFloat)scale;
- (void)start;
- (void)stop;
@end

@implementation PGGIFPlayer

- (id)initWithData:(NSData *)data imageView:(UIImageView *)imageView scale:(CGFloat)scale {
    self = [super init];
    if (!self) return nil;

    NSDictionary *sourceOptions = [NSDictionary dictionaryWithObject:(id)kCFBooleanFalse
                                                               forKey:(id)kCGImageSourceShouldCache];
    _source = CGImageSourceCreateWithData((CFDataRef)data, (CFDictionaryRef)sourceOptions);
    _frameCount = _source ? CGImageSourceGetCount(_source) : 0;
    if (_frameCount < 2) {
        [self release];
        return nil;
    }
    _imageView = [imageView retain];
    _imageScale = scale > 0 ? scale : 1.0;
    return self;
}

- (NSTimeInterval)delayForFrame:(NSUInteger)index {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_source, index, NULL);
    NSDictionary *gif = properties ? [(NSDictionary *)properties objectForKey:(NSString *)kCGImagePropertyGIFDictionary] : nil;
    NSNumber *delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (![delay respondsToSelector:@selector(doubleValue)] || delay.doubleValue <= 0)
        delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFDelayTime];
    NSTimeInterval interval = delay.doubleValue;
    if (properties) CFRelease(properties);
    return interval > 0.01 ? interval : 0.1;
}

- (BOOL)showFrameAtIndex:(NSUInteger)index {
    NSDictionary *options = [NSDictionary dictionaryWithObject:(id)kCFBooleanFalse
                                                          forKey:(id)kCGImageSourceShouldCache];
    CGImageRef frame = CGImageSourceCreateImageAtIndex(_source, index, (CFDictionaryRef)options);
    if (!frame) return NO;
    UIImage *image = [UIImage imageWithCGImage:frame scale:_imageScale orientation:UIImageOrientationUp];
    CGImageRelease(frame);
    _imageView.image = image;
    return YES;
}

- (void)scheduleNextFrame {
    if (!_running) return;
    NSTimeInterval delay = [self delayForFrame:_frameIndex];
    _timer = [[NSTimer timerWithTimeInterval:delay
                                      target:self
                                    selector:@selector(advanceFrame:)
                                    userInfo:nil
                                     repeats:NO] retain];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)start {
    if (_running) return;
    _running = [self showFrameAtIndex:0];
    _frameIndex = 0;
    [self scheduleNextFrame];
}

- (void)advanceFrame:(NSTimer *)timer {
    [_timer release];
    _timer = nil;
    if (!_running) return;
    _frameIndex = (_frameIndex + 1) % _frameCount;
    if (![self showFrameAtIndex:_frameIndex]) {
        _running = NO;
        return;
    }
    [self scheduleNextFrame];
}

- (void)stop {
    _running = NO;
    [_timer invalidate];
    [_timer release];
    _timer = nil;
}

- (void)dealloc {
    [self stop];
    if (_source) CFRelease(_source);
    [_imageView release];
    [super dealloc];
}

@end

static char PGGIFPlayerKey;

static UIImageView *PGFindImageView(UIView *view, UIImage *image) {
    if ([view isKindOfClass:[UIImageView class]] && [(UIImageView *)view image] == image)
        return (UIImageView *)view;
    for (UIView *subview in [view subviews]) {
        UIImageView *match = PGFindImageView(subview, image);
        if (match) return match;
    }
    return nil;
}

@interface PLPhotoTileViewController (PGGIFSupport)
- (void)pg_startGIFForImage:(id)image;
- (void)pg_stopGIFPlayer;
@end

@implementation PLPhotoTileViewController (PGGIFSupport)

- (void)pg_stopGIFPlayer {
    PGGIFPlayer *player = (PGGIFPlayer *)objc_getAssociatedObject(self, &PGGIFPlayerKey);
    [player stop];
    objc_setAssociatedObject(self, &PGGIFPlayerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)pg_startGIFForImage:(id)image {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(pg_startGIFForImage:) withObject:image waitUntilDone:NO];
        return;
    }
    if (![image isKindOfClass:[UIImage class]]) return;

    id type = nil;
    id data = [[self photo] largestAvailableDataRepresentationAndType:&type];
    if (![data isKindOfClass:[NSData class]] || [data length] < 6) return;
    const unsigned char *bytes = (const unsigned char *)[(NSData *)data bytes];
    if (memcmp(bytes, "GIF87a", 6) && memcmp(bytes, "GIF89a", 6)) return;

    UIImageView *imageView = PGFindImageView([self view], (UIImage *)image);
    if (!imageView) return;

    CGFloat scale = [(UIImage *)image respondsToSelector:@selector(scale)] ? [(UIImage *)image scale] : 1.0;
    PGGIFPlayer *player = [[PGGIFPlayer alloc] initWithData:(NSData *)data imageView:imageView scale:scale];
    if (!player) return;
    objc_setAssociatedObject(self, &PGGIFPlayerKey, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [player start];
    [player release];
}

@end

%hook PLPhotoTileViewController

- (void)setFullSizeImage:(id)image {
    [self pg_stopGIFPlayer];
    %orig(image);
    if ([NSThread isMainThread]) {
        [self performSelector:@selector(pg_startGIFForImage:) withObject:image afterDelay:0.05];
    } else {
        [self performSelectorOnMainThread:@selector(pg_startGIFForImage:) withObject:image waitUntilDone:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);
    [self pg_stopGIFPlayer];
}

%end

