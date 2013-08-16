//
//  HCXInternational.m
//  HCX
//
//  Created by pgo on 2013/04/23.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXInternational.h"

@implementation HCXInternational

+ (BOOL) useJapanese
{
    static int useJapaneseCache = -1;
    if(useJapaneseCache == -1)
    {
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        NSArray* languages = [defs objectForKey:@"AppleLanguages"];
        for(NSString *lang in languages)
        {
            if([lang isEqualToString:@"日本語"])
            {
                useJapaneseCache = YES;
                return YES;
            }
        }
        useJapaneseCache = NO;
        return NO;
    }
    
    return useJapaneseCache;
}


+ (NSString *) switchString:(NSString *)engStr japanese:(NSString *)jpnStr
{
    return [HCXInternational useJapanese]?engStr:jpnStr;
}


+ (NSString *) menuName:(NSString *)engStr
{
    if([HCXInternational useJapanese])
    {
        return engStr;
    }
    else
    {
        return [HCXInternational japneseMenuName:engStr];
    }
}


+ (BOOL) menuCompare:(NSString *)str comp:(NSString *)engStr
{
    if([str isEqualToString:engStr])
    {
        return YES;
    }
    if([str isEqualToString:[HCXInternational japneseMenuName:engStr]])
    {
        return YES;
    }
    return NO;
}


+ (NSString *) japneseMenuName:(NSString *)engStr
{
    if([engStr isEqualToString:@"File"])
    {
        return @"ファイル";
    }
    if([engStr isEqualToString:@"Edit"])
    {
        return @"編集";
    }
    if([engStr isEqualToString:@"Go"])
    {
        return @"ゴー";
    }
    if([engStr isEqualToString:@"Tools"])
    {
        return @"ツール";
    }
    if([engStr isEqualToString:@"Objects"])
    {
        return @"オブジェクト";
    }
    //
    // App
    //
    if([engStr isEqualToString:@"About HCX"])
    {
        return @"HCXについて";
    }
    if([engStr isEqualToString:@"Preferences…"])
    {
        return @"環境設定…";
    }
    if([engStr isEqualToString:@"Hide HCX"])
    {
        return @"HCXを隠す";
    }
    if([engStr isEqualToString:@"Hide Others"])
    {
        return @"ほかを隠す";
    }
    if([engStr isEqualToString:@"Show All"])
    {
        return @"すべてを表示";
    }
    if([engStr isEqualToString:@"Quit HCX"])
    {
        return @"HCXを終了";
    }
    //
    // File
    //
    if([engStr isEqualToString:@"New Stack…"])
    {
        return @"新規スタック…";
    }
    if([engStr isEqualToString:@"Open Stack…"])
    {
        return @"スタックを開く…";
    }
    if([engStr isEqualToString:@"Open Recent Stack"])
    {
        return @"最近開いたスタック";
    }
    if([engStr isEqualToString:@"Close Stack"])
    {
        return @"スタックを閉じる";
    }
    if([engStr isEqualToString:@"Save a Copy…"])
    {
        return @"バックアップコピー…";
    }
    if([engStr isEqualToString:@"Compact Stack"])
    {
        return @"スタック整理";
    }
    if([engStr isEqualToString:@"Protect Stack…"])
    {
        return @"スタック保護…";
    }
    if([engStr isEqualToString:@"Delete Stack…"])
    {
        return @"スタック削除…";
    }
    if([engStr isEqualToString:@"Print…"])
    {
        return @"プリント…";
    }
    //
    // Edit
    //
    if([engStr isEqualToString:@"Undo"])
    {
        return @"取り消す";
    }
    if([engStr isEqualToString:@"Cut"])
    {
        return @"カット";
    }
    if([engStr isEqualToString:@"Copy"])
    {
        return @"コピー";
    }
    if([engStr isEqualToString:@"Paste"])
    {
        return @"ペースト";
    }
    if([engStr isEqualToString:@"Delete"])
    {
        return @"削除";
    }
    if([engStr isEqualToString:@"New Card"])
    {
        return @"新規カード";
    }
    if([engStr isEqualToString:@"Delete Card"])
    {
        return @"カード削除";
    }
    if([engStr isEqualToString:@"Copy Card"])
    {
        return @"コピー カード";
    }
    if([engStr isEqualToString:@"Background"])
    {
        return @"バックグラウンド";
    }
    if([engStr isEqualToString:@"Icon…"])
    {
        return @"アイコン編集…";
    }
    if([engStr isEqualToString:@"Sound…"])
    {
        return @"サウンド編集…";
    }
    if([engStr isEqualToString:@"Resource…"])
    {
        return @"リソース編集…";
    }
    //
    // Go
    //
    if([engStr isEqualToString:@"Back"])
    {
        return @"戻る";
    }
    if([engStr isEqualToString:@"Home"])
    {
        return @"ホーム";
    }
    if([engStr isEqualToString:@"Help"])
    {
        return @"ヘルプ";
    }
    if([engStr isEqualToString:@"Recent"])
    {
        return @"リーセント";
    }
    if([engStr isEqualToString:@"Prev"])
    {
        return @"前のカード";
    }
    if([engStr isEqualToString:@"Next"])
    {
        return @"次のカード";
    }
    if([engStr isEqualToString:@"First"])
    {
        return @"最初のカード";
    }
    if([engStr isEqualToString:@"Last"])
    {
        return @"最後のカード";
    }
    if([engStr isEqualToString:@"Find…"])
    {
        return @"検索…";
    }
    if([engStr isEqualToString:@"Message"])
    {
        return @"メッセージ";
    }
    if([engStr isEqualToString:@"Next Window"])
    {
        return @"次のウィンドウ";
    }
    //
    // Tools
    //
    if([engStr isEqualToString:@"Show Tools Palette"])
    {
        return @"ツールパレットを表示";
    }
    //
    // Objects
    //
    if([engStr isEqualToString:@"Button Info…"])
    {
        return @"ボタン情報…";
    }
    if([engStr isEqualToString:@"Field Info…"])
    {
        return @"フィールド情報…";
    }
    if([engStr isEqualToString:@"Card Info…"])
    {
        return @"カード情報…";
    }
    if([engStr isEqualToString:@"Background Info…"])
    {
        return @"バックグラウンド情報…";
    }
    if([engStr isEqualToString:@"Stack Info…"])
    {
        return @"スタック情報…";
    }
    if([engStr isEqualToString:@"Bring Closer"])
    {
        return @"前面に出す";
    }
    if([engStr isEqualToString:@"Send Farther"])
    {
        return @"背面に送る";
    }
    if([engStr isEqualToString:@"New Button"])
    {
        return @"新規ボタン";
    }
    if([engStr isEqualToString:@"New Field"])
    {
        return @"新規フィールド";
    }
    if([engStr isEqualToString:@"New Background"])
    {
        return @"新規バックグラウンド";
    }
    
    
    return engStr;
}

@end
