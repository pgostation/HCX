//
//  HCXToolPanel.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXToolPanel.h"
#import "HCXToolPanelView.h"
#import "HCXToolBtn.h"
#import "StackEnv.h"

@implementation HCXToolPanel

static HCXToolPanel *panel;
static HCXToolPanelView *view;

+ (NSPanel *) getPanel
{
    return panel;
}

+ (void) clearAllHighlight: (HCXToolBtn *)sender
{
    NSArray *allViews = [view subviews];
    for(id x in allViews)
    {
        if( x == sender ) continue;
        if([x class] == [HCXToolBtn class])
        {
            HCXToolBtn *btn = x;
            [btn setState:NSOffState];
        }
    }
}

+ (void) selectTool: (NSString *)toolName
{
    [HCXToolPanel clearAllHighlight:nil];
    
    NSArray *allViews = [view subviews];
    for(id x in allViews)
    {
        if([x class] == [HCXToolBtn class])
        {
            HCXToolBtn *btn = x;
            if([btn.title isEqualToString:toolName]==YES)
            {
                [btn setHighlight:NSOnState];
            }
        }
    }
    
    [view changex:nil];
}

- (void) init2
{
    panel = self;
    
    [self setFloatingPanel:YES];
    [self setLevel:NSFloatingWindowLevel];
    
    //[self setTitle:@"Tools"];
    [self setDelegate:self];
    [self setReleasedWhenClosed:NO];
    [self setHidesOnDeactivate:YES];
    
    // 影が消えるので、付け直す
    [self setHasShadow:NO];
    [self setHasShadow:YES];
    
    // 最小化とズームボタンは不要なので隠す
    [[self standardWindowButton:NSWindowMiniaturizeButton] setFrame:NSZeroRect];
    [[self standardWindowButton:NSWindowZoomButton] setFrame:NSZeroRect];
    
    view = [[HCXToolPanelView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    [self setContentView:view];
    [view setWantsLayer:YES];
}

- (void) change: (StackEnv *) stackEnv
{
    [view changex:stackEnv];
}


@end
