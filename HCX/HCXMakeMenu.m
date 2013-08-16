//
//  HCXMakeMenu.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXMakeMenu.h"
#import "HCXInternational.h"

@implementation HCXMakeMenu

+ (void) makeMenus
{
    
    // Application Menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle:@"App" action:nil keyEquivalent:@""];
    {
        NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"App"];
        
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"About HCX") action:@selector(domenu:) keyEquivalent:@""];
            [appMenu addItem:menuItem];
        }
        [appMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Preferences…") action:@selector(domenu:) keyEquivalent:@""];
            [appMenu addItem:menuItem];
        }
        [appMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Hide HCX") action:@selector(domenu:) keyEquivalent:@"h"];
            [appMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Hide Others") action:@selector(domenu:) keyEquivalent:@"^h"];
            [appMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Show All") action:@selector(domenu:) keyEquivalent:@""];
            [appMenu addItem:menuItem];
        }
        [appMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Quit HCX") action:@selector(domenu:) keyEquivalent:@"q"];
            [appMenu addItem:menuItem];
        }
        
        [appMenuItem setSubmenu:appMenu];
    }
    
    // File Menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"File") action:nil keyEquivalent:@""];
    {
        NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:MENUNAME(@"File")];
        
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"New Stack…") action:@selector(domenu:) keyEquivalent:@""];
            [fileMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Open Stack…") action:@selector(domenu:) keyEquivalent:@"o"];
            [fileMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Open Recent Stack") action:@selector(domenu:) keyEquivalent:@""];
            NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"submenu"];
            [menuItem setSubmenu:subMenu];
            [fileMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Close Stack") action:@selector(domenu:) keyEquivalent:@"w"];
            [fileMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Save a Copy…") action:@selector(domenu:) keyEquivalent:@""];
            [fileMenu addItem:menuItem];
        }
        [fileMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Compact Stack") action:@selector(domenu:) keyEquivalent:@""];
            [fileMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Protect Stack…") action:@selector(domenu:) keyEquivalent:@""];
            [fileMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Delete Stack…") action:@selector(domenu:) keyEquivalent:@""];
            [fileMenu addItem:menuItem];
        }
        [fileMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Print…") action:@selector(domenu:) keyEquivalent:@"p"];
            [fileMenu addItem:menuItem];
        }
        
        [fileMenuItem setSubmenu:fileMenu];
    }
    
    // Edit Menu
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Edit") action:nil keyEquivalent:@""];
    {
        NSMenu *editMenu = [[NSMenu alloc] initWithTitle:MENUNAME(@"Edit")];
        
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Undo") action:@selector(domenu:) keyEquivalent:@"z"];
            [editMenu addItem:menuItem];
        }
        [editMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Cut") action:@selector(domenu:) keyEquivalent:@"x"];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Copy") action:@selector(domenu:) keyEquivalent:@"c"];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Paste") action:@selector(domenu:) keyEquivalent:@"v"];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Delete") action:@selector(domenu:) keyEquivalent:@""];
            [editMenu addItem:menuItem];
        }
        [editMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"New Card") action:@selector(domenu:) keyEquivalent:@"n"];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Delete Card") action:@selector(domenu:) keyEquivalent:@""];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Copy Card") action:@selector(domenu:) keyEquivalent:@""];
            [editMenu addItem:menuItem];
        }
        [editMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Background") action:@selector(domenu:) keyEquivalent:@"b"];
            [editMenu addItem:menuItem];
        }
        [editMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Icon…") action:@selector(domenu:) keyEquivalent:@"i"];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Sound…") action:@selector(domenu:) keyEquivalent:@""];
            [editMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Resource…") action:@selector(domenu:) keyEquivalent:@""];
            [editMenu addItem:menuItem];
        }
        
        [editMenuItem setSubmenu:editMenu];
    }
    
    // Go Menu
    NSMenuItem *goMenuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Go") action:nil keyEquivalent:@""];
    {
        NSMenu *goMenu = [[NSMenu alloc] initWithTitle:MENUNAME(@"Go")];
        
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Back") action:@selector(domenu:) keyEquivalent:@"~"];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Home") action:@selector(domenu:) keyEquivalent:@""]; //h
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Help") action:@selector(domenu:) keyEquivalent:@""];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Recent") action:@selector(domenu:) keyEquivalent:@""];
            [goMenu addItem:menuItem];
        }
        [goMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"First") action:@selector(domenu:) keyEquivalent:@"1"];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Prev") action:@selector(domenu:) keyEquivalent:@"2"];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Next") action:@selector(domenu:) keyEquivalent:@"3"];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Last") action:@selector(domenu:) keyEquivalent:@"4"];
            [goMenu addItem:menuItem];
        }
        [goMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Find…") action:@selector(domenu:) keyEquivalent:@""];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Message") action:@selector(domenu:) keyEquivalent:@"m"];
            [goMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Next Window") action:@selector(domenu:) keyEquivalent:@"l"];
            [goMenu addItem:menuItem];
        }
        
        [goMenuItem setSubmenu:goMenu];
    }
    
    // Tools Menu
    NSMenuItem *toolsMenuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Tools") action:nil keyEquivalent:@""];
    {
        NSMenu *toolMenu = [[NSMenu alloc] initWithTitle:MENUNAME(@"Tools")];
        
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Show Tools Palette") action:@selector(domenu:) keyEquivalent:@"t"];
            [toolMenu addItem:menuItem];
        }
        /*[toolMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Browse") action:@selector(domenu:) keyEquivalent:@""];
            [toolMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Button") action:@selector(domenu:) keyEquivalent:@""];
            [toolMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Field") action:@selector(domenu:) keyEquivalent:@""];
            [toolMenu addItem:menuItem];
        }*/
        
        [toolsMenuItem setSubmenu:toolMenu];
    }
    
    // Objects Menu
    NSMenuItem *objectsMenuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Objects") action:nil keyEquivalent:@""];
    {
        NSMenu *objectsMenu = [[NSMenu alloc] initWithTitle:MENUNAME(@"Objects")];
        
        {
            //NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Button Info…") action:@selector(domenu:) keyEquivalent:@""];
            //[objectsMenu addItem:menuItem];
            
            //menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Field Info…") action:@selector(domenu:) keyEquivalent:@""];
            //[objectsMenu addItem:menuItem];
            
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Card Info…") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Background Info…") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Stack Info…") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
        }
        [objectsMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Bring Closer") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"Send Farther") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
        }
        [objectsMenu addItem:[NSMenuItem separatorItem]];
        {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"New Button") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"New Field") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:MENUNAME(@"New Background") action:@selector(domenu:) keyEquivalent:@""];
            [objectsMenu addItem:menuItem];
        }
        
        [objectsMenuItem setSubmenu:objectsMenu];
    }
    
    // Set Menus to App
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main"];
    [mainMenu addItem:appMenuItem];
    [mainMenu addItem:fileMenuItem];
    [mainMenu addItem:editMenuItem];
    [mainMenu addItem:goMenuItem];
    [mainMenu addItem:toolsMenuItem];
    [mainMenu addItem:objectsMenuItem];
    [[NSApplication sharedApplication] setMainMenu:mainMenu];
}
@end
