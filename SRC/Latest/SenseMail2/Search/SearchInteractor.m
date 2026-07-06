//
//  searchInteractor.m
//  SenseMailShare
//
//  Created by Sergey on 21.09.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "SearchInteractor.h"
#import "SearchViewController.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"

@implementation SearchInteractor


-(void)showSearchInVC:(UINavigationController *)nav
{
    SearchViewController* vc = [[SearchViewController alloc] initWithNibName:@"SearchViewController" bundle:nil];
    vc.interactor = self;
    self.vc = vc;
    
    /* // Push from left to right
    CATransition *transition = [CATransition animation];
    transition.duration = 0.45;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    //transition.delegate = nav;
    [nav.view.layer addAnimation:transition forKey:nil];
    [nav pushViewController:vc animated:NO];
    */
    [nav pushViewController:vc animated:YES];// presentViewController:vc animated:YES completion:^{
        // vc is dead here...
        //NSLog(@"returned %@",vc.emailSettings.imapServer);
    //}];
}

-(void)doSearch
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    [self searchWithType:self.vc.searchType text:self.vc.userInputSearch];
}

/*
-(void)doSearch
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    NSString* dateStr;
    switch (self.vc.searchType) {
        case stFlagged:
            //[GlobalRouter sharedManager].currentAccount = @""; // BUG!
            [[GlobalRouter sharedManager] needSearchWithString:filterStarred];
            break;
        case stAnswered:
            [[GlobalRouter sharedManager] needSearchWithString:filterAnswered];
            break;
        case stUnread:
            [[GlobalRouter sharedManager] needSearchWithString:filterUnread];
            break;
        case stImportant:
            [[GlobalRouter sharedManager] needSearchWithString:filterImportant];
            break;
        case stLarge:
            [[GlobalRouter sharedManager] needSearchWithString:filterLarge];
            break;
        case stWithAttachments:
            [[GlobalRouter sharedManager] needSearchWithString:filterAttachments];
            break;
        case stProtected:
            [[GlobalRouter sharedManager] needSearchWithString:filterProtected];
            break;
        case stDateBefore:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterBefore, self.vc.searchTextView.text]];
            break;
        case stDateAfter:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSince, self.vc.searchTextView.text]];
            break;
        case stDate:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterOn, self.vc.searchTextView.text]];
            break;
        case stUserInput:
            [[GlobalRouter sharedManager] needSearchWithString:self.vc.userInputSearch];
            break;
        case stLastWeek:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy/MM/dd"];
            NSDate* fromDate = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24*7)];
            dateStr = [formatter stringFromDate:fromDate];
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSince, dateStr]];
            break;
        }
        case stLastMonth:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy/MM/dd"];
            NSDate* fromDate = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24*31)];
            dateStr = [formatter stringFromDate:fromDate];
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSince, dateStr]];
            break;
        }
        case stInTheMonth:
        {
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterIn, self.vc.searchTextView.text]];
            break;
        }
        case stBwDates:
        {
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterBetween, self.vc.searchTextView.text]];
            break;
        }
        case stFrom:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterFromF, self.vc.searchTextView.text]];
            break;
        case stTo:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterTo, self.vc.searchTextView.text]];
            break;
        default:
            break;
    }
}*/

-(void)searchWithType:(searchTypes)stype text:(NSString*)text
{
    NSString* dateStr;
    switch (stype) {
        case stFlagged:
            //[GlobalRouter sharedManager].currentAccount = @""; // BUG!
            [[GlobalRouter sharedManager] needSearchWithString:filterStarred];
            break;
        case stAnswered:
            [[GlobalRouter sharedManager] needSearchWithString:filterAnswered];
            break;
        case stUnread:
            [[GlobalRouter sharedManager] needSearchWithString:filterUnread];
            break;
        case stImportant:
            [[GlobalRouter sharedManager] needSearchWithString:filterImportant];
            break;
        case stLarge:
            [[GlobalRouter sharedManager] needSearchWithString:filterLarge];
            break;
        case stWithAttachments:
            [[GlobalRouter sharedManager] needSearchWithString:filterAttachments];
            break;
        case stProtected:
            [[GlobalRouter sharedManager] needSearchWithString:filterProtected];
            break;
        case stDateBefore:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterBefore, text]];
            break;
        case stDateAfter:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSince, text]];
            break;
        case stDate:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterOn, text]];
            break;
        case stUserInput:
            [[GlobalRouter sharedManager] needSearchWithString:text];
            break;
        case stLastWeek:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy/MM/dd"];
            NSDate* fromDate = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24*7)];
            dateStr = [formatter stringFromDate:fromDate];
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSince, dateStr]];
            break;
        }
        case stLastMonth:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy/MM/dd"];
            NSDate* fromDate = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24*31)];
            dateStr = [formatter stringFromDate:fromDate];
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSince, dateStr]];
            break;
        }
        case stInTheMonth:
        {
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterIn, text]];
            break;
        }
        case stBwDates:
        {
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterBetween, text]];
            break;
        }
        case stFrom:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterFromF, text]];
            break;
        case stTo:
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterTo, text]];
            break;
        case stSizeMore:
        {
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterLargerThan, text]];
            break;
        }
        case stSizeLess:
        {
            [[GlobalRouter sharedManager] needSearchWithString:[NSString stringWithFormat:@"%@ %@", filterSmallerThan, text]];
            break;
        }
        default:
            break;
    }
}

-(void)cancelSearch
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    self.vc = nil;
}

-(void)searchStringChanged:(NSString*)searchStr
{
    //NSDate* dd = [CommonProcs dateFromString:searchStr];
    NSArray* dddd = [CommonProcs datesFromString:searchStr];
    if(dddd){
        NSDate* dd = dddd[0];
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
        NSString *dateS = [dateFormatter stringFromDate:dd];
        
        // Remove commands
        for (NSString* str in self.vc.dateElements) {
            [self.vc.elementCommands removeObjectForKey:str];
            [self.vc.imagesForSearch removeObjectForKey:str];
        }
        [self.vc.dateElements removeAllObjects];
        
        NSString* dateBeforeStr = [NSString stringWithFormat:@"Received before %@", dateS];
        [self.vc.dateElements addObject:dateBeforeStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stDateBefore] forKey:dateBeforeStr];
        [self.vc.imagesForSearch setObject:@"calendar" forKey:dateBeforeStr];
        
        NSString* dateOnStr = [NSString stringWithFormat:@"Received on %@", dateS];
        [self.vc.dateElements addObject:dateOnStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stDate] forKey:dateOnStr];
        [self.vc.imagesForSearch setObject:@"calendar" forKey:dateOnStr];
        
        NSString* dateAfterStr = [NSString stringWithFormat:@"Received after %@", dateS];
        [self.vc.dateElements addObject:dateAfterStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stDateAfter] forKey:dateAfterStr];
        [self.vc.imagesForSearch setObject:@"calendar" forKey:dateAfterStr];
        
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"LLLL YYYY"];
        NSString* month = [formatter stringFromDate:dd];
        NSString* dateInStr = [NSString stringWithFormat:@"Received in: %@", month];
        [self.vc.dateElements addObject:dateInStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stInTheMonth] forKey:dateInStr];
        [self.vc.imagesForSearch setObject:@"calendar" forKey:dateInStr];
        
        if (dddd.count == 2) {
            NSString* dateS2 = [dateFormatter stringFromDate:dddd[1]];
            if ([dddd[0] compare:dddd[1]] == NSOrderedDescending) { // date0 is later
                // Swap dates
                NSString* tmp = dateS;
                dateS = dateS2;
                dateS2 = tmp;
            }
            NSString* dateBwStr = [NSString stringWithFormat:@"From %@ to %@", dateS, dateS2];
            [self.vc.dateElements addObject:dateBwStr];
            [self.vc.elementCommands setValue:[NSNumber numberWithInt:stBwDates] forKey:dateBwStr];
            [self.vc.imagesForSearch setObject:@"calendar" forKey:dateBwStr];
        }
        
        [self.vc.searchTableView reloadData];
    }else{
        [self.vc.dateElements removeAllObjects];
        
        // Add search from?
        NSString* fromStr = [NSString stringWithFormat:@"From: %@", searchStr];
        [self.vc.dateElements addObject:fromStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stFrom] forKey:fromStr];
        [self.vc.imagesForSearch setObject:@"searchFrom" forKey:fromStr];
        
        NSString* toStr = [NSString stringWithFormat:@"To: %@", searchStr];
        [self.vc.dateElements addObject:toStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stTo] forKey:toStr];
        [self.vc.imagesForSearch setObject:@"searchTo" forKey:toStr];
        
        [self.vc.searchTableView reloadData];
    }
    long szzz = [CommonProcs longFromString:searchStr];
    if (szzz > 0) {
        NSString* fromStr = [NSString stringWithFormat:@"Larger than: %@", [CommonProcs getByteSizeRep:szzz]];
        [self.vc.dateElements addObject:fromStr];
        [self.vc.elementCommands setValue:[NSNumber numberWithInt:stSizeMore] forKey:fromStr];
        [self.vc.imagesForSearch setObject:@"moreCircle" forKey:fromStr];
    }
}

@end
