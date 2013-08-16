//
//  HCXScript.m
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXScript.h"

#import "HCXToolPanel.h"
#import "HCXAuthoringPanel.h"
#import "HCXUIButton.h"
#import "HCXUIPopup.h"
#import "HCXUIField.h"

static NSMutableDictionary *GlobalVariable;
static NSDictionary *GlobalVariable_forOtherTask;
static BOOL inAuthoringMode;

@implementation HCXScript
{
    NSInteger curCardId;
}

+ (NSDictionary *) getGlobals
{
    return GlobalVariable_forOtherTask;
}

- (HCXScript *) initWithStackEnv:(StackEnv *) stackEnv
{
    self = [super init];
    if (self) {
        curCardId = stackEnv.stack.firstCardID;
        
        if(GlobalVariable==nil)
        {
            GlobalVariable = [[NSMutableDictionary alloc] init];
            [GlobalVariable setObject:@"browse" forKey:@"selectedtool"];
            
            GlobalVariable_forOtherTask = [GlobalVariable copy];
        }
    }
    
    return self;
}

- (void) doMsg: (NSString *)msg force: (BOOL)force stackEnv:(StackEnv *) stackEnv
{
    if([msg isEqualToString:@"go prev"])
    {
        NSInteger prevCardId = [self prevCardId:stackEnv];
        [stackEnv.cardView openCard:stackEnv cardId:prevCardId];
        curCardId = prevCardId;
        if(inAuthoringMode)
        {
            [HCXAuthoringPanel setData:nil];
        }
        return;
    }
    if([msg isEqualToString:@"go next"])
    {
        NSInteger nextCardId = [self nextCardId:stackEnv];
        [stackEnv.cardView openCard:stackEnv cardId:nextCardId];
        curCardId = nextCardId;
        if(inAuthoringMode)
        {
            [HCXAuthoringPanel setData:nil];
        }
        return;
    }
    if([msg isEqualToString:@"go this card"])
    {
        [stackEnv.cardView openCard:stackEnv cardId:curCardId];
        return;
    }
    if([msg isEqualToString:@"show tool window"])
    {
        [stackEnv showToolWindow];
        return;
    }
    if([msg isEqualToString:@"select browse tool"])
    {
        [GlobalVariable setObject:@"browse" forKey:@"selectedtool"];
        GlobalVariable_forOtherTask = [GlobalVariable copy];
        [HCXToolPanel selectTool:@"browse"];
        [HCXAuthoringPanel setData:nil];
        [HCXUIButton setDrawBorder:NO];
        [HCXUIField setDrawBorder:NO];
        [stackEnv.cardView setNeedsDisplay:YES];
        inAuthoringMode = NO;
        return;
    }
    if([msg isEqualToString:@"select button tool"])
    {
        [GlobalVariable setObject:@"button" forKey:@"selectedtool"];
        GlobalVariable_forOtherTask = [GlobalVariable copy];
        [HCXToolPanel selectTool:@"button"];
        [HCXAuthoringPanel setData:nil];
        [HCXUIButton setDrawBorder:YES];
        [HCXUIField setDrawBorder:NO];
        [stackEnv.cardView setNeedsDisplay:YES];
        inAuthoringMode = YES;
        return;
    }
    if([msg isEqualToString:@"select field tool"])
    {
        [GlobalVariable setObject:@"field" forKey:@"selectedtool"];
        GlobalVariable_forOtherTask = [GlobalVariable copy];
        [HCXToolPanel selectTool:@"field"];
        [HCXAuthoringPanel setData:nil];
        [HCXUIButton setDrawBorder:NO];
        [HCXUIField setDrawBorder:YES];
        [stackEnv.cardView setNeedsDisplay:YES];
        inAuthoringMode = YES;
        return;
    }
    if([msg isEqualToString:@"select paint tool"])
    {
        [GlobalVariable setObject:@"paint" forKey:@"selectedtool"];
        GlobalVariable_forOtherTask = [GlobalVariable copy];
        [HCXToolPanel selectTool:@"paint"];
        [HCXAuthoringPanel setData:nil];
        [HCXUIButton setDrawBorder:NO];
        [HCXUIField setDrawBorder:NO];
        [stackEnv.cardView setNeedsDisplay:YES];
        inAuthoringMode = NO;
        return;
    }
    if([msg isEqualToString:@"show stack info"])
    {
        [HCXAuthoringPanel setData:stackEnv.stack];
        return;
    }
}

- (NSInteger) currentCardId
{
    return curCardId;
}

- (NSInteger) prevCardId:(StackEnv *) stackEnv
{
    NSInteger prevCardId = -1;
    for(HCXCard *card in stackEnv.stack.cardList)
    {
        if(card.pid == curCardId)
        {
            if(prevCardId!=-1) return prevCardId; //見つかった次のカードID
        }
        prevCardId = card.pid;
    }
    
    //最後のカードID
    return prevCardId;
}

- (NSInteger) nextCardId:(StackEnv *) stackEnv
{
    bool flag = false;
    for(HCXCard *card in stackEnv.stack.cardList)
    {
        if(flag) return card.pid; //見つかった次のカードID
        if(card.pid == curCardId)
        {
            flag = true;
        }
    }
    
    if(flag){
         //最初のカードID
        HCXCard *card = [stackEnv.stack.cardList objectAtIndex:0];
        return card.pid;
    }
    
    return -1;
}

@end
