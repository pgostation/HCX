//
//  HCXAuthoringPanel.m
//  HCX
//
//  Created by pgo on 2013/04/21.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXAuthoringPanel.h"
#import "HCXInternational.h"
#import "StackEnv.h"
#import "HCXButton.h"
#import "HCXField.h"

@implementation HCXAuthoringPanel
{
    NSInteger stackEnvId;
    NSInteger cardId;
    
    objectType partParentType;
    NSInteger partParentId;
    NSInteger objId;
    
    NSTextField *nameLabel;
    NSTextField *nameFld;
    NSTextField *idLabel;
    
    NSTextField *styleLabel;
    NSPopUpButton *styleMenu;
    NSTextField *familyLabel;
    NSPopUpButton *familyMenu;
    NSTextField *optionInfoLabel;
    
    NSButton *propButton[10];
    
    NSButton *fontBtn;
    NSButton *scriptBtn;
    NSButton *contentBtn;
    NSButton *iconBtn;
    NSButton *colorBtn;
}

static HCXAuthoringPanel *authPanel;
static CGRect saveRect;
static const int kLabelHeight = 24;
static const int kLineHeight = 30;
static const int kPropHeight = 26;


- (void) init2
{
    authPanel = self;
    
    [self setFloatingPanel:YES];
    [self setLevel:NSFloatingWindowLevel];
    
    //[self setTitle:@"Object Info"];
    [self setDelegate:self];
    [self setReleasedWhenClosed:NO];
    [self setHidesOnDeactivate:YES];
    
    // 影が消えるので、付け直す
    [self setHasShadow:NO];
    [self setHasShadow:YES];
    
    // nameView
    _nameView = [[NSView alloc] initWithFrame:convRect(self.frame, 0, 0, self.frame.size.width, 77)];
    [_nameView setWantsLayer:YES];
    [[self contentView] addSubview:_nameView];
    
    // styleView
    _styleView = [[NSView alloc] initWithFrame:convRect(self.frame, 0, 75, self.frame.size.width, 70)];
    [_styleView setWantsLayer:YES];
    [[self contentView] addSubview:_styleView];
    
    // propView
    _propView = [[NSView alloc] initWithFrame:convRect(self.frame, 0, 145, self.frame.size.width, 140)];
    [_propView setWantsLayer:YES];
    [[self contentView] addSubview:_propView];
    
    // btnView
    _btnView = [[NSView alloc] initWithFrame:convRect(self.frame, 0, 285, self.frame.size.width, 100)];
    [_btnView setWantsLayer:YES];
    [[self contentView] addSubview:_btnView];
    
    //
    nameLabel = [self makeLabel:INTR(@"Name:",@"名前:") frame:convRect(_nameView.frame, 0, 0*kLineHeight, 48, kLabelHeight)];
    [_nameView addSubview:nameLabel];
    
    nameFld = [self makeField:@"" frame:convRect(_nameView.frame, 48, 0*kLineHeight, 144, kLabelHeight)];
    [_nameView addSubview:nameFld];
    
    idLabel = [self makeLabel:@"xxx" frame:convRect(_nameView.frame, 4, 1*kLineHeight+4, 196, kLabelHeight*2+4)];
    [idLabel setFont:[NSFont systemFontOfSize:11]];
    [idLabel setAlignment:NSLeftTextAlignment];
    [_nameView addSubview:idLabel];
    
    //
    styleLabel = [self makeLabel:INTR(@"Style:",@"スタイル:") frame:convRect(_styleView.frame, 0, 0*kLineHeight+4, 64, kLabelHeight)];
    [styleLabel setFont:[NSFont systemFontOfSize:11]];
    [_styleView addSubview:styleLabel];
    
    styleMenu = [[NSPopUpButton alloc] initWithFrame:convRect(_styleView.frame, 64, 0*kLineHeight, 128, kLabelHeight)];
    [[styleMenu cell] setControlSize:NSSmallControlSize];
    [styleMenu setFont:[NSFont systemFontOfSize:11]];
    [_styleView addSubview:styleMenu];
    
    familyLabel = [self makeLabel:INTR(@"Family:",@"ファミリー:") frame:convRect(_styleView.frame, 0, 1*kLineHeight+4, 64, kLabelHeight)];
    [familyLabel setFont:[NSFont systemFontOfSize:11]];
    [_styleView addSubview:familyLabel];
    
    familyMenu = [[NSPopUpButton alloc] initWithFrame:convRect(_styleView.frame, 64, 1*kLineHeight, 128, kLabelHeight)];
    [[familyMenu cell] setControlSize:NSSmallControlSize];
    [familyMenu setFont:[NSFont systemFontOfSize:11]];
    [_styleView addSubview:familyMenu];
    
    optionInfoLabel = [self makeLabel:@"xxx" frame:convRect(_styleView.frame, 4, 0*kLineHeight, 200, kLabelHeight*2)];
    [optionInfoLabel setFont:[NSFont systemFontOfSize:10]];
    [optionInfoLabel setAlignment:NSLeftTextAlignment];
    [_styleView addSubview:optionInfoLabel];
    
    //
    for(int i=0; i<10; i++)
    {
        propButton[i] = [[NSButton alloc] initWithFrame:convRect(_propView.frame, i%2*100+4, i/2*kPropHeight, 96, kLabelHeight)];
        [propButton[i] setButtonType:NSSwitchButton];
        [propButton[i] setTitle:@"Property"];
        [propButton[i] setAction:@selector(propChange:)];
        [[propButton[i] cell] setControlSize:NSSmallControlSize];
        [propButton[i] setFont:[NSFont systemFontOfSize:11]];
        [_propView addSubview:propButton[i]];
    }
    
    //
    scriptBtn = [[NSButton alloc] initWithFrame:convRect(_btnView.frame, 3, 0*kLineHeight, 96, kLabelHeight+4)];
    [scriptBtn setTitle:INTR(@"Script…",@"スクリプト…")];
    [scriptBtn setAction:@selector(btnClick:)];
    [scriptBtn setBezelStyle:NSRoundedBezelStyle];
    [_btnView addSubview:scriptBtn];
    
    colorBtn = [[NSButton alloc] initWithFrame:convRect(_btnView.frame, 101, 0*kLineHeight, 96, kLabelHeight+4)];
    [colorBtn setTitle:INTR(@"Color…",@"色…")];
    [colorBtn setAction:@selector(btnClick:)];
    [colorBtn setBezelStyle:NSRoundedBezelStyle];
    [_btnView addSubview:colorBtn];
    
    fontBtn = [[NSButton alloc] initWithFrame:convRect(_btnView.frame, 3, 1*kLineHeight, 96, kLabelHeight+4)];
    [fontBtn setTitle:INTR(@"Font…",@"フォント…")];
    [fontBtn setAction:@selector(btnClick:)];
    [fontBtn setBezelStyle:NSRoundedBezelStyle];
    [_btnView addSubview:fontBtn];
    
    iconBtn = [[NSButton alloc] initWithFrame:convRect(_btnView.frame, 101, 1*kLineHeight, 96, kLabelHeight+4)];
    [iconBtn setTitle:INTR(@"Icon…",@"アイコン…")];
    [iconBtn setAction:@selector(btnClick:)];
    [iconBtn setBezelStyle:NSRoundedBezelStyle];
    [_btnView addSubview:iconBtn];
    
    contentBtn = [[NSButton alloc] initWithFrame:convRect(_btnView.frame, 3, 2*kLineHeight, 96, kLabelHeight+4)];
    [contentBtn setTitle:INTR(@"Content…",@"内容…")];
    [contentBtn setAction:@selector(btnClick:)];
    [contentBtn setBezelStyle:NSRoundedBezelStyle];
    [_btnView addSubview:contentBtn];
}

- (NSTextField *) makeLabel:(NSString *)text frame:(CGRect)frame;
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:text];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setBezeled:NO];
    [label setAlignment:NSRightTextAlignment];
    return label;
}

- (NSTextField *) makeField:(NSString *)text frame:(CGRect)frame;
{
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    [field setStringValue:text];
    [field setDelegate:self];
    return field;
}

+ (void) setData: (HCXObject *) objData
{
    if(objData==nil && authPanel==nil)
    {
        return; //表示クリアする必要なし
    }
    
    // データnilのときは表示をクリア
    if(objData==nil)
    {
        authPanel.title = @"";
        authPanel.nameView.hidden = YES;
        authPanel.styleView.hidden = YES;
        authPanel.propView.hidden = YES;
        authPanel.btnView.hidden = YES;
        [authPanel setLevel:NSNormalWindowLevel]; //スクリプト編集のときとかは後ろに回したい
        return;
    }
    
    authPanel.nameView.hidden = NO;
    authPanel.styleView.hidden = NO;
    authPanel.propView.hidden = NO;
    authPanel.btnView.hidden = NO;
    
    [authPanel setLevel:NSFloatingWindowLevel];
    
    if(authPanel==nil || authPanel.myObjectType != objData.objectType)
    {
        if(authPanel!=nil)
        {
            if(authPanel.isVisible==YES)
            {
                saveRect = authPanel.frame;
            }
            //[authPanel orderOut:nil];
            //if(objData==nil)
            //{
            //    saveRect = NSZeroRect;
            //}
        }
        // オーサリングパレットを作成
        //NSRect rect = NSMakeRect(_cardWindow.frame.origin.x+_cardWindow.frame.size.width+8, _cardWindow.frame.origin.y+_cardWindow.frame.size.height-400-32, 200, 400);
        NSRect rect = NSMakeRect(0, 0, 200, 400);
        authPanel = [[HCXAuthoringPanel alloc] initWithContentRect:rect
                                                              styleMask:/*NSHUDWindowMask|*/NSUtilityWindowMask|NSClosableWindowMask|NSTitledWindowMask
                                                                backing:NSBackingStoreRetained
                                                                  defer:NO];
        [authPanel init2];
    }
    
    [authPanel setData:objData];
}

- (void) setData: (HCXObject *) objData
{
    StackEnv *stackEnv = [StackEnv currentStackEnv];
    stackEnvId = stackEnv.pid;
    cardId = [stackEnv getCurrentCardId];
    objId = objData.pid;
    
    _myObjectType = objData.objectType;
    
    //[nameFld setEditable:YES];
    //[nameFld setBezeled:YES];
    
    styleLabel.hidden = YES;
    styleMenu.hidden = YES;
    familyLabel.hidden = YES;
    familyMenu.hidden = YES;
    optionInfoLabel.hidden = YES;
    for(int i=0; i<10; i++)
    {
        propButton[i].hidden = YES;
    }
    fontBtn.hidden = YES;
    contentBtn.hidden = YES;
    iconBtn.hidden = YES;
    colorBtn.hidden = YES;
    
    
    if(objData.objectType==ENUM_STACK)
    {
        self.title = INTR(@"Stack information",@"スタック情報");
        
        HCXStackData *stack = (HCXStackData *)objData;
        nameFld.stringValue = stack.name;
        [nameFld setEditable:NO];
        [nameFld setBezeled:NO];
        idLabel.stringValue = [NSString stringWithFormat:@"%@:%ld", INTR(@"Number of cards",@"カード枚数"), [stack.cardList count]];
        
        optionInfoLabel.hidden = NO;
        optionInfoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld px   %@: %ld px", INTR(@"Width",@"幅"), stack.width, INTR(@"Height",@"高さ"), stack.height];
        
        propButton[0].hidden = NO;
        propButton[0].title = INTR(@"Can't Abort",@"中断不可");
        propButton[0].state = stack.cantAbort?NSOnState:NSOffState;
        
        propButton[1].hidden = NO;
        propButton[1].title = INTR(@"Can't Peek",@"強調表示不可");
        propButton[1].state = stack.cantPeek?NSOnState:NSOffState;
        
        propButton[2].hidden = NO;
        propButton[2].title = INTR(@"Can't Modify",@"変更不可");
        propButton[2].state = stack.cantModify?NSOnState:NSOffState;
        
        propButton[3].hidden = NO;
        propButton[3].title = INTR(@"Window\nresizable",@"ウィンドウ\nサイズ可変");
        propButton[3].state = stack.resizable?NSOnState:NSOffState;
    }
    
    if(objData.objectType==ENUM_BACKGROUND)
    {
        self.title = INTR(@"Background information",@"バックグラウンド情報");
        
        HCXBackground *bg = (HCXBackground *)objData;
        nameFld.stringValue = bg.name;
        NSInteger number = [bg numberInStack];
        idLabel.stringValue = [NSString stringWithFormat:@"ID:%ld  %@:%ld", bg.pid, INTR(@"Number",@"番号"), number];
        
        propButton[0].hidden = NO;
        propButton[0].title = INTR(@"Show picture",@"ピクチャを表示");
        propButton[0].state = bg.showPict?NSOnState:NSOffState;
        
        propButton[2].hidden = NO;
        propButton[2].title = INTR(@"Don't search",@"検索しない");
        propButton[2].state = bg.dontSearch?NSOnState:NSOffState;
        
        propButton[3].hidden = NO;
        propButton[3].title = INTR(@"Can't delete",@"削除不可");
        propButton[3].state = bg.cantDelete?NSOnState:NSOffState;
    }
    
    if(objData.objectType==ENUM_CARD)
    {
        self.title = INTR(@"Card information",@"カード情報");
        
        HCXCard *card = (HCXCard *)objData;
        nameFld.stringValue = card.name;
        NSInteger number = [card numberInStack];
        idLabel.stringValue = [NSString stringWithFormat:@"ID:%ld  %@:%ld", card.pid, INTR(@"Number",@"番号"), number];
        
        propButton[0].hidden = NO;
        propButton[0].title = INTR(@"Show picture",@"ピクチャを表示");
        propButton[0].state = card.showPict?NSOnState:NSOffState;
        
        propButton[1].hidden = NO;
        propButton[1].title = INTR(@"Marked",@"マーク");
        propButton[1].state = card.marked?NSOnState:NSOffState;
        
        propButton[2].hidden = NO;
        propButton[2].title = INTR(@"Don't search",@"検索しない");
        propButton[2].state = card.dontSearch?NSOnState:NSOffState;
        
        propButton[3].hidden = NO;
        propButton[3].title = INTR(@"Can't delete",@"削除不可");
        propButton[3].state = card.cantDelete?NSOnState:NSOffState;
    }
    
    if(objData.objectType==ENUM_BUTTON)
    {
        HCXButton *button = (HCXButton *)objData;
        partParentType = button.parentType;
        partParentId = button.parentId;
        
        self.title = INTR(@"Button information",@"ボタン情報");
        
        nameFld.stringValue = button.name;
        
        NSString *buttonType = (button.parentType==ENUM_CARD)?INTR(@"Card button",@"カードボタン"):INTR(@"Background button",@"バックグラウンドボタン");
        NSInteger number = [button buttonNumberInParent];
        NSInteger partNumber = [button partNumberInParent];
        idLabel.stringValue = [NSString stringWithFormat:@"%@  ID:%ld\n%@:%ld  %@:%ld", buttonType, button.pid, INTR(@"Number",@"番号"), number, INTR(@"Part number",@"パーツ番号"), partNumber];
        
        styleLabel.hidden = NO;
        styleMenu.hidden = NO;
        NSMenu *menuA=[[NSMenu alloc]init];
        NSArray *array = @[INTR(@"Transparent",@"透明"),
                           INTR(@"Opaque",@"不透明"),
                           INTR(@"Rectangle",@"長方形"),
                           INTR(@"Shadow",@"シャドウ"),
                           INTR(@"RoundRect",@"丸みのある長方形"),
                           INTR(@"Standard",@"標準"),
                           INTR(@"Default",@"省略時設定"),
                           INTR(@"Oval",@"楕円"),
                           INTR(@"Radio",@"ラジオボタン"),
                           INTR(@"Checkbox",@"チェックボックス"),
                           INTR(@"Popup",@"ポップアップ")];
        for(NSString *styleName in array)
        {
            NSMenuItem *menuItem01=[[NSMenuItem alloc]initWithTitle:styleName
                                                             action:@selector(styleSelect:)
                                                      keyEquivalent:@""];
            [menuA addItem:menuItem01];
        }
        
        [menuA setDelegate:self];
        [styleMenu setMenu:menuA];
        switch(button.style){
            case 0:
                [styleMenu selectItemAtIndex:5];
                break;
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 9:
            case 10:
                [styleMenu selectItemAtIndex:button.style-1];
                break;
            case 6:
                [styleMenu selectItemAtIndex:6];
                break;
            case 7:
                [styleMenu selectItemAtIndex:7];
                break;
            case 8:
                [styleMenu selectItemAtIndex:10];
                break;
        }
        
        familyLabel.hidden = NO;
        familyMenu.hidden = NO;
        NSMenu *menuB=[[NSMenu alloc]init];
        NSArray *arrayB = @[INTR(@"None",@"なし"),
                            @"1",
                            @"2",
                            @"3",
                            @"4",
                            @"5",
                            @"6",
                            @"7",
                            @"8",
                            @"9",
                            @"10",
                            @"11",
                            @"12",
                            @"13",
                            @"14",
                            @"15"];
        for(NSString *familyName in arrayB)
        {
            NSMenuItem *menuItem01=[[NSMenuItem alloc]initWithTitle:familyName
                                                             action:@selector(familySelect:)
                                                      keyEquivalent:@""];
            [menuB addItem:menuItem01];
        }
        
        [menuB setDelegate:self];
        [familyMenu setMenu:menuB];
        [familyMenu selectItemAtIndex:button.family];
        
        propButton[0].hidden = NO;
        propButton[0].title = INTR(@"Show name",@"名前を表示");
        propButton[0].state = button.showName?NSOnState:NSOffState;
        
        propButton[1].hidden = NO;
        propButton[1].title = INTR(@"Enabled",@"使えるように");
        propButton[1].state = button.enabled?NSOnState:NSOffState;
        
        propButton[2].hidden = NO;
        propButton[2].title = INTR(@"Visible",@"見えるように");
        propButton[2].state = button.visible?NSOnState:NSOffState;
        
        propButton[3].hidden = NO;
        propButton[3].title = INTR(@"Scale Icon",@"アイコンの\n拡大縮小");
        propButton[3].state = button.scaleIcon?NSOnState:NSOffState;
        
        propButton[4].hidden = NO;
        propButton[4].title = INTR(@"Auto Hilite",@"オートハイラ\nイト");
        propButton[4].state = button.autoHighlight?NSOnState:NSOffState;
        
        if(button.parentType==ENUM_BACKGROUND)
        {
            propButton[5].hidden = NO;
            propButton[5].title = INTR(@"Shared Hilite",@"ハイライトを\n共有");
            propButton[5].state = button.sharedHighlight?NSOnState:NSOffState;
        }
        
        fontBtn.hidden = NO;
        contentBtn.hidden = NO;
        iconBtn.hidden = NO;
        colorBtn.hidden = NO;
    }
    
    if(objData.objectType==ENUM_FIELD)
    {
        HCXField *field = (HCXField *)objData;
        partParentType = field.parentType;
        partParentId = field.parentId;
        
        self.title = INTR(@"Field information",@"フィールド情報");
        
        nameFld.stringValue = field.name;
        
        NSString *fieldType = (field.parentType==ENUM_CARD)?INTR(@"Card field",@"カードフィールド"):INTR(@"Background field",@"バックグラウンドフィールド");
        NSInteger number = [field fieldNumberInParent];
        NSInteger partNumber = [field partNumberInParent];
        idLabel.stringValue = [NSString stringWithFormat:@"%@  ID:%ld\n%@:%ld  %@:%ld", fieldType, field.pid, INTR(@"Number",@"番号"), number, INTR(@"Part number",@"パーツ番号"), partNumber];
        
        styleLabel.hidden = NO;
        styleMenu.hidden = NO;
        NSMenu *menuA=[[NSMenu alloc]init];
        NSArray *array = @[INTR(@"Transparent",@"透明"),
                           INTR(@"Opaque",@"不透明"),
                           INTR(@"Rectangle",@"長方形"),
                           INTR(@"Shadow",@"シャドウ"),
                           INTR(@"Scrolling",@"スクロール")];
        for(NSString *styleName in array)
        {
            NSMenuItem *menuItem01=[[NSMenuItem alloc]initWithTitle:styleName
                                                             action:@selector(styleSelect:)
                                                      keyEquivalent:@""];
            [menuA addItem:menuItem01];
        }
        
        [menuA setDelegate:self];
        [styleMenu setMenu:menuA];
        switch(field.style){
            case 0:
                [styleMenu selectItemAtIndex:5];
                break;
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
                [styleMenu selectItemAtIndex:field.style-1];
                break;
        }
        
        propButton[0].hidden = NO;
        propButton[0].title = INTR(@"Lock text",@"ロックテキスト");
        propButton[0].state = field.lockText?NSOnState:NSOffState;
        
        propButton[1].hidden = NO;
        propButton[1].title = INTR(@"Visible",@"見えるように");
        propButton[1].state = field.visible?NSOnState:NSOffState;
        
        propButton[2].hidden = NO;
        propButton[2].title = INTR(@"Don't Wrap",@"行を折り返さ\nない");
        propButton[2].state = field.dontWrap?NSOnState:NSOffState;
        
        propButton[3].hidden = NO;
        propButton[3].title = INTR(@"Wide margins",@"余白を広く");
        propButton[3].state = field.wideMargins?NSOnState:NSOffState;
        
        propButton[4].hidden = NO;
        propButton[4].title = INTR(@"Auto select",@"自動的に選択");
        propButton[4].state = field.autoSelect?NSOnState:NSOffState;
        
        propButton[5].hidden = NO;
        propButton[5].title = INTR(@"Multiple lines",@"複数行");
        propButton[5].state = field.multipleLines?NSOnState:NSOffState;
        
        propButton[6].hidden = NO;
        propButton[6].title = INTR(@"Fixed line height",@"行の高さを固定");
        propButton[6].state = field.fixedLineHeight?NSOnState:NSOffState;
        
        propButton[7].hidden = NO;
        propButton[7].title = INTR(@"Show lines",@"行表示");
        propButton[7].state = field.autoTab?NSOnState:NSOffState;
        
        propButton[8].hidden = NO;
        propButton[8].title = INTR(@"Don't Search",@"検索しない");
        propButton[8].state = field.dontSearch?NSOnState:NSOffState;
        
        if(field.parentType==ENUM_BACKGROUND)
        {
            propButton[9].hidden = NO;
            propButton[9].title = INTR(@"Shared text",@"テキストを共有");
            propButton[9].state = field.sharedText?NSOnState:NSOffState;
        }
        
        fontBtn.hidden = NO;
        colorBtn.hidden = NO;
    }
    
    // こうしないとNSPanelではtitle変わらないけど、やたら時間かかる→NSWindowにしても同じ→毎回作り直せばええんや！
    //NSRect rect = self.frame;
    //[self setFrame:CGRectInset(rect,-1,0) display:NO];
    //[self setFrame:rect display:NO];
    
    // パネルを表示
    if([self isVisible]==NO)
    {
        NSInteger left = stackEnv.cardWindow.frame.size.width/2-self.frame.size.width/2;
        if([[objData class] isSubclassOfClass:[HCXPart class]])
        {
            left = ((HCXPart *)objData).left+objData.width+16;
        }
        NSRect rect = saveRect;
        if(rect.size.width==0)
        {
            rect = NSMakeRect(stackEnv.cardWindow.frame.origin.x+left,
                                 stackEnv.cardWindow.frame.origin.y+stackEnv.cardWindow.frame.size.height-self.frame.size.height-16,
                                 self.frame.size.width,
                                 self.frame.size.height);
        }
        [self setFrame:rect display:YES];
        [self makeKeyAndOrderFront:self];
    }
}

//+ (void) hide
//{
//    [authPanel orderOut:authPanel];
//    authPanel = nil;
//    saveRect = NSZeroRect;
//}

static CGRect convRect(CGRect frame, int x, int y, int w, int h)
{
    return NSMakeRect(x,frame.size.height-y-h-16,w,h);
}

//----------------
// Window Delegate
//----------------
- (void)windowWillClose:(NSNotification *)notify
{
    NSWindow *win = notify.object;
    if(win==authPanel){
        authPanel = nil;
        saveRect = NSZeroRect;
    }
}

//-------------------------
// Checkbox Action Selector
//-------------------------
- (void)propChange:(NSButton *)sender
{
    StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
    if(_myObjectType==ENUM_STACK)
    {
        HCXStackData *stack = stackEnv.stack;
        if([sender.title isEqualToString:INTR(@"Can't Abort",@"中断不可")])
        {
            stack.cantAbort = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Can't Peek",@"強調表示不可")])
        {
            stack.cantPeek = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Can't Modify",@"変更不可")])
        {
            stack.cantModify = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Window\nresizable",@"ウィンドウ\nサイズ可変")])
        {
            stack.resizable = sender.state==NSOnState?true:false;
        }
        [stackEnv setChangeFlag:YES];
    }
    
    if(_myObjectType==ENUM_BACKGROUND)
    {
        HCXBackground *bg = [stackEnv.stack getBgById:objId];
        if([sender.title isEqualToString:INTR(@"Show picture",@"ピクチャを表示")])
        {
            bg.showPict = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Don't search",@"検索しない")])
        {
            bg.dontSearch = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Can't delete",@"削除不可")])
        {
            bg.cantDelete = sender.state==NSOnState?true:false;
        }
        [stackEnv setChangeFlag:YES];
    }
    
    if(_myObjectType==ENUM_CARD)
    {
        HCXCard *cd = [stackEnv.stack getCardById:objId];
        if([sender.title isEqualToString:INTR(@"Show picture",@"ピクチャを表示")])
        {
            cd.showPict = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Don't search",@"検索しない")])
        {
            cd.dontSearch = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Can't delete",@"削除不可")])
        {
            cd.cantDelete = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Marked",@"マーク")])
        {
            cd.marked = sender.state==NSOnState?true:false;
        }
        [stackEnv setChangeFlag:YES];
    }
    
    if(_myObjectType==ENUM_BUTTON)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        HCXButton *btn = (HCXButton*)[cardbase getPartById:objId];
        if([sender.title isEqualToString:INTR(@"Show name",@"名前を表示")])
        {
            btn.showName = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Enabled",@"使えるように")])
        {
            btn.enabled = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Visible",@"見えるように")])
        {
            btn.visible = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Scale Icon",@"アイコンの\n拡大縮小")])
        {
            btn.scaleIcon = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Auto Hilite",@"オートハイラ\nイト")])
        {
            btn.autoHighlight = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Shared Hilite",@"ハイライトを\n共有")])
        {
            btn.sharedHighlight = sender.state==NSOnState?true:false;
        }
        [stackEnv setChangeFlag:YES];
    }
    
    if(_myObjectType==ENUM_FIELD)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        HCXField *fld = (HCXField*)[cardbase getPartById:objId];
        if([sender.title isEqualToString:INTR(@"Lock text",@"ロックテキスト")])
        {
            fld.lockText = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Visible",@"見えるように")])
        {
            fld.visible = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Don't Wrap",@"行を折り返さ\nない")])
        {
            fld.dontWrap = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Wide margins",@"余白を広く")])
        {
            fld.wideMargins = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Auto select",@"自動的に選択")])
        {
            fld.autoSelect = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Multiple lines",@"複数行")])
        {
            fld.multipleLines = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Fixed line height",@"行の高さを固定")])
        {
            fld.fixedLineHeight = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Show lines",@"行表示")])
        {
            fld.showLines = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Don't Search",@"検索しない")])
        {
            fld.dontSearch = sender.state==NSOnState?true:false;
        }
        else if([sender.title isEqualToString:INTR(@"Shared text",@"テキストを共有")])
        {
            fld.sharedText = sender.state==NSOnState?true:false;
        }
        [stackEnv setChangeFlag:YES];
    }
    
    [stackEnv sendMessageToCurCard: @"go this card" force:YES];
}

//-----------------------
// button Action Selector
//-----------------------
- (void)btnClick:(NSButton *)sender
{
    StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
    HCXObject *object;
    if(_myObjectType==ENUM_STACK)
    {
        object = stackEnv.stack;
    }
    
    if(_myObjectType==ENUM_BACKGROUND)
    {
        object = [stackEnv.stack getBgById:objId];
    }
    
    if(_myObjectType==ENUM_CARD)
    {
        object = [stackEnv.stack getCardById:objId];
    }
    
    if(_myObjectType==ENUM_BUTTON)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXButton*)[cardbase getPartById:objId];
    }
    
    if(_myObjectType==ENUM_FIELD)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXField*)[cardbase getPartById:objId];
    }
    
    NSString *objStr = [object string];
    
    if([sender.title isEqualToString:INTR(@"Script…",@"スクリプト…")])
    {
        [stackEnv sendMessageToCurCard: [NSString stringWithFormat:@"edit script of %@", objStr] force:YES];
    }
    if([sender.title isEqualToString:INTR(@"Color…",@"色…")])
    {
        [stackEnv sendMessageToCurCard: [NSString stringWithFormat:@"edit color of %@", objStr] force:YES];
    }
    if([sender.title isEqualToString:INTR(@"Font…",@"フォント…")])
    {
        [stackEnv sendMessageToCurCard: [NSString stringWithFormat:@"edit font of %@", objStr] force:YES];
    }
    if([sender.title isEqualToString:INTR(@"Icon…",@"アイコン…")])
    {
        [stackEnv sendMessageToCurCard: [NSString stringWithFormat:@"edit icon of %@", objStr] force:YES];
    }
    if([sender.title isEqualToString:INTR(@"Content…",@"内容…")])
    {
        [stackEnv sendMessageToCurCard: [NSString stringWithFormat:@"edit content of %@", objStr] force:YES];
    }
    
}

//---------------------
// NSTextField Delegate
//---------------------
- (void) controlTextDidChange:(NSNotification *)notification
{
    StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
    HCXObject *object;
    if(_myObjectType==ENUM_STACK)
    {
        object = stackEnv.stack;
    }
    
    if(_myObjectType==ENUM_BACKGROUND)
    {
        object = [stackEnv.stack getBgById:objId];
    }
    
    if(_myObjectType==ENUM_CARD)
    {
        object = [stackEnv.stack getCardById:objId];
    }
    
    if(_myObjectType==ENUM_BUTTON)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXButton*)[cardbase getPartById:objId];
    }
    
    if(_myObjectType==ENUM_FIELD)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXField*)[cardbase getPartById:objId];
    }
    
    NSTextField *textField = [notification object];
    if(textField == nameFld && (_myObjectType!=ENUM_STACK))
    {
        object.name = nameFld.stringValue;
        [stackEnv setChangeFlag:YES];
        [stackEnv sendMessageToCurCard: @"go this card" force:YES];
    }
}

- (void) styleSelect:(NSMenuItem *)sender
{
    StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
    HCXPart *object;
    
    if(_myObjectType==ENUM_BUTTON)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXButton*)[cardbase getPartById:objId];
        
        NSArray *array = @[INTR(@"Transparent",@"透明"),
                           INTR(@"Opaque",@"不透明"),
                           INTR(@"Rectangle",@"長方形"),
                           INTR(@"Shadow",@"シャドウ"),
                           INTR(@"RoundRect",@"丸みのある長方形"),
                           INTR(@"Standard",@"標準"),
                           INTR(@"Default",@"省略時設定"),
                           INTR(@"Oval",@"楕円"),
                           INTR(@"Radio",@"ラジオボタン"),
                           INTR(@"Checkbox",@"チェックボックス"),
                           INTR(@"Popup",@"ポップアップ")];
        if([sender.title isEqualToString:[array objectAtIndex:0]])
        {
            object.style = 1;
        }
        if([sender.title isEqualToString:[array objectAtIndex:1]])
        {
            object.style = 2;
        }
        if([sender.title isEqualToString:[array objectAtIndex:2]])
        {
            object.style = 3;
        }
        if([sender.title isEqualToString:[array objectAtIndex:3]])
        {
            object.style = 4;
        }
        if([sender.title isEqualToString:[array objectAtIndex:4]])
        {
            object.style = 5;
        }
        if([sender.title isEqualToString:[array objectAtIndex:5]])
        {
            object.style = 0;
        }
        if([sender.title isEqualToString:[array objectAtIndex:6]])
        {
            object.style = 6;
        }
        if([sender.title isEqualToString:[array objectAtIndex:7]])
        {
            object.style = 7;
        }
        if([sender.title isEqualToString:[array objectAtIndex:8]])
        {
            object.style = 10;
        }
        if([sender.title isEqualToString:[array objectAtIndex:9]])
        {
            object.style = 9;
        }
        if([sender.title isEqualToString:[array objectAtIndex:10]])
        {
            object.style = 8;
        }
    }
    
    if(_myObjectType==ENUM_FIELD)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXField*)[cardbase getPartById:objId];
        
        NSArray *array = @[INTR(@"Transparent",@"透明"),
                           INTR(@"Opaque",@"不透明"),
                           INTR(@"Rectangle",@"長方形"),
                           INTR(@"Shadow",@"シャドウ"),
                           INTR(@"Scrolling",@"スクロール")];
        if([sender.title isEqualToString:[array objectAtIndex:0]])
        {
            object.style = 1;
        }
        if([sender.title isEqualToString:[array objectAtIndex:1]])
        {
            object.style = 2;
        }
        if([sender.title isEqualToString:[array objectAtIndex:2]])
        {
            object.style = 3;
        }
        if([sender.title isEqualToString:[array objectAtIndex:3]])
        {
            object.style = 4;
        }
        if([sender.title isEqualToString:[array objectAtIndex:4]])
        {
            object.style = 5;
        }
    }
    
    [stackEnv setChangeFlag:YES];
    [stackEnv sendMessageToCurCard: @"go this card" force:YES];
}

- (void) familySelect:(NSMenuItem *)sender
{
    StackEnv *stackEnv = [StackEnv stackEnvById:stackEnvId];
    HCXButton *object;
    
    if(_myObjectType==ENUM_BUTTON)
    {
        HCXCardBase *cardbase = [stackEnv.stack getCardById:cardId];
        if(partParentType==ENUM_BACKGROUND)
        {
            cardbase = [stackEnv.stack getBgById:partParentId];
        }
        object = (HCXButton*)[cardbase getPartById:objId];
        
        if([sender.title isEqualToString:INTR(@"None",@"なし")])
        {
            object.family = 0;
        }
        else
        {
            object.family = [sender.title intValue];
        }
    }
    
    [stackEnv setChangeFlag:YES];
    [stackEnv sendMessageToCurCard: @"go this card" force:YES];
}

@end
