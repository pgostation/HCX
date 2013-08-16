//
//  HCXDraggableToolBtn.m
//  HCX
//
//  Created by pgo on 2013/04/21.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXDraggableToolBtn.h"
#import "HCXInternational.h"
#import "HCXToolPanel.h"
#import "StackEnv.h"
#import "HCXButton.h"
#import "HCXField.h"
#import "HCXDoMenu.h"

@implementation HCXDraggableToolBtn
{
    NSInteger style;
}

static NSPanel *dragWindow;


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setState:NSOnState];
        [[self cell] setControlSize:NSMiniControlSize];
    }
    
    return self;
}

- (void) setStyle: (NSInteger) in_style
{
    style = in_style;
    switch(style)
    {
        case 0: //standard
            [self setBezelStyle:NSRoundedBezelStyle];
            break;
        case 1: //transparent
        case 11: //transparent
        case 2: //opaque
        case 12: //opaque
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
            [self setBezelStyle:NSRoundedBezelStyle];
            {
                [[HCXToolPanel getPanel] setDefaultButtonCell:[self cell]];
            }
            break;
        case 7: //oval
            [self setBordered:NO];
            break;
        case 8: //popup
            [self setBezelStyle:NSSmallSquareBezelStyle];
            break;
        case 9: //checkbox
            [self setButtonType:NSSwitchButton];
            [[self cell] setControlSize:NSRegularControlSize];
            break;
        case 10: //radio
            [self setButtonType:NSRadioButton];
            [[self cell] setControlSize:NSRegularControlSize];
            break;
        case 13: //rectangle field
            [self setBordered:NO];
            break;
        case 14: //shadow field
            [self setBordered:NO];
            break;
        case 15: //scrolling field
            [self setBordered:NO];
            break;
    }
}


- (void)drawRect:(NSRect)dirtyRect
{
    switch(style)
    {
        case 1: //transparent
        case 11: //transparent
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 枠
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.7, 1.0, 0.5);
            CGContextStrokeRect(cgContext, dirtyRect);
        }
            break;
        case 2: //opaque
        case 12: //opaque
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
            
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 1.0);
            CGContextStrokeRect(cgContext, dirtyRect);
        }
            break;
        case 7: //oval
        {
            CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
            
            // 背景 塗り
            CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 0.4);
            CGContextFillEllipseInRect(cgContext, dirtyRect);
        }
            break;
        case 13: //rectangle field
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
        case 14: //shadow field
        {
            /*NSShadow *shadow = [[NSShadow alloc] init];
            [shadow setShadowOffset:NSMakeSize(3.0, -3.0)];
            [shadow setShadowBlurRadius:3.0];
            [shadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.3]];
            [shadow set];*/
            
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
        case 15: //scrolling field
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
            // スクロール
            CGContextSetRGBStrokeColor(cgContext, 0.0, 0.0, 0.0, 0.4);
            CGContextStrokeRect(cgContext, CGRectMake(self.frame.size.width-16.5, 0, 0, self.frame.size.height));
            CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 0.1);
            CGContextFillRect(cgContext, CGRectMake(self.frame.size.width-15.5, 0, 1, self.frame.size.height));
            CGContextSetRGBFillColor(cgContext, 0.0, 0.0, 0.0, 0.1);
            CGContextFillRect(cgContext, CGRectMake(self.frame.size.width-2.5, 0, 1, self.frame.size.height));
        }
            break;
    }
    
    [super drawRect:dirtyRect];
}

- (void)mouseDown:(NSEvent*)event
{
    NSLog(@"mouseDown");
    
    NSRect rect = NSMakeRect([NSEvent mouseLocation].x-48 , [NSEvent mouseLocation].y-12, 96, 24);
    if(dragWindow==nil)
    {
        dragWindow = [[NSPanel alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:NO];
        [dragWindow setFloatingPanel:YES];
        [dragWindow setLevel:NSFloatingWindowLevel];
        //[dragWindow setBackgroundColor:[NSColor clearColor]];
        //[dragWindow setOpaque:NO];
        [dragWindow setAlphaValue:0.6];
    }
    
    HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:NSMakeRect(0, 0, rect.size.width, rect.size.height)];
    [btn setStyle:style];
    [btn setTitle:self.title];
    [btn setWantsLayer:YES];
    [btn setTag:-1];
    [btn setAlignment:self.alignment];
    [dragWindow setContentView:btn];
    
    [dragWindow setFrame:rect display:YES];
    [dragWindow makeKeyAndOrderFront:self];
}

- (void)mouseUp:(NSEvent*)event
{
    if(self.tag==-1){
        StackEnv *stackEnv = [StackEnv currentStackEnv];
        NSRect cardFrame = stackEnv.cardWindow.frame;
        NSPoint mouse = [NSEvent mouseLocation];
        if(CGRectContainsPoint(cardFrame, mouse))
        {
            // ボタン/フィールドを現在のカードに追加
            HCXStackData *stack = stackEnv.stack;
            NSInteger cardid = [stackEnv getCurrentCardId];
            HCXCardBase *cardbaseData = [stack getCardById:cardid];
            HCXCard *cardData = [stack getCardById:cardid];
            
            HCXPart *newPart;
            {
                if(style<11)
                {
                    newPart = [[HCXButton alloc] init];
                    newPart.style = style;
                    newPart.name = INTR(@"New Button",@"新規ボタン");
                    HCXButton *btn = (HCXButton *)newPart;
                    btn.enabled = true;
                    btn.autoHighlight = true;
                    btn.showName = true;
                    
                    newPart.left = mouse.x-cardFrame.origin.x-48;
                    newPart.top = cardFrame.size.height-20-(mouse.y-cardFrame.origin.y)-12;
                    newPart.width = 96;
                    newPart.height = 24;
                }
                else
                {
                    newPart = [[HCXField alloc] init];
                    newPart.style = style-10;
                    newPart.name = @"";
                    
                    newPart.left = mouse.x-cardFrame.origin.x-48;
                    newPart.top = cardFrame.size.height-20-(mouse.y-cardFrame.origin.y)-24;
                    newPart.width = 96;
                    newPart.height = 48;
                }
                newPart.pid = [cardbaseData nextPartId];
                newPart.text = @"";
                newPart.script = @"";
                newPart.visible = true;
                newPart.parentType = cardbaseData.objectType;
                newPart.parentId = cardbaseData.pid;
                if(cardbaseData.objectType==ENUM_BACKGROUND)
                {
                    newPart.cardIdOfContent = cardData.pid;
                }
                else
                {
                    newPart.cardIdOfContent = -1;
                }
                newPart.stackId = cardbaseData.parentStackId;
            }
            [cardData.partsList addObject:newPart];
        }
        [dragWindow setFrame:NSZeroRect display:NO];
        [HCXDoMenu sendMessageToCurCard:@"go this card" force:YES];
    }
}

- (void)mouseDragged:(NSEvent*)event
{
    if(self.tag==-1){
        NSRect rect = NSMakeRect([NSEvent mouseLocation].x-48 , [NSEvent mouseLocation].y-12, 96, 24);
        [dragWindow setFrame:rect display:NO];
    }
}

@end
