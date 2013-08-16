//
//  HCXUIButton.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "HCXUIButton.h"
#import "HCXButton.h"
#import "HCXStackData.h"
#import "HCXUIPopup.h"
#import "StackEnv.h"
#import "HCXAuthoringPanel.h"
#import "HCXPart.h"

@implementation HCXUIButton
{
    BOOL isBg;
    NSInteger stackEnvId;
    BOOL highlight;
    BOOL autoHighlight;
    BOOL visible;
    NSInteger btnStyle;
    
    int dirLR;
    int dirUD;
    NSPoint lastMouse;
    
    NSAttributedString *titleWithIcon;
}

static BOOL isDrawBorder = NO;
static BOOL isDrawHover = NO;
static NSInteger selectedButtonId;

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
    if(btnData.highlight==YES)
    {
        highlight = YES;
        [self setState:NSOnState];
    }
    
    {
        autoHighlight = btnData.autoHighlight;
    }
    if(btnData.icon==0)
    {
    }
    else
    {
        //NSString *picPath = [stack getRsrcFilePath:@"icon" rsrcid:btnData.icon];
        NSString *picPath = [stack.dirPath stringByAppendingFormat:@"/ICON_%ld.png", btnData.icon];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:picPath];
        [self setImage:image];
    }
    if(btnData.visible==YES)
    {
        visible = YES;
    }
    {
        btnStyle = btnData.style;
        switch(btnStyle)
        {
            case 0: //standard
                if(self.frame.size.height<20)
                {
                    [self setBezelStyle:NSRoundedBezelStyle];
                }
                else
                {
                    [self setBezelStyle:NSThickSquareBezelStyle];
                }
                break;
            case 1: //transparent
            case 2: //opaque
            case 3: //rectangle
                [self setBordered:NO];
                break;
            case 4: //shadow
                [self setBezelStyle:NSSmallSquareBezelStyle];
                break;
            case 5: //roundrect
                [self setBezelStyle:NSRegularSquareBezelStyle];
                break;
            case 6: //default
                if(self.frame.size.height<20)
                {
                    [self setBezelStyle:NSRoundedBezelStyle];
                }
                else
                {
                    [self setBezelStyle:NSThickSquareBezelStyle];
                }
                {
                    StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
                    [stackEnv.cardWindow setDefaultButtonCell:[self cell]];
                }
                break;
            case 7: //oval
                [self setBordered:NO];
                break;
            //case 8: //popup
                //break;
            case 9: //checkbox
                [self setButtonType:NSSwitchButton];
                break;
            case 10: //radio
                [self setButtonType:NSRadioButton];
                break;
        }
    }
    /* NSAttributedStringを使う場合はNSParagraphStyleを使う
    {
        if([btnData.textAlign isEqualToString:@"left"])
        {
            [self setAlignment:NSLeftTextAlignment];
        }
        else if([btnData.textAlign isEqualToString:@"center"])
        {
            [self setAlignment:NSCenterTextAlignment];
        }
        else if([btnData.textAlign isEqualToString:@"right"])
        {
            [self setAlignment:NSRightTextAlignment];
        }
    }
     */
    
    
    if(btnData.showName)
    {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        
        // 色の設定
        [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
        
        // アラインメントの設定
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        if([btnData.textAlign isEqualToString:@"left"])
        {
            [style setAlignment:NSLeftTextAlignment];
        }
        else if([btnData.textAlign isEqualToString:@"center"])
        {
            [style setAlignment:NSCenterTextAlignment];
        }
        else if([btnData.textAlign isEqualToString:@"right"])
        {
            [style setAlignment:NSRightTextAlignment];
        }
        [attributes setObject:style forKey:NSParagraphStyleAttributeName];
        
        // フォントの設定
        NSString *fontName = btnData.textFontName;
        if(fontName==nil)
        {
            if(stack.systemFontName==nil)
            {
                stack.systemFontName = [NSFont systemFontOfSize:10].familyName;
            }
            fontName = stack.systemFontName;
        }
        
        NSInteger fontStyleMask = 0;
        if(btnData.textStyle==0){}
        else{
            if((btnData.textStyle&1)>0) fontStyleMask += NSBoldFontMask;
            if((btnData.textStyle&2)>0) fontStyleMask += NSItalicFontMask;
        }
        
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *customFont = [fontManager fontWithFamily:fontName
                                                  traits:fontStyleMask
                                                  weight:5
                                                    size:btnData.textSize];
        if(customFont!=nil)
        {
            [attributes setObject:customFont forKey:NSFontAttributeName];
        }
        
        // ボタンにNSAttributedStringを設定
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:btnData.name attributes:attributes];
        
        if(btnData.icon==0 || btnData.icon==-1)
        {
            [self setAttributedTitle:attributedTitle];
            titleWithIcon = nil;
        }
        else{
            titleWithIcon = attributedTitle;
        }
    }
    else
    {
        [self setTitle:@""];
    }
}

- (BOOL) highlight
{
    return highlight;
}

- (void) setHighlightFromScript: (BOOL) b
{
    highlight = b;
    [self setNeedsDisplay];
}

+ (void) setDrawBorder: (BOOL) b
{
    isDrawBorder = b;
    if(!b){
        isDrawHover = false;
        selectedButtonId = 0;
    }
    
    [HCXUIPopup setDrawBorder:b];
}

+ (void) setHover: (BOOL) b
{
    isDrawHover = b;
    
    [HCXUIPopup setHover:b];
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
            CGContextStrokeRect(cgContext, self.bounds);
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount) ;
            CGContextStrokeRect(cgContext, self.bounds);
        }
        return;
    }
    
    if((btnStyle==1 || btnStyle==7) && self.isEnabled)
    {
        [super drawRect:dirtyRect];
        if(titleWithIcon!=nil) [self drawCustomTitle];
    }
    
    switch(btnStyle)
    {
        case 1: //transparent
        {
            // 背景 色反転
            if(highlight)
            {
                StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
                if(stackEnv.redrawFlag==NO)
                {
                    stackEnv.redrawFlag = YES; // 無限ループ防止
                    
                    CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
                    CGContextScaleCTM(cgContext, 1.0, -1.0);
                    
                    // 裏画面に描画
                    NSGraphicsContext* nsContext = [NSGraphicsContext
                                                  graphicsContextWithGraphicsPort:stackEnv.offBitmap
                                                  flipped:NO];
                    [stackEnv.cardView displayRectIgnoringOpacity:CGRectMake(self.frame.origin.x,self.frame.origin.y,dirtyRect.size.width,dirtyRect.size.height)/*CGRectMake(0,0,stackEnv.stack.width,stackEnv.stack.height)*/ inContext:nsContext];
                    
                    unsigned char *bitmap = CGBitmapContextGetData(stackEnv.offBitmap);
                    int i = self.frame.origin.y*stackEnv.stack.width*4;
                    int maxi = stackEnv.stack.width * (self.frame.origin.y+dirtyRect.size.height) * 4;
                    for(; i < maxi;){
                        bitmap[i] = 255 - bitmap[i];i++;
                        bitmap[i] = 255 - bitmap[i];i++;
                        bitmap[i] = 255 - bitmap[i];i++;
                        bitmap[i] = 255;i++;//255 - bitmap[i++];
                    }
                    
                    // 表画面に描画して、色反転
                    {
                        CGImageRef image = CGBitmapContextCreateImage(stackEnv.offBitmap);
                        CGContextDrawImage(cgContext, CGRectMake(-self.frame.origin.x,-stackEnv.stack.height+self.frame.origin.y,stackEnv.stack.width,stackEnv.stack.height), image);
                        CGImageRelease(image);
                        
                        //CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1.0);
                        //NSRectFillUsingOperation(dirtyRect, NSCompositeXOR);
                        //CGContextFillRect(cgContext, dirtyRect);
                    }
                    
                    stackEnv.redrawFlag = NO; // 無限ループ防止
                }
            }
        }
            break;
        case 2: //opaque
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            if(highlight)
            {
                CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            }
            else
            {
                CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            }
            CGContextFillRect(cgContext, dirtyRect);
        }
            break;
        case 3: //rectangle
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            if(highlight)
            {
                CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            }
            else
            {
                CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            }
            CGContextFillRect(cgContext, dirtyRect);
            
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextStrokeRect(cgContext, self.bounds);
        }
            break;
        case 7: //oval
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            if(highlight)
            {
                CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 1.0);
                CGContextFillEllipseInRect(cgContext, self.bounds);
            }
        }
            break;
        
        case 0:
        case 4:
        case 5:
        case 6:
            if(self.isEnabled==NO)
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 0.5);
            CGContextFillRect(cgContext, dirtyRect);
        }
            break;
    }
    
    if((btnStyle!=1 && btnStyle!=7) || !self.isEnabled)
    {
        [super drawRect:dirtyRect];
        if(titleWithIcon!=nil) [self drawCustomTitle];
    }
    
    if(isDrawBorder)
    {
        if(isDrawHover)
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSetRGBStrokeColor(cgContext, 1.0, 1.0, 1.0, 1.0);
            CGContextStrokeRect(cgContext, self.bounds);
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount);
            CGContextStrokeRect(cgContext, self.bounds);
        }
        else
        {
            if(selectedButtonId==self.partId)
            {
                //Frame
                CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
                CGContextSetRGBStrokeColor(cgContext, 1.0, 1.0, 1.0, 1.0);
                CGContextStrokeRect(cgContext, CGRectInset(self.bounds, 0.5, 0.5));
                CGContextSetRGBStrokeColor(cgContext, 0.0, 0.6, 1.0, 1.0);
                CGContextSetLineDash(cgContext, kDashedPhase, kDashedLinesLength, kDashedCount);
                CGContextStrokeRect(cgContext, CGRectInset(self.bounds, 0.5, 0.5));
            }
            else
            {
                CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
                CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
                CGContextStrokeRect(cgContext, self.bounds);
            }
        }
    }
}

- (void) drawCustomTitle
{
    [titleWithIcon drawInRect:NSMakeRect(self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height/2 + [self image].size.height/2, self.bounds.size.width, self.bounds.size.height)];
}

- (void)mouseDown:(NSEvent*)event
{
    if(isDrawBorder)
    {
        // クリックしたボタンを選択
        StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
        if(selectedButtonId!=0)
        {
            NSArray *views = [stackEnv.cardView subviews];
            for(NSView *view in views)
            {
                if(view.class == self.class && ((HCXUIButton *)view).partId==selectedButtonId)
                {
                    [view setNeedsDisplay:YES];
                    break;
                }
            }
        }
        [HCXUIPopup clearSelectedButton];
        selectedButtonId = self.partId;
        [self setNeedsDisplay:YES];
        
        // 移動するか大きさ変更するか
        [self mouseEntered:nil];
        NSPoint mouse = [NSEvent mouseLocation];
        lastMouse = mouse;
        //mouse = convMousePoint(&mouse, stackEnv.cardWindow.frame.size.height);
        
        dirLR = 0; dirUD = 0;
        if(mouse.x-stackEnv.cardWindow.frame.origin.x<self.frame.origin.x+4) dirLR = -1;
        if(mouse.x-stackEnv.cardWindow.frame.origin.x>self.frame.origin.x+self.frame.size.width-4) dirLR = 1;
        if(stackEnv.cardWindow.frame.size.height-(mouse.y-stackEnv.cardWindow.frame.origin.y)-22<self.frame.origin.y+4) dirUD = -1;
        if(stackEnv.cardWindow.frame.size.height-(mouse.y-stackEnv.cardWindow.frame.origin.y)-22>self.frame.origin.y+self.frame.size.height-4) dirUD = 1;
        NSLog(@"mouse.y=%f window.origin.y=%f window.height=%f", mouse.y, stackEnv.cardWindow.frame.origin.y, stackEnv.cardWindow.frame.size.height);
        NSLog(@"ori=%f hei=%f", self.frame.origin.y, self.frame.size.height);
        
        //if(selectedButtonId==self.partId)
        {
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
            
            [stackEnv.cardWindow makeKeyAndOrderFront:nil];
        }
        
        return;
    }
    
    if(autoHighlight){
        switch(btnStyle)
        {
            case 0:
            case 4:
            case 5:
            case 6:
            case 9:
            case 10:
                [super mouseDown:event];
        }
        highlight = YES;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseUp:(NSEvent*)event
{
    if(autoHighlight){
        switch(btnStyle)
        {
            case 0:
            case 4:
            case 5:
            case 6:
            case 9:
            case 10:
                [super mouseUp:event];
        }
        highlight = NO;
        [self setNeedsDisplay:YES];
    }
    
    if(isDrawBorder)
    {
        StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
        HCXButton *object;
        
        {
            HCXCardBase *cardbase = [stackEnv.stack getCardById:[stackEnv getCurrentCardId]];
            if(isBg)
            {
                cardbase = [stackEnv.stack getBgById:((HCXCard*)cardbase).bgId];
            }
            object = (HCXButton*)[cardbase getPartById:self.partId];
            
            object.left = self.frame.origin.x;
            object.top = self.frame.origin.y;
            object.width = self.frame.size.width;
            object.height = self.frame.size.height;
        }
        [stackEnv setChangeFlag:YES];
        //[stackEnv sendMessageToCurCard: @"go this card" force:YES];
        
        [self setCursorArea:event];
    }
}

- (void)mouseDragged:(NSEvent*)event
{
    NSLog(@"mouseDragged¥n");
    
    if(isDrawBorder)
    {
        NSPoint mouse = [NSEvent mouseLocation];
        int mvX = mouse.x - lastMouse.x;
        int mvY = mouse.y - lastMouse.y;
        
        if(dirLR==0 && dirUD==0)
        {
            self.frame = NSMakeRect(self.frame.origin.x+mvX,self.frame.origin.y-mvY,self.frame.size.width,self.frame.size.height);
        }
        else{
            if(dirLR==-1)
            {
                self.frame = NSMakeRect(self.frame.origin.x+mvX,self.frame.origin.y,self.frame.size.width-mvX,self.frame.size.height);
            }
            else if(dirLR==1)
            {
                self.frame = NSMakeRect(self.frame.origin.x,self.frame.origin.y,self.frame.size.width+mvX,self.frame.size.height);
            }
            if(dirUD==-1)
            {
                self.frame = NSMakeRect(self.frame.origin.x,self.frame.origin.y-mvY,self.frame.size.width,self.frame.size.height+mvY);
            }
            else if(dirUD==1)
            {
                self.frame = NSMakeRect(self.frame.origin.x,self.frame.origin.y,self.frame.size.width,self.frame.size.height-mvY);
            }
        }
    
        lastMouse = mouse;
    }
}

- (void)viewDidMoveToWindow {
    /*NSTrackingRectTag tag =*/ [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)mouseEntered:(NSEvent*)event
{
    NSLog(@"mouseEntered¥n");
    StackEnv *stackEnv = [StackEnv currentStackEnv];
    [self setFocusRingType:NSFocusRingTypeNone];
    [[stackEnv cardWindow] makeFirstResponder:self];
    [[stackEnv cardWindow] setAcceptsMouseMovedEvents:YES];
    if(isDrawBorder)
    {
        if(isDrawHover)
        {
        }
        else
        {
            [self setCursorArea:event];
        }
    }
}

- (void)mouseExited:(NSEvent*)event
{
    NSLog(@"mouseExited¥n");
}

- (void)mouseMoved:(NSEvent*)event
{
    //NSLog(@"mouseMoved¥n");
}

- (void)setCursorArea:(NSEvent*)event
{
    [self discardCursorRects];
    int w = self.bounds.size.width;
    int h = self.bounds.size.height;
    [self addCursorRect:NSMakeRect(0, 0, 4, 4) cursor:[NSCursor crosshairCursor]];
    [self addCursorRect:NSMakeRect(w-4, 0, 4, 4) cursor:[NSCursor crosshairCursor]];
    [self addCursorRect:NSMakeRect(0, h-4, 4, 4) cursor:[NSCursor crosshairCursor]];
    [self addCursorRect:NSMakeRect(w-4, h-4, 4, 4) cursor:[NSCursor crosshairCursor]];
    [self addCursorRect:NSMakeRect(0, 0, 4, h) cursor:[NSCursor resizeLeftCursor]];
    [self addCursorRect:NSMakeRect(w-4, 0, 4, h) cursor:[NSCursor resizeRightCursor]];
    [self addCursorRect:NSMakeRect(0, 0, w, 4) cursor:[NSCursor resizeUpCursor]];
    [self addCursorRect:NSMakeRect(0, h-4, w, 4) cursor:[NSCursor resizeDownCursor]];
    [self addCursorRect:NSMakeRect(0, 0, w, h) cursor:[NSCursor openHandCursor]];
}

@end
