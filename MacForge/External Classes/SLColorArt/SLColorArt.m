//
//  SLColorArt.m
//  ColorArt
//
//  Created by Aaron Brethorst on 12/11/12.
//
// Copyright (C) 2012 Panic Inc. Code by Wade Cosgrove. All rights reserved.
//
// Redistribution and use, with or without modification, are permitted provided that the following conditions are met:
//
// - Redistributions must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
// - Neither the name of Panic Inc nor the names of its contributors may be used to endorse or promote works derived from this software without specific prior written permission from Panic Inc.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL PANIC INC BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "SLColorArt.h"
#import "EQImage+Scale.h"
#import "EQImage+Helper.h"
#define kAnalyzedBackgroundColor @"kAnalyzedBackgroundColor"
#define kAnalyzedPrimaryColor @"kAnalyzedPrimaryColor"
#define kAnalyzedSecondaryColor @"kAnalyzedSecondaryColor"
#define kAnalyzedDetailColor @"kAnalyzedDetailColor"


@interface EQColor (DarkAddition)

- (BOOL)pc_isDarkColor;
- (BOOL)pc_isDistinct:(EQColor*)compareColor;
- (EQColor*)pc_colorWithMinimumSaturation:(CGFloat)saturation;
- (BOOL)pc_isBlackOrWhite;
- (BOOL)pc_isContrastingColor:(EQColor*)color;

@end


@interface PCCountedColor : NSObject

@property (assign) NSUInteger count;
@property (strong) EQColor *color;

- (id)initWithColor:(EQColor*)color count:(NSUInteger)count;

@end

@interface SLColorArt ()
@property(nonatomic, copy) EQImage *image;
@property(nonatomic,readwrite,strong) EQColor *backgroundColor;
@property(nonatomic,readwrite,strong) EQColor *primaryColor;
@property(nonatomic,readwrite,strong) EQColor *secondaryColor;
@property(nonatomic,readwrite,strong) EQColor *detailColor;
@property(nonatomic,readwrite) NSInteger randomColorThreshold;
@end

@implementation SLColorArt

- (id)initWithImage:(EQImage*)image
{
    self = [self initWithImage:image threshold:2];
    if (self) {

    }
    return self;
}

- (id)initWithImage:(EQImage*)image threshold:(NSInteger)threshold;
{
    self = [super init];

    if (self)
    {
        self.randomColorThreshold = threshold;
        self.image = image;
        [self _processImage];
    }

    return self;
}


+ (void)processImage:(EQImage *)image
        scaledToSize:(CGSize)scaleSize
           threshold:(NSInteger)threshold
          onComplete:(void (^)(SLColorArt *colorArt))completeBlock;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EQImage *scaledImage = [image scaledToSize:scaleSize];
        SLColorArt *colorArt = [[SLColorArt alloc] initWithImage:scaledImage
                                                       threshold:threshold];
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(colorArt);
        });
    });
    
}

- (void)_processImage
{
    //EQImage *finalImage = [self _scaleImage:self.image size:self.scaledSize];

    NSDictionary *colors = [self _analyzeImage:self.image];

    self.backgroundColor = [colors objectForKey:kAnalyzedBackgroundColor];
    self.primaryColor = [colors objectForKey:kAnalyzedPrimaryColor];
    self.secondaryColor = [colors objectForKey:kAnalyzedSecondaryColor];
    self.detailColor = [colors objectForKey:kAnalyzedDetailColor];

    //self.scaledImage = finalImage;
}

- (EQImage*)_scaleImage:(EQImage*)image size:(CGSize)scaledSize
{
    return [image scaledToSize:scaledSize];
}

- (NSDictionary*)_analyzeImage:(EQImage*)anImage
{
    NSArray *imageColors = nil;
	EQColor *backgroundColor = [self _findEdgeColor:anImage imageColors:&imageColors];
	EQColor *primaryColor = nil;
	EQColor *secondaryColor = nil;
	EQColor *detailColor = nil;
    
    // If the random color threshold is too high and the image size too small,
    // we could miss detecting the background color and crash.
    if ( backgroundColor == nil )
    {
#if TARGET_OS_IPHONE
        backgroundColor = [EQColor whiteColor];
#else
        // Make sure this is in the correct color space or other methods using the
        // `[NSColor getRed:green:lue:alpha:]` API will crash.
        backgroundColor = [[EQColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
#endif
    }
    
//	BOOL darkBackground = [backgroundColor pc_isDarkColor];

	[self _findTextColors:imageColors primaryColor:&primaryColor secondaryColor:&secondaryColor detailColor:&detailColor backgroundColor:backgroundColor];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
    if (backgroundColor) {
      [dict setObject:backgroundColor forKey:kAnalyzedBackgroundColor];
    }
    if (primaryColor) {
      [dict setObject:primaryColor forKey:kAnalyzedPrimaryColor];
    }
    if (secondaryColor) {
      [dict setObject:secondaryColor forKey:kAnalyzedSecondaryColor];
    }
    if (detailColor) {
      [dict setObject:detailColor forKey:kAnalyzedDetailColor];
    }


    return [NSDictionary dictionaryWithDictionary:dict];
}

typedef struct RGBAPixel
{
    Byte red;
    Byte green;
    Byte blue;
    Byte alpha;
    
} RGBAPixel;

- (NSBitmapImageRep *)bitmapImageRepresentationForImage:(NSImage *)image {
    int width = [image size].width;
    int height = [image size].height;
    
    if(width < 1 || height < 1)
        return nil;
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes: NULL
                             pixelsWide: width
                             pixelsHigh: height
                             bitsPerSample: 8
                             samplesPerPixel: 4
                             hasAlpha: YES
                             isPlanar: NO
                             colorSpaceName: NSDeviceRGBColorSpace
                             bytesPerRow: width * 4
                             bitsPerPixel: 32];
    
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep: rep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: ctx];
    [image drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositingOperationCopy fraction: 1.0];
    [ctx flushGraphics];
    [NSGraphicsContext restoreGraphicsState];
    
    return rep;
}

- (EQColor*)_findEdgeColor:(EQImage*)image imageColors:(NSArray**)colors
{
    NSBitmapImageRep *imageRep = [self bitmapImageRepresentationForImage:image];
    imageRep = [(NSBitmapImageRep*)imageRep bitmapImageRepByConvertingToColorSpace:[NSColorSpace genericRGBColorSpace] renderingIntent:NSColorRenderingIntentDefault];
    
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    NSUInteger colorCount = 0;

    struct RGBAPixel* pixels = (struct RGBAPixel*)[imageRep bitmapData];
    
    NSInteger width =imageRep.pixelsWide;
    NSInteger height = imageRep.pixelsHigh;
    NSMutableArray *imgColors = [NSMutableArray new];
    for ( NSUInteger x = 0; x < width; x++ ) {
        for ( NSUInteger y = 0; y < height; y++ ){
            const NSUInteger index = x + y * width;
            RGBAPixel pixel = pixels[index];
            if(pixel.alpha >= 127) {
                EQColor *color = [EQColor colorWithRed:(pixel.red/255.0f) green:(pixel.green/255.0f) blue:(pixel.blue/255.0f) alpha:1];
                
                PCCountedColor* countedColor = [[PCCountedColor alloc] initWithColor:color count:index];
                [imgColors addObject:countedColor];
                if(colorCount <= EDGE_THICKNESS) {
                    red += color.redComponent;
                    green += color.greenComponent;
                    blue += color.blueComponent;
                    colorCount += 1;
                }
            }
        }
        
    }

    *colors = imgColors;
    red /= colorCount;
    green /= colorCount;
    blue /= colorCount;
    
    EQColor *ret = [EQColor colorWithRed:red green:green blue:blue alpha:1.0f];
    return ret;
}


- (void)_findTextColors:(NSArray*)colors primaryColor:(EQColor**)primaryColor secondaryColor:(EQColor**)secondaryColor detailColor:(EQColor**)detailColor backgroundColor:(EQColor*)backgroundColor
{
	EQColor *curColor = nil;
	NSMutableArray *sortedColors = [NSMutableArray arrayWithCapacity:[colors count]];
	BOOL findDarkTextColor = ![backgroundColor pc_isDarkColor];

    for(PCCountedColor* countedColor in colors) {
        EQColor* curColor = [countedColor.color pc_colorWithMinimumSaturation:.15];

		if ( [curColor pc_isDarkColor] == findDarkTextColor )
		{
			NSUInteger colorCount = countedColor.count;

			//if ( colorCount <= 2 ) // prevent using random colors, threshold should be based on input image size
			//	continue;

			PCCountedColor *container = [[PCCountedColor alloc] initWithColor:curColor count:colorCount];

			[sortedColors addObject:container];
		}
	}

	[sortedColors sortUsingSelector:@selector(compare:)];

	for ( PCCountedColor *curContainer in sortedColors )
	{
		curColor = curContainer.color;

		if ( *primaryColor == nil )
		{
			if ( [curColor pc_isContrastingColor:backgroundColor] )
				*primaryColor = curColor;
		}
		else if ( *secondaryColor == nil )
		{
			if ( ![*primaryColor pc_isDistinct:curColor] || ![curColor pc_isContrastingColor:backgroundColor] )
				continue;

			*secondaryColor = curColor;
		}
		else if ( *detailColor == nil )
		{
			if ( ![*secondaryColor pc_isDistinct:curColor] || ![*primaryColor pc_isDistinct:curColor] || ![curColor pc_isContrastingColor:backgroundColor] )
				continue;
            
			*detailColor = curColor;
			break;
		}
	}
}

@end

@implementation EQColor (DarkAddition)

- (BOOL)pc_isDarkColor
{
	EQColor *convertedColor = self;//[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
	CGFloat r, g, b, a;

	[convertedColor getRed:&r green:&g blue:&b alpha:&a];

	CGFloat lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;

	if ( lum < .5 )
	{
		return YES;
	}

	return NO;
}


- (BOOL)pc_isDistinct:(EQColor*)compareColor
{
	EQColor *convertedColor = self;//[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	EQColor *convertedCompareColor = compareColor;//[compareColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat r, g, b, a;
	CGFloat r1, g1, b1, a1;

	[convertedColor getRed:&r green:&g blue:&b alpha:&a];
	[convertedCompareColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];

	CGFloat threshold = .25; //.15

	if ( fabs(r - r1) > threshold ||
		fabs(g - g1) > threshold ||
		fabs(b - b1) > threshold ||
		fabs(a - a1) > threshold )
    {
        // check for grays, prevent multiple gray colors

        if ( fabs(r - g) < .03 && fabs(r - b) < .03 )
        {
            if ( fabs(r1 - g1) < .03 && fabs(r1 - b1) < .03 )
                return NO;
        }

        return YES;
    }

	return NO;
}


- (EQColor*)pc_colorWithMinimumSaturation:(CGFloat)minSaturation
{
	EQColor *tempColor = self;//[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	if ( tempColor != nil )
	{
		CGFloat hue = 0.0;
		CGFloat saturation = 0.0;
		CGFloat brightness = 0.0;
		CGFloat alpha = 0.0;

		[tempColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

		if ( saturation < minSaturation )
		{
			return [EQColor colorWithHue:hue saturation:minSaturation brightness:brightness alpha:alpha];
		}
	}

	return self;
}


- (BOOL)pc_isBlackOrWhite
{
	EQColor *tempColor = self;//[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	if ( tempColor != nil )
	{
		CGFloat r, g, b, a;

		[tempColor getRed:&r green:&g blue:&b alpha:&a];

		if ( r > .91 && g > .91 && b > .91 )
			return YES; // white

		if ( r < .09 && g < .09 && b < .09 )
			return YES; // black
	}

	return NO;
}


- (BOOL)pc_isContrastingColor:(EQColor*)color
{
	EQColor *backgroundColor = self;//[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	EQColor *foregroundColor = color;//[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	if ( backgroundColor != nil && foregroundColor != nil )
	{
		CGFloat br, bg, bb, ba;
		CGFloat fr, fg, fb, fa;

		[backgroundColor getRed:&br green:&bg blue:&bb alpha:&ba];
		[foregroundColor getRed:&fr green:&fg blue:&fb alpha:&fa];

		CGFloat bLum = 0.2126 * br + 0.7152 * bg + 0.0722 * bb;
		CGFloat fLum = 0.2126 * fr + 0.7152 * fg + 0.0722 * fb;

		CGFloat contrast = 0.;

		if ( bLum > fLum )
			contrast = (bLum + 0.05) / (fLum + 0.05);
		else
			contrast = (fLum + 0.05) / (bLum + 0.05);

		//return contrast > 3.0; //3-4.5
		return contrast > 1.6;
	}

	return YES;
}


@end


@implementation PCCountedColor

- (id)initWithColor:(EQColor*)color count:(NSUInteger)count
{
	self = [super init];

	if ( self )
	{
		self.color = color;
		self.count = count;
	}

	return self;
}

- (NSComparisonResult)compare:(PCCountedColor*)object
{
	if ( [object isKindOfClass:[PCCountedColor class]] )
	{
		if ( self.count < object.count )
		{
			return NSOrderedDescending;
		}
		else if ( self.count == object.count )
		{
			return NSOrderedSame;
		}
	}
    
	return NSOrderedAscending;
}


@end
