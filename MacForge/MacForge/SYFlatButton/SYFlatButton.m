//
//  SYFlatButton.m
//  SYFlatButton
//
//  Created by Sunnyyoung on 2016/11/17.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "SYFlatButton.h"

@interface SYFlatButton () <CALayerDelegate>

@property (nonatomic, strong) CAShapeLayer *imageLayer;
@property (nonatomic, strong) CATextLayer *titleLayer;
@property (nonatomic, assign) BOOL mouseDown;
@property NSMutableDictionary *fontFamilyNameToYOffsetMap; // used to offet certain fonts so they are properly centered vertically

@end

@implementation SYFlatButton

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways|NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited owner:self userInfo:nil]];
}

#pragma mark - Drawing method

- (void)drawRect:(NSRect)dirtyRect {
    // Do nothing
}

- (BOOL)layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window {
    return YES;
}

#pragma mark - Setup method

- (void)setup {
    // Setup layer
	self.layer = [CALayer new];
    self.wantsLayer = YES;
    self.layer.masksToBounds = YES;
    self.layer.delegate = self;
    self.layer.backgroundColor = [NSColor redColor].CGColor;
	
	// setup the list of custom y-offsets for specific fonts so they are vertically aligned
	self.fontFamilyNameToYOffsetMap = [NSMutableDictionary new];
	self.fontFamilyNameToYOffsetMap[@"Titillium Web"] = @(-4);
	
	// setup the rest of the control
	[self setupImageLayer];
	[self setupTitleLayer];
	[self animateColorForCurrentState];
}

- (void)setupImageLayer {
    // Ignore image layer if has no image or imagePosition equal to NSNoImage
    if (!self.image || self.imagePosition == NSNoImage) {
        [self.imageLayer removeFromSuperlayer];
        return;
    }
    
    CGSize buttonSize = self.frame.size;
    CGSize imageSize = self.image.size;
    CGSize titleSize = [self.title sizeWithAttributes:@{NSFontAttributeName: self.font}];
    CGFloat x = 0.0; // Image's origin x
    CGFloat y = 0.0; // Image's origin y
    
    // Caculate the image's and title's position depends on button's imagePosition and imageHugsTitle property
    NSCellImagePosition effectiveImagePosition = [self effectiveImagePositionFrom:self.imagePosition];
    BOOL effectiveImageHugsTitle = NO;
    if (@available(macOS 10.12, *)) {
        effectiveImageHugsTitle = self.imageHugsTitle;
    }
    
    switch (effectiveImagePosition) {
        case NSNoImage:
            return;
            break;
        case NSImageOnly: {
            x = (buttonSize.width - imageSize.width) / 2.0;
            y = (buttonSize.height - imageSize.height) / 2.0;
            break;
        }
        case NSImageOverlaps: {
            x = (buttonSize.width - imageSize.width) / 2.0;
            y = (buttonSize.height - imageSize.height) / 2.0;
            break;
        }
        case NSImageLeading:
        case NSImageLeft: {
            x = effectiveImageHugsTitle ? ((buttonSize.width - imageSize.width - titleSize.width) / 2.0 - self.spacing) : self.spacing;
            y = (buttonSize.height - imageSize.height) / 2.0;
            break;
        }
        case NSImageTrailing:
        case NSImageRight: {
            x = effectiveImageHugsTitle ? ((buttonSize.width - imageSize.width + titleSize.width) / 2.0 + self.spacing) : (buttonSize.width - imageSize.width - self.spacing);
            y = (buttonSize.height - imageSize.height) / 2.0;
            break;
        }
        case NSImageAbove: {
            x = (buttonSize.width - imageSize.width) / 2.0;
            y = effectiveImageHugsTitle ? ((buttonSize.height - imageSize.height - titleSize.height) / 2.0 - self.spacing) : self.spacing;
            break;
        }
        case NSImageBelow: {
            x = (buttonSize.width - imageSize.width) / 2.0;
            y = effectiveImageHugsTitle ? ((buttonSize.height - imageSize.height + titleSize.height) / 2.0 + self.spacing) : (buttonSize.height - imageSize.height - self.spacing);
            break;
        }
        default: {
            break;
        }
    }
    
    // Setup image layer
    self.imageLayer.frame = self.bounds;
    self.imageLayer.mask = ({
        CALayer *layer = [CALayer layer];
        NSRect rect = NSMakeRect(round(x), round(y), imageSize.width, imageSize.height);
        layer.frame = rect;
        layer.contents = (__bridge id _Nullable)[self.image CGImageForProposedRect:&rect context:nil hints:nil];
        layer;
    });
    [self.layer addSublayer:self.imageLayer];
}

- (void)setupTitleLayer {
    // Ignore title layer if has no title or imagePosition equal to NSImageOnly
    if (!self.title || self.imagePosition == NSImageOnly) {
        [self.titleLayer removeFromSuperlayer];
        return;
    }
    
    CGSize buttonSize = self.frame.size;
    CGSize imageSize = self.image.size;
    CGSize titleSize = [self.title sizeWithAttributes:@{NSFontAttributeName: self.font}];
    CGFloat x = 0.0; // Title's origin x
    CGFloat y = 0.0; // Title's origin y
	
	// check if this font needs a specific fix to be centered vertically
	// (some fonts display too much white space above or below the text)
	if ([self.fontFamilyNameToYOffsetMap objectForKey:self.font.familyName] != nil) {
		NSNumber *yOffset = self.fontFamilyNameToYOffsetMap[self.font.familyName];
		titleSize.height += yOffset.floatValue;
	}

    // Caculate the image's and title's position depends on button's imagePosition and imageHugsTitle property
    NSCellImagePosition effectiveImagePosition = [self effectiveImagePositionFrom:self.imagePosition];
    BOOL effectiveImageHugsTitle = NO;
    if (@available(macOS 10.12, *)) {
        effectiveImageHugsTitle = self.imageHugsTitle;
    }
    
    switch (effectiveImagePosition) {
        case NSImageOnly: {
            return;
            break;
        }
        case NSNoImage: {
            x = (buttonSize.width - titleSize.width) / 2.0;
            y = (buttonSize.height - titleSize.height) / 2.0;
            break;
        }
        case NSImageOverlaps: {
            x = (buttonSize.width - titleSize.width) / 2.0;
            y = (buttonSize.height - titleSize.height) / 2.0;
            break;
        }
        case NSImageLeading:
        case NSImageLeft: {
            x = effectiveImagePosition ? ((buttonSize.width + imageSize.width - titleSize.width) / 2.0 + self.spacing) : (buttonSize.width - titleSize.width - self.spacing);
            y = (buttonSize.height - titleSize.height) / 2.0;
            break;
        }
        case NSImageTrailing:
        case NSImageRight: {
            x = effectiveImagePosition ? ((buttonSize.width - imageSize.width - titleSize.width) / 2.0 - self.spacing) : self.spacing;
            y = (buttonSize.height - titleSize.height) / 2.0;
            break;
        }
        case NSImageAbove: {
            x = (buttonSize.width - titleSize.width) / 2.0;
            y = effectiveImagePosition ? ((buttonSize.height + imageSize.height - titleSize.height) / 2.0 + self.spacing) : (buttonSize.height - titleSize.height - self.spacing);
            break;
        }
        case NSImageBelow: {
            y = effectiveImagePosition ? ((buttonSize.height - imageSize.height - titleSize.height) / 2.0 - self.spacing) : self.spacing;
            x = (buttonSize.width - titleSize.width) / 2.0;
            break;
        }
        default: {
            break;
        }
    }
    
    // Setup title layer
    self.titleLayer.frame = NSMakeRect(round(x), round(y), ceil(titleSize.width), ceil(titleSize.height));
    self.titleLayer.string = self.title;
    self.titleLayer.font = (__bridge CFTypeRef _Nullable)(self.font);
    self.titleLayer.fontSize = self.font.pointSize;
	self.titleLayer.contentsScale = NSScreen.mainScreen.backingScaleFactor; // this is necessary so the text isn't blurry
	
    [self.layer addSublayer:self.titleLayer];
}

#pragma mark - Animation method

- (void)removeAllAnimations {
    [self.layer removeAllAnimations];
    [self.layer.sublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull layer, NSUInteger index, BOOL * _Nonnull stop) {
        [layer removeAllAnimations];
    }];
}

- (void)animateColorForCurrentState {
    [self removeAllAnimations];
    CGFloat duration = (self.state == NSOnState) ? self.onAnimateDuration : self.offAnimateDuration;
    
	NSColor *borderColor = (self.isEnabled == NO) ? self.borderDisabledColor : (self.state == NSOnState) ? self.borderHighlightColor : self.borderNormalColor;
    NSColor *backgroundColor = (self.isEnabled == NO) ? self.backgroundDisabledColor : (self.state == NSOnState) ? self.backgroundHighlightColor : self.backgroundNormalColor;
    NSColor *titleColor = (self.isEnabled == NO) ? self.titleDisabledColor : (self.state == NSOnState) ? self.titleHighlightColor : self.titleNormalColor;
    NSColor *imageColor = (self.isEnabled == NO) ? self.imageDisabledColor : (self.state == NSOnState) ? self.imageHighlightColor : self.imageNormalColor;
    [self animateLayer:self.layer color:borderColor keyPath:@"borderColor" duration:duration];
    [self animateLayer:self.layer color:backgroundColor keyPath:@"backgroundColor" duration:duration];
    [self animateLayer:self.imageLayer color:imageColor keyPath:@"backgroundColor" duration:duration];
    [self animateLayer:self.titleLayer color:titleColor keyPath:@"foregroundColor" duration:duration];
}

- (void)animateLayer:(CALayer *)layer color:(NSColor *)color keyPath:(NSString *)keyPath duration:(CGFloat)duration {
    CGColorRef oldColor = (__bridge CGColorRef)([layer valueForKeyPath:keyPath]);
    if (!(CGColorEqualToColor(oldColor, color.CGColor))) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
        animation.fromValue = [layer valueForKeyPath:keyPath];
        animation.toValue = (id)color.CGColor;
        animation.duration = duration;
        animation.removedOnCompletion = NO;
        [layer addAnimation:animation forKey:keyPath];
        [layer setValue:(id)color.CGColor forKey:keyPath];
    }
}

#pragma mark - Event Response

- (NSView *)hitTest:(NSPoint)point {
    return self.isEnabled ? [super hitTest:point] : nil;
}

- (void)mouseDown:(NSEvent *)event {
    if (self.isEnabled) {
        self.mouseDown = YES;
        self.state = (self.state == NSOnState) ? NSOffState : NSOnState;
    }
}

- (void)mouseEntered:(NSEvent *)event {
    if (self.mouseDown) {
        self.state = (self.state == NSOnState) ? NSOffState : NSOnState;
    }
}

- (void)mouseExited:(NSEvent *)event {
    if (self.mouseDown) {
        self.mouseDown = NO;
        self.state = (self.state == NSOnState) ? NSOffState : NSOnState;
    }
}

- (void)mouseUp:(NSEvent *)event {
    if (self.mouseDown) {
        self.mouseDown = NO;
        if (self.momentary) {
            self.state = (self.state == NSOnState) ? NSOffState : NSOnState;
        }
//        [NSApp sendAction:self.action to:self.target from:self];
        NSPoint eventLocation = [event locationInWindow];
        NSPoint point = [self convertPoint:eventLocation fromView:nil];
        if (NSPointInRect(point, self.bounds)) {
            [NSApp sendAction:self.action to:self.target from:self];
        }
    }
}

#pragma mark - Property method

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [self setupTitleLayer];
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    [self setupTitleLayer];
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    [self setupTitleLayer];
}

- (void)setImage:(NSImage *)image {
    [super setImage:image];
    [self setupImageLayer];
}

- (void)setState:(NSInteger)state {
    [super setState:state];
	[self animateColorForCurrentState];
}

- (void)setImagePosition:(NSCellImagePosition)imagePosition {
    [super setImagePosition:imagePosition];
    [self setupImageLayer];
    [self setupTitleLayer];
}

- (void)setMomentary:(BOOL)momentary {
    _momentary = momentary;
    [self animateColorForCurrentState];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = _cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.layer.borderWidth = _borderWidth;
}

- (void)setSpacing:(CGFloat)spacing {
    _spacing = spacing;
    [self setupImageLayer];
    [self setupTitleLayer];
}

- (void)setBorderNormalColor:(NSColor *)borderNormalColor {
    _borderNormalColor = borderNormalColor;
    [self animateColorForCurrentState];
}

- (void)setBorderHighlightColor:(NSColor *)borderHighlightColor {
    _borderHighlightColor = borderHighlightColor;
    [self animateColorForCurrentState];
}

- (void)setBorderDisabledColor:(NSColor *)borderDisabledColor {
	_borderDisabledColor = borderDisabledColor;
	[self animateColorForCurrentState];
}

- (void)setBackgroundNormalColor:(NSColor *)backgroundNormalColor {
    _backgroundNormalColor = backgroundNormalColor;
    [self animateColorForCurrentState];
}

- (void)setBackgroundHighlightColor:(NSColor *)backgroundHighlightColor {
    _backgroundHighlightColor = backgroundHighlightColor;
    [self animateColorForCurrentState];
}

- (void)setBackgroundDisabledColor:(NSColor *)backgroundDisabledColor {
	_backgroundDisabledColor = backgroundDisabledColor;
	[self animateColorForCurrentState];
}

- (void)setImageNormalColor:(NSColor *)imageNormalColor {
    _imageNormalColor = imageNormalColor;
    [self animateColorForCurrentState];
}

- (void)setImageHighlightColor:(NSColor *)imageHighlightColor {
    _imageHighlightColor = imageHighlightColor;
    [self animateColorForCurrentState];
}

- (void)setImageDisabledColor:(NSColor *)imageDisabledColor {
	_imageDisabledColor = imageDisabledColor;
	[self animateColorForCurrentState];
}

- (void)setTitleNormalColor:(NSColor *)titleNormalColor {
    _titleNormalColor = titleNormalColor;
    [self animateColorForCurrentState];
}

- (void)setTitleHighlightColor:(NSColor *)titleHighlightColor {
    _titleHighlightColor = titleHighlightColor;
    [self animateColorForCurrentState];
}

- (void)setTitleDisabledColor:(NSColor *)titleDisabledColor {
	_titleDisabledColor = titleDisabledColor;
	[self animateColorForCurrentState];
}

- (void)setEnabled:(BOOL)enabled {
	super.enabled = enabled;
	[self animateColorForCurrentState];
}

- (CAShapeLayer *)imageLayer {
    if (_imageLayer == nil) {
        _imageLayer = [[CAShapeLayer alloc] init];
        _imageLayer.delegate = self;
    }
    return _imageLayer;
}

- (CATextLayer *)titleLayer {
    if (_titleLayer == nil) {
        _titleLayer = [[CATextLayer alloc] init];
        _titleLayer.delegate = self;
    }
    return _titleLayer;
}

#pragma mark - Helper Methods

- (NSCellImagePosition)effectiveImagePositionFrom:(NSCellImagePosition) originalImagePosition {
    
    NSCellImagePosition effectiveImagePosition = originalImagePosition;
    
    if (@available(macOS 10.12, *)) {
        switch(originalImagePosition) {
            case NSImageTrailing:
                effectiveImagePosition = NSImageRight;
                break;
            case NSImageLeading:
                effectiveImagePosition = NSImageLeft;
                break;
            default:
                //no mapping needed
                break;
        }
    }
    return effectiveImagePosition;
}

@end
