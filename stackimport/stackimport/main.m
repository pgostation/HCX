//
//  main.m
//  stackimport
//
//  Created by pgo on 2013/03/30.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HCXSIAppDelegate.h"
#import "HCXstackimport.h"

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc, (const char **)argv);
}

int NSApplicationMain(int argc, const char *argv[])
{
    NSLog(@"starting stackimport");
    
    
    // argments
    {
        const char *path = NULL;
        //BOOL nowin = NO;
        
        for(int i=0; i<argc; i++)
        {
            const char *cstr = argv[i];
            if(0==strcmp(cstr,"-i") && i+1<argc) // input file
            {
                i++;
                path = argv[i];
            }
            //else if(0==strcmp(cstr,"-NOWIN") && i+1<argc)
            //{
            //    nowin = YES;
            //}
        }
        
        
        if(path!=NULL)
        {
            NSString *x = [NSString stringWithCString:path encoding:NSUTF8StringEncoding];
            [x writeToFile:@"/Users/takayoshi/Documents/debug" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSLog(@"path = %s", path);
            /*BOOL result =*/ [[[HCXstackimport alloc] init] stackimport:[NSString stringWithCString:path encoding:NSUTF8StringEncoding]];
        }
    }
    
    // set delegate
    HCXSIAppDelegate *delegate = [[HCXSIAppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    
    return 0;
}
