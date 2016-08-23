//
//  ChangeUserName.m
//  BangBang
//
//  Created by lottak_mac2 on 16/5/20.
//  Copyright © 2016年 Lottak. All rights reserved.
//

#import "ChangeUserDetail.h"
#import "UserManager.h"

@interface ChangeUserDetail ()<UITextFieldDelegate>
{
    UITextField *_textField;
    UIScrollView *_scrollView;
    User *_currUser;
}
@end

@implementation ChangeUserDetail

- (void)viewDidLoad {
    [super viewDidLoad];
    _currUser = [[UserManager manager].user deepCopy];
    self.title = @"修改签名";
    self.view.backgroundColor = [UIColor whiteColor];
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT - 64)];
    _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _scrollView.contentSize = CGSizeMake(MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT + 0.5);
    [self.view addSubview:_scrollView];
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, MAIN_SCREEN_WIDTH - 40, 30)];
    _textField.delegate = self;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.placeholder = @"在这里写你的个性签名";
    _textField.text = _currUser.mood;
    [_scrollView addSubview:_textField];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(_textField.frame) + 10, MAIN_SCREEN_WIDTH - 40, 0.5)];
    line.backgroundColor = [UIColor grayColor];
    [_scrollView addSubview:line];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(line.frame) + 8, MAIN_SCREEN_WIDTH - 40, 10)];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor grayColor];
    label.text = @"设置一个个性的签名！可以展现你的风格！";
    [_scrollView addSubview:label];
    [self.view addSubview:_scrollView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(rightButtonClicked:)];
    //按钮是否能够被点击
    RAC(self.navigationItem.rightBarButtonItem,enabled) = [_textField.rac_textSignal map:^(NSString *mood) {
        if([NSString isBlank:mood])
            return @(NO);
        return @(YES);
    }];
    // Do any additional setup after loading the view from its nib.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)rightButtonClicked:(UIBarButtonItem*)item
{
    [self.view endEditing:YES];
    _currUser.mood = _textField.text;
    [self.delegate changeUserInfo:_currUser];
    [self.navigationController popViewControllerAnimated:YES];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
