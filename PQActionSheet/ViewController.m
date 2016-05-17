//
//  ViewController.m
//  PQActionSheet
//
//  Created by Mac on 16/5/17.
//  Copyright © 2016年 Gap. All rights reserved.
//

#import "ViewController.h"
#import "WCActionSheet.h"

@interface ViewController () <WCActionSheetDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)pressBlockButtonAction:(UIButton *)sender {
    WCActionSheet *actionSheet = [[WCActionSheet alloc] init];
    NSInteger titleIndex = [actionSheet addButtonWithTitle:@"Title"];
    [actionSheet addButtonWithTitle:@"HELLO " actionBlock:^{
        NSLog(@"HELLO");
    }];
    [actionSheet addButtonWithTitle:@"SOMEONE LIKE YOU" actionBlock:^{
        NSLog(@"SOMEONE LIKE YOU");
    }];
    
    [actionSheet addButtonWithTitle:@"BEAUTIFUL IN WHITE" actionBlock:^{
        NSLog(@"BEAUTIFUL IN WHITE");
    }];
    
    [actionSheet setButtonTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14],
                                           NSForegroundColorAttributeName:[UIColor blackColor]}
                                forState:UIControlStateNormal];
    [actionSheet setButtonTextAttributes:@{NSForegroundColorAttributeName:[UIColor grayColor]}      withIndex:titleIndex
                                   state:UIControlStateNormal];
    [actionSheet show];
}

- (IBAction)pressDelegateButtonAction:(UIButton *)sender {
    WCActionSheet *actionSheet = [[WCActionSheet alloc] initWithDelegate:self cancelButtonTitle:@"Cancel" title:@"DELEGATE TITLE" otherButtonTitles:@"HELLO",@"WORLD",@"HELLO WORLD", nil];
    [actionSheet show];
}

#pragma mark - WCActionSheetDelegate 

- (void)actionSheet:(WCActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"BUTTON INDEX = %ld button index of title = %@",(long)buttonIndex,[actionSheet buttonTitleAtIndex:buttonIndex]);
}

@end
