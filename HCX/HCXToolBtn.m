//
//  HCXToolBtn.m
//  HCX
//
//  Created by pgo on 2013/04/21.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXToolBtn.h"
#import "HCXDoMenu.h"
#import "HCXToolPanel.h"

@implementation HCXToolBtn

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTarget:self];
        [self setBezelStyle:NSThickSquareBezelStyle];
        [self setButtonType:NSOnOffButton];
        [self setAction:@selector(btnAction:)];
    }
    
    return self;
}

- (void) setHighlight: (NSInteger) state
{
    [super setState:state];
    
    if(state==NSOnState){
        [HCXToolPanel clearAllHighlight:self];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if(self.state==NSOnState)
    {
        CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
        
        // 背景 塗り
        CGContextSetRGBFillColor(cgContext, 0.0, 0.5, 1.0, 0.05);
        CGContextFillRect(cgContext, dirtyRect);
    }
}

- (void)btnAction:(NSButton *)sender
{
    [self setHighlight:NSOnState];
    [HCXDoMenu sendMessageToCurCard:[NSString stringWithFormat:@"select %@ tool", sender.title] force:YES];
}

@end
