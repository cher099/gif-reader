#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <math.h>
#import <string.h>

@interface PLManagedAsset : NSObject
- (id)largestAvailableDataRepresentationAndType:(id *)type;
@end

@interface PLPhotoTileViewController : UIViewController
@property(readonly, nonatomic) PLManagedAsset *photo;
- (void)setFullSizeImage:(id)image;
@end

static UIImage *PGAnimatedGIF(NSData *data, CGFloat scale) {
    if (data.length < 6) return nil;
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    if (memcmp(bytes, "GIF87a", 6) && memcmp(bytes, "GIF89a", 6)) return nil;

    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    if (!source) return nil;

    size_t count = CGImageSourceGetCount(source);
    if (count < 2) {
        CFRelease(source);
        return nil;
    }

    // UIImage's animated image keeps every decoded frame in memory. Bound that
    // cost for older devices by sampling long GIFs and downsampling each frame.
    const size_t maximumFrames = 40;
    const double maximumDecodedPixels = 2500000.0;
    size_t stride = (count + maximumFrames - 1) / maximumFrames;
    if (stride < 1) stride = 1;
    size_t selectedFrames = (count + stride - 1) / stride;

    size_t sourceWidth = 640;
    size_t sourceHeight = 960;
    CFDictionaryRef firstProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    if (firstProperties) {
        NSNumber *width = [(NSDictionary *)firstProperties objectForKey:(NSString *)kCGImagePropertyPixelWidth];
        NSNumber *height = [(NSDictionary *)firstProperties objectForKey:(NSString *)kCGImagePropertyPixelHeight];
        if ([width respondsToSelector:@selector(unsignedIntegerValue)] && width.unsignedIntegerValue > 0)
            sourceWidth = width.unsignedIntegerValue;
        if ([height respondsToSelector:@selector(unsignedIntegerValue)] && height.unsignedIntegerValue > 0)
            sourceHeight = height.unsignedIntegerValue;
        CFRelease(firstProperties);
    }
    double sourcePixelsPerFrame = (double)sourceWidth * (double)sourceHeight;
    double downsampleRatio = sqrt(maximumDecodedPixels / ((double)selectedFrames * sourcePixelsPerFrame));
    if (downsampleRatio > 1.0) downsampleRatio = 1.0;
    size_t maximumPixelSize = (size_t)floor((double)MAX(sourceWidth, sourceHeight) * downsampleRatio);
    if (maximumPixelSize < 1) maximumPixelSize = 1;
    NSDictionary *thumbnailOptions = [NSDictionary dictionaryWithObjectsAndKeys:
        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
        [NSNumber numberWithUnsignedInteger:maximumPixelSize], (id)kCGImageSourceThumbnailMaxPixelSize,
        nil];

    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:selectedFrames];
    NSTimeInterval duration = 0;
    for (size_t index = 0; index < count; index++) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
        NSDictionary *gif = properties ? [(NSDictionary *)properties objectForKey:(NSString *)kCGImagePropertyGIFDictionary] : nil;
        NSNumber *delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
        if (![delay respondsToSelector:@selector(doubleValue)] || delay.doubleValue <= 0)
            delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFDelayTime];
        duration += delay.doubleValue > 0.01 ? delay.doubleValue : 0.1;
        if (properties) CFRelease(properties);

        if (index % stride != 0) continue;
        CGImageRef image = CGImageSourceCreateThumbnailAtIndex(source, index, (CFDictionaryRef)thumbnailOptions);
        if (!image) image = CGImageSourceCreateImageAtIndex(source, index, NULL);
        if (!image) continue;
        [frames addObject:[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]];
        CGImageRelease(image);
    }
    CFRelease(source);
    if (frames.count < 2) return nil;
    return [UIImage animatedImageWithImages:frames duration:duration];
}

static UIImage *PGAnimatedGIFForManagedAsset(PLManagedAsset *asset) {
    if (!asset) return nil;
    id type = nil;
    id data = [asset largestAvailableDataRepresentationAndType:&type];
    if (![data isKindOfClass:[NSData class]]) return nil;
    return PGAnimatedGIF((NSData *)data, 1.0);
}

%hook PLPhotoTileViewController

- (void)setFullSizeImage:(id)image {
    UIImage *animated = PGAnimatedGIFForManagedAsset([self photo]);
    %orig(animated ? animated : image);
}

%end

%hook UIImage

- (id)initWithData:(NSData *)data {
    UIImage *animated = PGAnimatedGIF(data, 1.0);
    if (animated) {
        [self release];
        return [animated retain];
    }
    return %orig(data);
}

- (id)initWithData:(NSData *)data scale:(CGFloat)scale {
    UIImage *animated = PGAnimatedGIF(data, scale);
    if (animated) {
        [self release];
        return [animated retain];
    }
    return %orig(data, scale);
}

- (id)initWithContentsOfFile:(NSString *)path {
    if ([[[path pathExtension] lowercaseString] isEqualToString:@"gif"]) {
        UIImage *animated = PGAnimatedGIF([NSData dataWithContentsOfFile:path], 1.0);
        if (animated) {
            [self release];
            return [animated retain];
        }
    }
    return %orig(path);
}

+ (UIImage *)imageWithData:(NSData *)data {
    UIImage *animated = PGAnimatedGIF(data, 1.0);
    return animated ? animated : %orig(data);
}

+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale {
    UIImage *animated = PGAnimatedGIF(data, scale);
    return animated ? animated : %orig(data, scale);
}

+ (UIImage *)imageWithContentsOfFile:(NSString *)path {
    if ([[[path pathExtension] lowercaseString] isEqualToString:@"gif"]) {
        UIImage *animated = PGAnimatedGIF([NSData dataWithContentsOfFile:path], 1.0);
        if (animated) return animated;
    }
    return %orig(path);
}

%end
