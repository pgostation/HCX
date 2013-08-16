//
//  main.m
//  HCX
//
//  Created by pgo on 2013/03/28.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HCXAppDelegate.h"

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc, (const char **)argv);
}

int NSApplicationMain(int argc, const char *argv[])
{
    HCXAppDelegate * delegate = [[HCXAppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    
    return 0;
}