//
//  HCXSIAppDelegate.m
//  stackimport
//
//  Created by pgo on 2013/03/30.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import "HCXSIAppDelegate.h"
#import "HCXstackimport.h"

@implementation HCXSIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Application Menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle:@"App" action:nil keyEquivalent:@""];
    {
        NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"App"];
        
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"About this application" action:@selector(about:) keyEquivalent:@""];
            [appMenu addItem:menuItem];
        }
        [appMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences…" action:nil keyEquivalent:@""];
            [appMenu addItem:menuItem];
        }
        [appMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"q"];
            [appMenu addItem:menuItem];
        }
        
        [appMenuItem setSubmenu:appMenu];
    }
    
    // Set Menus to App
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main"];
    [mainMenu addItem:appMenuItem];
    [[NSApplication sharedApplication] setMainMenu:mainMenu];
}


// アラートのボタン押下時に呼び出される
- (void) alertDidEnd:(NSAlert *)alert
          returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn) {
        NSLog(@"NSAlertDefaultReturn");
    }
    else if(returnCode == NSAlertAlternateReturn) {
        NSLog(@"NSAlertAlternateReturn");
    }
    else if(returnCode == NSAlertOtherReturn) {
        NSLog(@"NSAlertOtherReturn");
    }
    else if(returnCode == NSAlertErrorReturn) {
        NSLog(@"NSAlertErrorReturn");
    }
    
    // quit
    [[NSApplication sharedApplication] terminate:self];
}

//-------------------------------------------------------
// Drop a file at dock icon
//-------------------------------------------------------

- (BOOL)application:(NSApplication *)theApplication
           openFile:(NSString *)filename
{
    return [[[HCXstackimport alloc] init] stackimport:filename];
}

//-------------------------------------------------------
// Do menu item
//-------------------------------------------------------

- (void)about:(NSMenuItem *)sender
{
    NSLog(@"about");
    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(80,[NSScreen mainScreen].frame.size.height-300,200,200)
                     styleMask:NSClosableWindowMask | NSTitledWindowMask
                       backing:NSBackingStoreBuffered defer:YES];
    NSTextField *fld=[[NSTextField alloc]initWithFrame:CGRectMake(10,10,180,180)];
    [fld setEditable:NO];
    [fld setBezeled:NO];
    fld.stringValue=@"stackimport.app\n\n(c)2013 pgostation\n----\n\nDrop a HyperCard stack to app icon.";
    [_window.contentView addSubview:fld];
    
    [_window makeKeyAndOrderFront:nil];
}

- (void)quit:(NSMenuItem *)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
