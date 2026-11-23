#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

static UIImage *PGAnimatedGIF(NSData *data, CGFloat scale) {
    if (data.length < 6) return nil;

    const unsigned char *bytes = (const unsigned char *)data.bytes;
    BOOL isGIF87a = memcmp(bytes, "GIF87a", 6) == 0;
    BOOL isGIF89a = memcmp(bytes, "GIF89a", 6) == 0;
    if (!isGIF87a && !isGIF89a) return nil;

    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    if (!source) return nil;

    size_t count = CGImageSourceGetCount(source);
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;

    for (size_t index = 0; index < count; index++) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(source, index, NULL);
        if (!image) continue;

        UIImage *frame = [UIImage imageWithCGImage:image
                                             scale:scale
                                       orientation:UIImageOrientationUp];
        [frames addObject:frame];
        CGImageRelease(image);

        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
        NSDictionary *gif = properties ? [(NSDictionary *)properties objectForKey:(NSString *)kCGImagePropertyGIFDictionary] : nil;
        NSNumber *delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
        if (![delay respondsToSelector:@selector(doubleValue)] || delay.doubleValue <= 0)
            delay = [gif objectForKey:(NSString *)kCGImagePropertyGIFDelayTime];
        duration += (delay.doubleValue > 0.01 ? delay.doubleValue : 0.1);

        if (properties) CFRelease(properties);
    }

    CFRelease(source);
    if (frames.count < 2) return nil;

    return [UIImage animatedImageWithImages:frames duration:duration];
}

%hook UIImage

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
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *animated = PGAnimatedGIF(data, 1.0);
        if (animated) return animated;
    }
    return %orig(path);
}

%end
