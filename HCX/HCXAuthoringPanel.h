//
//  HCXAuthoringPanel.h
//  HCX
//
//  Created by pgo on 2013/04/21.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HCXObject;

@interface HCXAuthoringPanel : NSPanel <NSWindowDelegate,NSTextFieldDelegate,NSMenuDelegate>

@property NSInteger myObjectType;

@property NSView *nameView; // 名前、IDを表示
@property NSView *styleView; // スタイル選択、ファミリーを表示
@property NSView *propView; // プロパティを表示
@property NSView *btnView; // ボタンを表示

- (void) init2;
+ (void) setData: (HCXObject *) objData;
//+ (void) hide;

@end
