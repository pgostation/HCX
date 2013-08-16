//
//  HCXDoMenu.m
//  HCX
//
//  Created by pgo on 2013/03/29.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import "HCXDoMenu.h"
#import "HCXReadXML.h"
#import "HCXStackData.h"
#import "StackEnv.h"
#import "HCXInternational.h"

@implementation HCXDoMenu
{
    NSTask *task;
    NSPipe *pipe;
}

- (HCXDoMenu *) init
{
	if(( self = [super init] ))
	{
    }
    
    return self;
}

//-------------------------------------------------------
// DoMenu
//-------------------------------------------------------
- (void) domenu: (NSString *)menuName
{
    // --------------
    // -- APP MENU --
    // --------------
    if(MENUCOMP(menuName,@"Quit HCX"))
    {
        // quit
        [[NSApplication sharedApplication] terminate:self];
    }
    
    // ---------------
    // -- FILE MENU --
    // ---------------
    if(MENUCOMP(menuName,@"Open Stack…"))
    {
        NSOpenPanel* openPanel;
        //NSArray *fileTypes = [NSArray arrayWithObjects:@"txt", nil]; // 開けるファイルを拡張子で制限する
        
        openPanel = [NSOpenPanel openPanel];
        
        [openPanel beginSheetModalForWindow:nil completionHandler:^(NSInteger returnCode) {
            if (returnCode == NSOKButton){
                NSURL *pathToFile = nil;
                pathToFile = [[openPanel URLs] objectAtIndex:0];
                [self open:pathToFile];
            }
        }];
    }
    
    // -------------
    // -- GO MENU --
    // -------------
    if(MENUCOMP(menuName,@"Prev"))
    {
        [HCXDoMenu sendMessageToCurCard:@"go prev" force:YES];
    }
    else if(MENUCOMP(menuName,@"Next"))
    {
        [HCXDoMenu sendMessageToCurCard:@"go next" force:YES];
    }
    else if(MENUCOMP(menuName,@"First"))
    {
        [HCXDoMenu sendMessageToCurCard:@"go first" force:YES];
    }
    else if(MENUCOMP(menuName,@"Last"))
    {
        [HCXDoMenu sendMessageToCurCard:@"go last" force:YES];
    }
    
    // -------------
    // -- TOOLS MENU --
    // -------------
    if(MENUCOMP(menuName,@"Show Tools Palette"))
    {
        [HCXDoMenu sendMessageToCurCard:@"show tool window" force:YES];
    }
    
    // -------------
    // -- OBJECTS MENU --
    // -------------
    if(MENUCOMP(menuName,@"Stack Info…"))
    {
        [HCXDoMenu sendMessageToCurCard:@"show stack info" force:YES];
    }
}

//-------------------------------------------------------
// send message
//-------------------------------------------------------
+ (void) sendMessageToCurCard: (NSString *)msg force: (BOOL)force
{
    StackEnv *stackEnv = [StackEnv currentStackEnv];
    [stackEnv sendMessageToCurCard:msg force:force];
}

//-------------------------------------------------------
// File Menu
//-------------------------------------------------------
- (void) open: (NSURL *)pathToFile
{
    if(pathToFile==nil){
        NSLog(@"### open: pathToFile==nil ###");
        return;
    }
    
    for(StackEnv *stackEnv in [StackEnv getStackEnvList])
    {
        if([stackEnv.stack.dirPath isEqualToString:[pathToFile path]])
        {
            // 既に開いている
            [stackEnv.cardWindow makeKeyAndOrderFront:nil];
            return;
        }
    }
    
    NSString *dirPath = [pathToFile path];
	NSLog(@"open: %@", dirPath);
    
    // HCXのファイルを開く
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *xmlPath = [dirPath stringByAppendingPathComponent:@"_stack.xml"];
    if([fileManager fileExistsAtPath:xmlPath]==YES){
        [self openFile:dirPath];
    }
    // Import HyperCard Stack
    else if([[NSWorkspace sharedWorkspace] launchApplication:@"stackimport.app"]==YES)
    {
        // open file
        [[NSWorkspace sharedWorkspace] openFile:dirPath withApplication:@"stackimport.app"];
        
        // receive notification
        NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(endStackImport:) name:@"endStackImport" object:nil];
        
        // activate
        NSArray* apps = [NSRunningApplication
                         runningApplicationsWithBundleIdentifier:@"pgostation.stackimport"];
        [(NSRunningApplication*)[apps objectAtIndex:0] activateWithOptions: NSApplicationActivateAllWindows];
    }
}

// selector @ global notification "endStackImport"
- (void) endStackImport:(NSNotification *)notification
{
    NSString *dirPath = [[notification userInfo] objectForKey:@"dirPath"];
	NSLog(@"dirPath: %@", dirPath);
    
    // remove - receive Notification
    NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:@"endStackImport" object:nil];
    
    [self openFile:dirPath];
}

- (void) openFile:(NSString *)dirPath
{
    StackEnv *stackEnv = [[StackEnv alloc] init];
    
    HCXStackData *stack = [[[HCXReadXML alloc] init] read:dirPath stackEnv:stackEnv];
    
    [stackEnv open:stack];
}


@end
