//
//  HCXPictureView.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXPictureView.h"

@implementation HCXPictureView
{
    CGImageRef cdPict;
    NSSize cdPictSize;
}

- (HCXPictureView *)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) openPic: (NSString *) picPath
{
    if(cdPict != NULL){
        CGImageRelease(cdPict);
        cdPict = NULL;
    }
    
    NSImage *nsImage = [[NSImage alloc] initWithContentsOfFile:picPath];
    
    cdPict = xCGImageCreateWithNSImage(nsImage);
    
    cdPictSize = nsImage.size;
    [self setFrame:NSMakeRect(self.frame.origin.x, self.frame.origin.y, cdPictSize.width, cdPictSize.height)];
    
    [self setNeedsDisplay:YES];
}

static CGImageRef xCGImageCreateWithNSImage(NSImage *image)
{
    NSSize imageSize = [image size];
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapContext flipped:NO]];
    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    return cgImage;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
    
    // 背景 白
    //CGContextSetRGBFillColor(cgContext, 1.0,1.0,1.0,1.0);
    //CGContextFillRect(cgContext, dirtyRect);
    
    //CGContextScaleCTM(cgContext, 1.0, -1.0);
    
    // カードピクチャ
    CGContextDrawImage(cgContext, NSMakeRect(0,0,cdPictSize.width, cdPictSize.height), cdPict);
}

- (void)dealloc
{
    if(cdPict != NULL){
        CGImageRelease(cdPict);
        cdPict = NULL;
    }
    //[super dealloc]; //ARC AUTO
}

@end
