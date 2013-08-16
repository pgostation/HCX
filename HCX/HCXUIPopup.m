//
//  HCXUIPopup.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXUIPopup.h"
#import "HCXButton.h"
#import "HCXUIButton.h"
#import "HCXStackData.h"
#import "StackEnv.h"
#import "HCXAuthoringPanel.h"

@implementation HCXUIPopup
{
    NSInteger stackEnvId;
    BOOL isBg;
    BOOL visible;
}

static BOOL isDrawBorder = NO;
static BOOL isDrawHover = NO;
static NSInteger selectedButtonId;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) setStackEnv: (NSInteger)in_stackEnvId
{
    stackEnvId = in_stackEnvId;
}

- (void) setStyle: (HCXButton *)btnData stack:(HCXStackData *)stack isBg:(BOOL) in_isBg
{
    isBg = in_isBg;
    self.partId = btnData.pid;
    
    if(btnData.height<16)
    {
        [[self cell] setControlSize:NSMiniControlSize];
    }
    else if(btnData.height<20)
    {
        [[self cell] setControlSize:NSSmallControlSize];
    }
    else
    {
        [[self cell] setControlSize:NSRegularControlSize];
    }
    if(btnData.enabled==NO)
    {
        [self setEnabled:NO];
    }
    if(btnData.visible==YES)
    {
        visible = YES;
    }    
    
    if(btnData.showName)
    {
        [self setTitle:btnData.name];
    }
    else
    {
        [self setTitle:@""];
    }
}

- (BOOL) highlight
{
    return NO;//highlight;
}

- (void) setHighlightFromScript: (BOOL) b
{
}

+ (void) setDrawBorder: (BOOL) b
{
    isDrawBorder = b;
    if(!b){
        isDrawHover = false;
        selectedButtonId = 0;
    }
}

+ (void) setHover: (BOOL) b
{
    isDrawHover = b;
}

+ (void) clearSelectedButton
{
    if(selectedButtonId!=0)
    {
        //[selectedButton setNeedsDisplay];
        selectedButtonId = 0;
    }
}

static CGFloat const kDashedBorderWidth     = (2.0f);
static CGFloat const kDashedPhase           = (0.0f);
static CGFloat const kDashedLinesLength[]   = {4.0f, 2.0f};
static size_t const kDashedCount            = (2.0f);

- (void)drawRect:(NSRect)dirtyRect
{
    if(!visible){
        if(isDrawHover)
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetRGBStrokeColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextStrokeRect(cgContext, self.frame);
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount) ;
            CGContextStrokeRect(cgContext, self.frame);
        }
        return;
    }
    
    {
        [super drawRect:dirtyRect];
    }
    
    if(isDrawBorder)
    {
        if(isDrawHover)
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetRGBStrokeColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextStrokeRect(cgContext, self.frame);
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount) ;
            CGContextStrokeRect(cgContext, self.frame);
        }
        else
        {
            if(selectedButtonId==self.partId)
            {
                CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
                CGContextSetRGBStrokeColor(cgContext, 1.0, 1.0, 1.0, 1.0);
                CGContextStrokeRect(cgContext, CGRectInset(self.frame, 0.5, 0.5));
                CGContextSetRGBStrokeColor(cgContext, 0.0, 0.6, 1.0, 1.0);
                CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount);
                CGContextStrokeRect(cgContext, CGRectInset(self.frame, 0.5, 0.5));
            }
            else
            {
                CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
                CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
                CGContextStrokeRect(cgContext, self.frame);
            }
        }
    }
}

- (void)mouseDown:(NSEvent*)event
{
    if(isDrawBorder)
    {
        // クリックしたボタンを選択
        if(selectedButtonId!=0)
        {
            StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
            NSArray *views = [stackEnv.cardView subviews];
            for(NSView *view in views)
            {
                if(view.class == self.class && ((HCXUIPopup *)view).partId==selectedButtonId)
                {
                    [view setNeedsDisplay:YES];
                    break;
                }
            }
        }
        [HCXUIPopup clearSelectedButton];
        selectedButtonId = 0;
        [self setNeedsDisplay:YES];
        
        // オーサリングパネルにボタン情報を設定
        StackEnv *stackEnv = [StackEnv currentStackEnv];
        NSInteger cardid = [stackEnv getCurrentCardId];
        HCXCardBase *cardData = [stackEnv.stack getCardById:cardid];
        if(isBg)
        {
            cardData = [stackEnv.stack getBgById:((HCXCard *)cardData).bgId];
        }
        HCXPart *btnData = [cardData getPartById:self.partId];
        [HCXAuthoringPanel setData:btnData];
        
        return;
    }
}

- (void)mouseUp:(NSEvent*)event
{
}

- (void)mouseDragged:(NSEvent*)event
{
    NSLog(@"mouseDragged¥n");
}

@end
