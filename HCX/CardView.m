//
//  CardView.m
//  HCX
//
//  Created by pgo on 2013/04/18.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "CardView.h"
#import "HCXPart.h"
#import "HCXPictureView.h"
#import "HCXUIButton.h"
#import "HCXUIPopup.h"
#import "HCXUIField.h"
#import "StackEnv.h"
#import "HCXAuthoringPanel.h"
#import "HCXScript.h"
#import "HCXDoMenu.h"

@implementation CardView

- (BOOL)isFlipped
{
    return YES;
}

- (void) openFirstCard: (StackEnv *) stackEnv
{
    [self openCard:stackEnv cardId:stackEnv.stack.firstCardID];
}

- (void) openCard: (StackEnv *) stackEnv cardId: (NSInteger) cardId
{
    HCXStackData *stack = stackEnv.stack;
    
    // 全てのsubviewを消しておく
    NSArray *viewsToRemove = [self subviews];
    for (NSView *v in [viewsToRemove reverseObjectEnumerator]) {
        [v removeFromSuperview];
    }
    
    [HCXUIButton clearSelectedButton];
    [HCXUIPopup clearSelectedButton];
    [HCXUIField clearSelectedField];
    
    HCXCard *cardData = [stack getCardById:cardId];
    
    {
        HCXBackground *bgData = [stack getBgById:cardData.bgId];
        
        // BG ピクチャ
        if(bgData.showPict)
        {
            NSString *picPath = [stack.dirPath stringByAppendingPathComponent:bgData.bitmapName];
            HCXPictureView *bgPicView = [[HCXPictureView alloc] initWithFrame:NSMakeRect(0,0,stack.width,stack.height)];
            [self addSubview:bgPicView];
            [bgPicView openPic:picPath];
        }
        
        // BG パーツ
        for(HCXPart *iterate_part in bgData.partsList)
        {
            HCXPart *part = [iterate_part loadContent:cardData];
            if(part.objectType == ENUM_BUTTON && part.style==8) //popup
            {
                HCXUIPopup *popup = [[HCXUIPopup alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [popup setStyle:(HCXButton *)part stack:stack isBg:YES];
                [popup setStackEnv:stackEnv.pid];
                [self addSubview:popup];
            }
            else if(part.objectType == ENUM_BUTTON)
            {
                HCXUIButton *uibtn = [[HCXUIButton alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [uibtn setStyle:(HCXButton *)part stack:stack isBg:YES];
                [uibtn setStackEnv:stackEnv.pid];
                [self addSubview:uibtn];
            }
            else if(part.objectType == ENUM_FIELD && part.style==5) //scrolling
            {
                NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [scrollView setHasVerticalScroller:YES];
                [scrollView setBorderType:NSBezelBorder];
                {
                    NSClipView *clipView = [[NSClipView alloc] initWithFrame:NSMakeRect(0,0,part.width-16,part.height)];
                    [scrollView setContentView:clipView];
                    
                    HCXUIField *uifld = [[HCXUIField alloc] initWithFrame:NSMakeRect(0,0,part.width-16,part.height+100)];
                    [uifld setStyle:(HCXField *)part stack:stack isBg:YES];
                    [scrollView setDocumentView:uifld];
                }
                [self addSubview:scrollView];
            }
            else if(part.objectType == ENUM_FIELD)
            {
                HCXUIField *uifld = [[HCXUIField alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [uifld setStyle:(HCXField *)part stack:stack isBg:YES];
                [self addSubview:uifld];
            }
        }
    }
    
    {
        // カードピクチャ
        if(cardData.showPict)
        {
            NSString *picPath = [stack.dirPath stringByAppendingPathComponent:cardData.bitmapName];
            HCXPictureView *cdPicView = [[HCXPictureView alloc] initWithFrame:NSMakeRect(0,0,stack.width,stack.height)];
            [self addSubview:cdPicView];
            [cdPicView openPic:picPath];
        }
    
        // カード パーツ
        for(HCXPart *part in cardData.partsList)
        {
            if(part.objectType == ENUM_BUTTON && part.style==8) //popup
            {
                HCXUIPopup *popup = [[HCXUIPopup alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [popup setStyle:(HCXButton *)part stack:stack isBg:NO];
                [popup setStackEnv:stackEnv.pid];
                [self addSubview:popup];
            }
            else if(part.objectType == ENUM_BUTTON)
            {
                HCXUIButton *uibtn = [[HCXUIButton alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [uibtn setStyle:(HCXButton *)part stack:stack isBg:NO];
                [uibtn setStackEnv:stackEnv.pid];
                [self addSubview:uibtn];
                
            }
            else if(part.objectType == ENUM_FIELD && part.style==5) //scrolling
            {
                NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [scrollView setHasVerticalScroller:YES];
                [scrollView setBorderType:NSBezelBorder];
                {
                    NSClipView *clipView = [[NSClipView alloc] initWithFrame:NSMakeRect(0,0,part.width-16,part.height)];
                    [scrollView setContentView:clipView];
                    
                    HCXUIField *uifld = [[HCXUIField alloc] initWithFrame:NSMakeRect(0,0,part.width-16,part.height+100)];
                    [uifld setStyle:(HCXField *)part stack:stack isBg:NO];
                    [scrollView setDocumentView:uifld];
                }
                [self addSubview:scrollView];
            }
            else if(part.objectType == ENUM_FIELD)
            {
                HCXUIField *uifld = [[HCXUIField alloc] initWithFrame:NSMakeRect(part.left,part.top,part.width,part.height)];
                [uifld setStyle:(HCXField *)part stack:stack isBg:NO];
                [self addSubview:uifld];
            }
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
    
    // 背景 白
    CGContextSetRGBFillColor(cgContext, 1.0,1.0,1.0,1.0);
    CGContextFillRect(cgContext, dirtyRect);
}

- (void)mouseDown:(NSEvent*)event
{
    NSString *selectedToolStr = [[HCXScript getGlobals] objectForKey:@"selectedtool"];
    if([selectedToolStr isEqualToString:@"button"] || [selectedToolStr isEqualToString:@"field"])
    {
        // オーサリングパネルにカード情報を設定
        StackEnv *stackEnv = [StackEnv currentStackEnv];
        NSInteger cardid = [stackEnv getCurrentCardId];
        HCXCardBase *cardData = [stackEnv.stack getCardById:cardid];
        /*if(isBg)
        {
            cardData = [stackEnv.stack getBgById:((HCXCard *)cardData).bgId];
        }*/
        [HCXAuthoringPanel setData:cardData];
        
        [HCXUIButton clearSelectedButton];
        [HCXUIPopup clearSelectedButton];
        [HCXUIField clearSelectedField];
        
        return;
    }
    
    [super mouseDown:event];
}

- (void)keyDown:(NSEvent *)theEvent
{
    StackEnv *stackEnv = [StackEnv currentStackEnv];
    
    switch( [theEvent keyCode] ) {
        case 126:       // up arrow
        case 125:       // down arrow
            NSLog(@"Arrow key pressed!");
            break;
        case 124:       // right arrow
            [stackEnv sendMessageToCurCard:@"go next" force:YES];
            break;
        case 123:       // left arrow
            [stackEnv sendMessageToCurCard:@"go prev" force:YES];
            break;
        default:
            NSLog(@"Key pressed: %@", theEvent);
            break;
    }
}

@end
