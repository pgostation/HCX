//
//  StackEnv.m
//  HCX
//
//  Created by pgo on 2013/04/18.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "StackEnv.h"
#import "HCXDoMenu.h"
#import "HCXScript.h"
#import "HCXToolPanel.h"
#import "HCXAuthoringPanel.h"

@implementation StackEnv
{
    HCXScript *scriptEngine;
    BOOL changeStackDataFlag;
}

static NSMutableArray *StackEnvList;
static HCXToolPanel *toolPanel;
//static HCXAuthoringPanel *authoringPanel;

- (StackEnv *)init
{
    self = [super init];
    if (self) {
        static NSInteger pidSeed = 1;
        self.pid = pidSeed++;
        if(StackEnvList==nil){
            StackEnvList = [[NSMutableArray alloc] init];
        }
        [StackEnvList addObject:self];
    }
    
    return self;
}

//---------------------
//  StackEnv 関連
//---------------------
+ (StackEnv *) currentStackEnv
{
    // 現在のウィンドウはどのStackEnvと結びついているか
    for(StackEnv *stackEnv in [StackEnv getStackEnvList])
    {
        if([stackEnv.cardWindow isMainWindow])
        {
            return stackEnv;
        }
    }
    
    return nil;
}

+ (StackEnv *) stackEnvById: (NSInteger)stackEnvId
{
    for(StackEnv *env in StackEnvList)
    {
        if(env.pid == stackEnvId)
        {
            return env;
        }
    }
    
    return nil;
}

+ (void) RemoveStackEnvList:(StackEnv *)window
{
    for(int i=0; i<[StackEnvList count]; i++)
    {
        if(window == [StackEnvList objectAtIndex:i])
        {
            [StackEnvList removeObject:window];
            break;
        }
    }
}

+ (NSMutableArray *) getStackEnvList
{
    return StackEnvList;
}

//---------------------
//  ウィンドウ 関連
//---------------------
- (void) preOpen:(HCXStackData *)stack
{
    // 先にウィンドウを出して読み込み待ちを感じさせないようにする
    
    _stack = stack;
    
    // スクリプトエンジン初期化
    scriptEngine = [[HCXScript alloc] initWithStackEnv:self];
    
    // ウィンドウ
    NSInteger windowMask = NSTitledWindowMask | NSClosableWindowMask;
    if(stack.resizable) windowMask |= NSResizableWindowMask;
    _cardWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,stack.width,stack.height) styleMask: windowMask backing:NSBackingStoreBuffered defer:YES];
    [_cardWindow setTitle:stack.name];
    [_cardWindow setDelegate:self];
    [_cardWindow setReleasedWhenClosed:NO]; // これがないと過解放されてEXC_BAD_ACCESS
    [_cardWindow center];
    [_cardWindow makeKeyAndOrderFront:nil];
    
    _offBitmap = CGBitmapContextCreate(NULL, stack.width, stack.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGImageAlphaPremultipliedLast);
    
    [StackEnv resetWindowStyle];
    
    if(toolPanel == nil)
    {
        // ツールパレットを作成、表示
        NSRect rect = NSMakeRect(_cardWindow.frame.origin.x-96-8, _cardWindow.frame.origin.y+_cardWindow.frame.size.height-290-32, 96, 290);
        if(rect.origin.x<0) rect.origin = NSMakePoint(0,rect.origin.y);
        if(rect.origin.y<0) rect.origin = NSMakePoint(rect.origin.x,0);
        toolPanel = [[HCXToolPanel alloc] initWithContentRect:rect
                                                 styleMask:/*NSHUDWindowMask|*/NSUtilityWindowMask|NSClosableWindowMask|NSTitledWindowMask
                                                 backing:NSBackingStoreRetained
                                                        defer:NO];
        [toolPanel init2];
    }
    [toolPanel change:self];
    [toolPanel makeKeyAndOrderFront:self];
    
}

- (void) open:(HCXStackData *)stack
{
    _stack = stack;
    
    if(_cardWindow == nil)
    {
        [self preOpen:stack];
    }
    
    [StackEnv resetWindowStyle];
    
    _cardView = [[CardView alloc] initWithFrame:NSMakeRect(0,0,stack.width,stack.height)];
    [_cardView openFirstCard:self];
    [_cardWindow setContentView:_cardView];
    
    [_cardWindow makeFirstResponder:_cardView]; // これでキーボード取得できる
    [_cardWindow makeKeyAndOrderFront:_cardView]; // これでカードウィンドウをメインにする
}

+ (void) resetWindowStyle
{
    if([StackEnvList count] == 1)
    {
        // 閉じるボタンなし
        for(StackEnv *env in StackEnvList)
        {
            [env.cardWindow setStyleMask:NSTitledWindowMask | NSMiniaturizableWindowMask];
        }
    }
    else
    {
        // 閉じるボタンあり
        for(StackEnv *env in StackEnvList)
        {
            [env.cardWindow setStyleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask];
        }
    }
}

- (void) showToolWindow
{
    NSRect rect = NSMakeRect(_cardWindow.frame.origin.x-96-8, _cardWindow.frame.origin.y+_cardWindow.frame.size.height-290-32, 96, toolPanel.frame.size.height);
    if(rect.origin.x<0) rect.origin = NSMakePoint(0,rect.origin.y);
    if(rect.origin.y<0) rect.origin = NSMakePoint(rect.origin.x,0);
    [toolPanel setFrame:rect display:YES];
    [toolPanel makeKeyAndOrderFront:self];
}

- (void) windowWillClose:(NSNotification *)notification
{
    // スタック環境リストから外す
    [StackEnv RemoveStackEnvList:self];
    _cardWindow = nil;
    _stack = nil;
    
    [StackEnv resetWindowStyle];
}

//---------------------
//  現在のカード 関連
//---------------------
- (void) sendMessageToCurCard: (NSString *)msg force: (BOOL)force
{
    if(force==YES)
    {
        [scriptEngine doMsg:msg force:force stackEnv:self];
    }
}

- (NSInteger) getCurrentCardId
{
    return [scriptEngine currentCardId];
}

//---------------------
//  スタック 関連
//---------------------
+ (HCXStackData *) stackById: (NSInteger)stackId
{
    for(StackEnv *env in StackEnvList)
    {
        if(env.stack.pid == stackId)
        {
            return env.stack;
        }
    }
    
    return nil;
}

- (void) setChangeFlag:(BOOL)flag
{
    changeStackDataFlag = flag;
}

@end
