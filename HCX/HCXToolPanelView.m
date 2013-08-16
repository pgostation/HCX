//
//  HCXToolPanelView.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXToolPanelView.h"
#import "HCXToolBtn.h"
#import "StackEnv.h"
#import "HCXScript.h"
#import "HCXDraggableToolBtn.h"

@implementation HCXToolPanelView
{
    NSView *buttonView;
    NSView *fieldView;
    NSView *paintView;
    NSView *drawView;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        buttonView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height-64)];
        fieldView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height-64)];
        paintView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height-64)];
        drawView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height-64)];
        
        [self init2];
    }
    
    return self;
}

- (void) changex: (StackEnv *) stackEnv
{
    NSDictionary *dic = [HCXScript getGlobals];
    NSString *selectedToolName = [dic objectForKey:@"selectedtool"];
    
    // 下側の追加ビューの表示
    {
        [buttonView removeFromSuperview];
        [fieldView removeFromSuperview];
        [paintView removeFromSuperview];
        [drawView removeFromSuperview];
        
        if([selectedToolName isEqualToString:@"button"])
        {
            [self addSubview:buttonView];
        }
        if([selectedToolName isEqualToString:@"field"])
        {
            [self addSubview:fieldView];
        }
        if([selectedToolName isEqualToString:@"paint"])
        {
            [self addSubview:paintView];
        }
        if([selectedToolName isEqualToString:@"draw"])
        {
            [self addSubview:drawView];
        }
    }
    
    // ドラッグアンドドロップの受付
    /*if([selectedToolName isEqualToString:@"button"])
    {
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
    }
    else if([selectedToolName isEqualToString:@"field"])
    {
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
     } else */
    if([selectedToolName isEqualToString:@"paint"])
    {
        [self registerForDraggedTypes:[NSImage imagePasteboardTypes]];
    }
    else if([selectedToolName isEqualToString:@"draw"])
    {
        [self registerForDraggedTypes:[NSImage imagePasteboardTypes]];
    }
    else
    {
        [self registerForDraggedTypes:[[NSArray alloc] init]];
    }
    
}

- (void) init2
{
    {
        HCXToolBtn *btn = [[HCXToolBtn alloc] initWithFrame:convRect(self.frame,0,0,32,32)];
        [btn setTitle:@"browse"];
        [btn setToolTip:@"Browse"];
        [btn setImage:[NSImage imageNamed:@"tb_Browse.png"]];
        [self addSubview:btn];
        
        [btn setState:NSOnState];
    }
    {
        HCXToolBtn *btn = [[HCXToolBtn alloc] initWithFrame:convRect(self.frame,32,0,32,32)];
        [btn setTitle:@"button"];
        [btn setToolTip:@"Button"];
        [btn setImage:[NSImage imageNamed:@"tb_Button.png"]];
        [self addSubview:btn];
    }
    {
        HCXToolBtn *btn = [[HCXToolBtn alloc] initWithFrame:convRect(self.frame,64,0,32,32)];
        [btn setTitle:@"field"];
        [btn setToolTip:@"Field"];
        [btn setImage:[NSImage imageNamed:@"tb_Field.png"]];
        [self addSubview:btn];
    }
    {
        HCXToolBtn *btn = [[HCXToolBtn alloc] initWithFrame:convRect(self.frame,0,32,32,32)];
        [btn setTitle:@"paint"];
        [btn setToolTip:@"Paint"];
        [btn setImage:[NSImage imageNamed:@"tb_Brush.png"]];
        [self addSubview:btn];
    }
    {
        HCXToolBtn *btn = [[HCXToolBtn alloc] initWithFrame:convRect(self.frame,32,32,32,32)];
        [btn setTitle:@"draw"];
        [btn setToolTip:@"Draw"];
        [btn setImage:[NSImage imageNamed:@"tb_Line.png"]];
        [self addSubview:btn];
    }
    
    {
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64,88,16)];
            [btn setTitle:@"Transparent"];
            [btn setStyle:1];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*1,88,16)];
            [btn setTitle:@"Opaque"];
            [btn setStyle:2];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*2,88,16)];
            [btn setTitle:@"Rectangle"];
            [btn setStyle:3];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*3,88,16)];
            [btn setTitle:@"Shadow"];
            [btn setStyle:4];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*4,88,16)];
            [btn setTitle:@"RoundRect"];
            [btn setStyle:5];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*5,88,16)];
            [btn setTitle:@"Oval"];
            [btn setStyle:7];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*6,88,16)];
            [btn setTitle:@"Standard"];
            [btn setStyle:0];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*7,88,16)];
            [btn setTitle:@"Default"];
            [btn setStyle:6];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*8,88,16)];
            [btn setTitle:@"Radio"];
            [btn setStyle:10];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*9,88,16)];
            [btn setTitle:@"Checkbox"];
            [btn setStyle:9];
            [buttonView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+20*10,88,16)];
            [btn setTitle:@"Popup"];
            [btn setStyle:8];
            [buttonView addSubview:btn];
        }
    }
    
    {
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64,88,32)];
            [btn setTitle:@"Transparent\n"];
            [btn setStyle:11];
            [btn setAlignment:NSLeftTextAlignment];
            [fieldView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+40*1,88,32)];
            [btn setTitle:@"Opaque\n"];
            [btn setStyle:12];
            [btn setAlignment:NSLeftTextAlignment];
            [fieldView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+40*2,88,32)];
            [btn setTitle:@"Rectangle\n"];
            [btn setStyle:13];
            [btn setAlignment:NSLeftTextAlignment];
            [fieldView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+40*3,88,32)];
            [btn setTitle:@"Shadow\n"];
            [btn setStyle:14];
            [btn setAlignment:NSLeftTextAlignment];
            [fieldView addSubview:btn];
        }
        
        {
            HCXDraggableToolBtn *btn = [[HCXDraggableToolBtn alloc] initWithFrame:convRect(self.frame,4,64+40*4,88,32)];
            [btn setTitle:@"Scrolling\n"];
            [btn setStyle:15];
            [btn setAlignment:NSLeftTextAlignment];
            [fieldView addSubview:btn];
        }
    }
}

static CGRect convRect(CGRect frame, int x, int y, int w, int h)
{
    return NSMakeRect(x,frame.size.height-y-h-16,w,h);
}

@end
