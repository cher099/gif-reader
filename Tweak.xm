#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
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
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;
    for (size_t index = 0; index < count; index++) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(source, index, NULL);
        if (!image) continue;
        [frames addObject:[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]];
        CGImageRelease(image);

        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
        NSDictionary *gif = properties ? [(NSDictionary *)properties objectForKey:(NSString *)kCGImagePropertyGIFDictionary] : nil;
        NSNumber *delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
        if (![delay respondsToSelector:@selector(doubleValue)] || delay.doubleValue <= 0)
            delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFDelayTime];
        duration += delay.doubleValue > 0.01 ? delay.doubleValue : 0.1;
        if (properties) CFRelease(properties);
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
