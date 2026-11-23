#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <string.h>

static NSMutableDictionary *PGAnimatedImagesByCGImage;

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

static UIImage *PGAnimatedGIFForRepresentation(ALAssetRepresentation *representation) {
    NSString *uti = [[representation UTI] lowercaseString];
    if (![uti isEqualToString:@"com.compuserve.gif"] && ![uti isEqualToString:@"public.gif"])
        return nil;
    NSURL *url = [representation url];
    NSData *data = url ? [NSData dataWithContentsOfURL:url] : nil;
    return PGAnimatedGIF(data, 1.0);
}

%hook ALAssetRepresentation

- (CGImageRef)fullScreenImage {
    CGImageRef image = %orig;
    if (image) {
        UIImage *animated = PGAnimatedGIFForRepresentation(self);
        if (animated) {
            if (!PGAnimatedImagesByCGImage) PGAnimatedImagesByCGImage = [[NSMutableDictionary alloc] init];
            [PGAnimatedImagesByCGImage setObject:animated forKey:[NSValue valueWithPointer:image]];
        }
    }
    return image;
}

- (CGImageRef)fullResolutionImage {
    CGImageRef image = %orig;
    if (image) {
        UIImage *animated = PGAnimatedGIFForRepresentation(self);
        if (animated) {
            if (!PGAnimatedImagesByCGImage) PGAnimatedImagesByCGImage = [[NSMutableDictionary alloc] init];
            [PGAnimatedImagesByCGImage setObject:animated forKey:[NSValue valueWithPointer:image]];
        }
    }
    return image;
}

%end

%hook UIImage

+ (UIImage *)imageWithCGImage:(CGImageRef)image {
    UIImage *animated = [PGAnimatedImagesByCGImage objectForKey:[NSValue valueWithPointer:image]];
    return animated ? animated : %orig(image);
}

+ (UIImage *)imageWithCGImage:(CGImageRef)image scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    UIImage *animated = [PGAnimatedImagesByCGImage objectForKey:[NSValue valueWithPointer:image]];
    return animated ? animated : %orig(image, scale, orientation);
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
