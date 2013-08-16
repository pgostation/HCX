//
//  HCXAppDelegate.m
//  HCX
//
//  Created by pgo on 2013/03/28.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import "HCXAppDelegate.h"
#import "HCXDoMenu.h"
#import "HCXMakeMenu.h"


@implementation HCXAppDelegate
{
    HCXDoMenu *domenu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    domenu = [[HCXDoMenu alloc] init];
    
    // メニュー作成
    [HCXMakeMenu makeMenus];
}

- (void)domenu:(NSMenuItem *)sender
{
    [domenu domenu:[sender title]];
}

//-------------------------------------------------------
// Drop a file at dock icon
//-------------------------------------------------------

- (BOOL)application:(NSApplication *)theApplication
           openFile:(NSString *)filename
{
    NSURL *pathToFile = [NSURL fileURLWithPath:filename];
    [domenu open:pathToFile];
    return YES;
}

@end
