#import "GIFViewController.h"
#import <ImageIO/ImageIO.h>

@interface GIFViewController ()
@property (nonatomic, copy) NSString *path;
@property (nonatomic, retain) UIImageView *imageView;
@end

@implementation GIFViewController
- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) _path = [path copy];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = [self.path lastPathComponent];
    UIImageView *view = [[[UIImageView alloc] initWithFrame:self.view.bounds] autorelease];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.contentMode = UIViewContentModeScaleAspectFit;
    view.backgroundColor = [UIColor blackColor];
    self.imageView = view;
    [self.view addSubview:view];
    [self loadGIF];
}

- (void)loadGIF {
    NSData *data = [NSData dataWithContentsOfFile:self.path];
    CGImageSourceRef source = data ? CGImageSourceCreateWithData((CFDataRef)data, NULL) : NULL;
    size_t count = source ? CGImageSourceGetCount(source) : 0;
    if (count < 1) {
        if (source) CFRelease(source);
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to play GIF" message:@"This file could not be read as an animated image." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
        return;
    }
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;
    for (size_t i = 0; i < count; i++) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
        if (!image) continue;
        [frames addObject:[UIImage imageWithCGImage:image]];
        CFRelease(image);
        NSDictionary *properties = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
        NSDictionary *gif = [properties objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
        NSNumber *delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
        if (![delay respondsToSelector:@selector(doubleValue)] || delay.doubleValue <= 0)
            delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFDelayTime];
        duration += (delay.doubleValue > 0.01 ? delay.doubleValue : 0.1);
        if (properties) CFRelease((CFTypeRef)properties);
    }
    CFRelease(source);
    self.imageView.animationImages = frames;
    self.imageView.animationDuration = duration;
    self.imageView.animationRepeatCount = 0;
    [self.imageView startAnimating];
}
@end
