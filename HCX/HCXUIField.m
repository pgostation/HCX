//
//  HCXUIField.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXUIField.h"
#import "HCXField.h"
#import "HCXStackData.h"
#import "StackEnv.h"
#import "HCXAuthoringPanel.h"

@implementation HCXUIField
{
    BOOL isBg;
    NSInteger stackEnvId;
    BOOL visible;
    NSInteger fldStyle;
}

static BOOL isDrawBorder = NO;
static BOOL isDrawHover = NO;
static NSInteger selectedFieldId;

- (void) setStackEnv: (NSInteger)in_stackEnvId
{
    stackEnvId = in_stackEnvId;
}

- (void) setStyle: (HCXField *)fldData stack:(HCXStackData *)stack isBg:(BOOL) in_isBg
{
    isBg = in_isBg;
    self.partId = fldData.pid;
    
    visible = fldData.visible;
    
    {
        fldStyle = fldData.style;
        switch(fldStyle)
        {
            case 1: //transparent
                [self setDrawsBackground:NO];
                break;
        }
    }
    
    if([fldData.text length]>0)
    {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        
        // 色の設定
        [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
        
        // アラインメントの設定
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        if([fldData.textAlign isEqualToString:@"left"])
        {
            [style setAlignment:NSLeftTextAlignment];
        }
        else if([fldData.textAlign isEqualToString:@"center"])
        {
            [style setAlignment:NSCenterTextAlignment];
        }
        else if([fldData.textAlign isEqualToString:@"right"])
        {
            [style setAlignment:NSRightTextAlignment];
        }
        [attributes setObject:style forKey:NSParagraphStyleAttributeName];
        
        // フォントの設定
        NSString *fontName = fldData.textFontName;
        if(fontName==nil)
        {
            if(stack.systemFontName==nil)
            {
                stack.systemFontName = [NSFont systemFontOfSize:10].familyName;
            }
            fontName = stack.systemFontName;
        }
        
        NSInteger fontStyleMask = 0;
        if(fldData.textStyle==0){}
        else{
            if((fldData.textStyle&1)>0) fontStyleMask += NSBoldFontMask;
            if((fldData.textStyle&2)>0) fontStyleMask += NSItalicFontMask;
        }
        
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *customFont = [fontManager fontWithFamily:fontName
                                                  traits:fontStyleMask
                                                  weight:5
                                                    size:fldData.textSize];
        if(customFont!=nil)
        {
            [attributes setObject:customFont forKey:NSFontAttributeName];
        }
        
        // フィールドにNSAttributedStringを設定
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:fldData.text attributes:attributes];
        [[self textStorage] setAttributedString:attributedText];
    }
}

+ (void) setDrawBorder: (BOOL) b
{
    isDrawBorder = b;
    if(!b){
        isDrawHover = false;
    }
}

+ (void) setHover: (BOOL) b
{
    isDrawHover = b;
}

+ (void) clearSelectedField
{
    if(selectedFieldId!=0)
    {
        //[selectedButton setNeedsDisplay];
        selectedFieldId = 0;
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
            CGContextStrokeRect(cgContext, dirtyRect);
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount) ;
            CGContextStrokeRect(cgContext, dirtyRect);
        }
        return;
    }
    
    {
        [super drawRect:dirtyRect];
    }
    
    switch(fldStyle)
    {
        case 1: //transparent
            break;
        case 2: //opaque
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(cgContext, dirtyRect);
        }
            break;
        case 3: //rectangle
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(cgContext, dirtyRect);
            // 枠
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.6);
            CGContextStrokeRect(cgContext, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
            // 内側シャドウ
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.15);
            CGContextStrokeRect(cgContext, CGRectMake(1, 1, self.frame.size.width-1, self.frame.size.height-1));
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.08);
            CGContextStrokeRect(cgContext, CGRectMake(2, 2, self.frame.size.width-3, self.frame.size.height-3));
        }
            break;
        case 4: //shadow
        {
            /*NSShadow *shadow = [[NSShadow alloc] init];
            [shadow setShadowOffset:NSMakeSize(3.0, -3.0)];
            [shadow setShadowBlurRadius:3.0];
            [shadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.3]];
            [shadow set];
            
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(cgContext, dirtyRect);
            // 枠
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.6);
            CGContextStrokeRect(cgContext, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
            // 内側シャドウ
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.15);
            CGContextStrokeRect(cgContext, CGRectMake(1, 1, self.frame.size.width-1, self.frame.size.height-1));
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.08);
            CGContextStrokeRect(cgContext, CGRectMake(2, 2, self.frame.size.width-3, self.frame.size.height-3));*/
            
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(cgContext, CGRectMake(0, 0, self.frame.size.width-2, self.frame.size.height-2));
            // 枠
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.4);
            CGContextStrokeRect(cgContext, CGRectMake(0.5, 0.5, self.frame.size.width-3, self.frame.size.height-3));
            // 内側シャドウ
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.15);
            CGContextStrokeRect(cgContext, CGRectMake(1, 1, self.frame.size.width-2-1, self.frame.size.height-2-1));
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.08);
            CGContextStrokeRect(cgContext, CGRectMake(2, 2, self.frame.size.width-2-3, self.frame.size.height-2-3));
            // 外側シャドウ(下)
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.2);
            CGContextStrokeRect(cgContext, CGRectMake(3, self.frame.size.height-1, self.frame.size.width-4, 1));
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.1);
            CGContextStrokeRect(cgContext, CGRectMake(3, self.frame.size.height, self.frame.size.width-4, 1));
            // 外側シャドウ(右)
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.2);
            CGContextStrokeRect(cgContext, CGRectMake(self.frame.size.width-1, 3, 1, self.frame.size.height-5));
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.1);
            CGContextStrokeRect(cgContext, CGRectMake(self.frame.size.width, 3, 1, self.frame.size.height-5));
        }
            break;
        case 5: //scroll
            break;
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
            if(selectedFieldId==self.partId)
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
        // クリックしたフィールドを選択
        if(selectedFieldId!=0)
        {
            StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
            NSArray *views = [stackEnv.cardView subviews];
            for(NSView *view in views)
            {
                if(view.class == self.class && ((HCXUIField *)view).partId==selectedFieldId)
                {
                    [view setNeedsDisplay:YES];
                    break;
                }
            }
        }
        selectedFieldId = self.partId;
        [self setNeedsDisplay:YES];
        
        // オーサリングパネルにフィールド情報を設定
        StackEnv *stackEnv = [StackEnv currentStackEnv];
        NSInteger cardid = [stackEnv getCurrentCardId];
        HCXCardBase *cardData = [stackEnv.stack getCardById:cardid];
        if(isBg)
        {
            cardData = [stackEnv.stack getBgById:((HCXCard *)cardData).bgId];
        }
        HCXPart *fldData = [cardData getPartById:self.partId];
        [HCXAuthoringPanel setData:fldData];
        
        return;
    }
    [super mouseDown:event];
}

- (void)mouseUp:(NSEvent*)event
{
    [super mouseUp:event];
    NSLog(@"mouseUp¥n");
}

- (void)mouseDragged:(NSEvent*)event
{
    NSLog(@"mouseDragged¥n");
}

@end
