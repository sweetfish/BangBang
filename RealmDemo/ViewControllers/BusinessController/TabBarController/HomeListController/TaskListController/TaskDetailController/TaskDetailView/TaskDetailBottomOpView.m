//
//  TaskDetailBottomOpView.m
//  RealmDemo
//
//  Created by lottak_mac2 on 16/8/2.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import "TaskDetailBottomOpView.h"
#import "TaskModel.h"
#import "UserManager.h"

@interface TaskDetailBottomOpView () {
    TaskModel *_taskModel;
    UserManager *_userManager;
}

@end

@implementation TaskDetailBottomOpView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _userManager = [UserManager manager];
    }
    return self;
}

- (void)dataDidChange {
    _taskModel = self.data;
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    Employee *employee = [_userManager getEmployeeWithGuid:_userManager.user.user_guid companyNo:_taskModel.company_no];
    //如果是负责人
    if([_taskModel.incharge isEqualToString:employee.employee_guid]) {
        if(_taskModel.status == 1) {//接收
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(10, 0, MAIN_SCREEN_WIDTH - 20, 30);
            [btn setTitle:@"接收" forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn.layer.cornerRadius = 5;
            btn.clipsToBounds = YES;
            [btn addTarget:self action:@selector(acceptClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
        } else if (_taskModel.status == 2) {//提交
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(10, 0, MAIN_SCREEN_WIDTH - 20, 30);
            [btn setTitle:@"提交" forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn.layer.cornerRadius = 5;
            btn.clipsToBounds = YES;
            [btn addTarget:self action:@selector(submitClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
        } else if (_taskModel.status == 6) {//提交
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(10, 0, MAIN_SCREEN_WIDTH - 20, 30);
            [btn setTitle:@"提交" forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn.layer.cornerRadius = 5;
            btn.clipsToBounds = YES;
            [btn addTarget:self action:@selector(submitClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
        }
    }
    //如果是创建者
    if([_taskModel.createdby isEqualToString:employee.employee_guid]) {
        if(_taskModel.status == 1) {//终止 编辑
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(10, 0, (MAIN_SCREEN_WIDTH - 30) / 2.f, 30);
            [btn setTitle:@"终止" forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn.layer.cornerRadius = 5;
            btn.clipsToBounds = YES;
            [btn addTarget:self action:@selector(stopClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            
            UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn1.frame = CGRectMake(CGRectGetMaxX(btn.frame) + 10, 0, (MAIN_SCREEN_WIDTH - 30) / 2.f, 30);
            [btn1 setTitle:@"编辑" forState:UIControlStateNormal];
            [btn1 setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn1.layer.cornerRadius = 5;
            btn1.clipsToBounds = YES;
            [btn1 addTarget:self action:@selector(updateClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn1];
        } else if (_taskModel.status == 2) {//终止 通过
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(10, 0, (MAIN_SCREEN_WIDTH - 30) / 2.f, 30);
            [btn setTitle:@"终止" forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn.layer.cornerRadius = 5;
            btn.clipsToBounds = YES;
            [btn addTarget:self action:@selector(stopClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            
            UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn1.frame = CGRectMake(CGRectGetMaxX(btn.frame) + 10, 0, (MAIN_SCREEN_WIDTH - 30) / 2.f, 30);
            [btn1 setTitle:@"完结" forState:UIControlStateNormal];
            [btn1 setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn1.layer.cornerRadius = 5;
            btn1.clipsToBounds = YES;
            [btn1 addTarget:self action:@selector(passClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn1];
        } else if (_taskModel.status == 4) {//退回 通过 终止
            UIButton *returnBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            returnBtn.frame = CGRectMake(10, 0, (MAIN_SCREEN_WIDTH - 40) / 3 , 30);
            [returnBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [returnBtn setTitle:@"退回" forState:UIControlStateNormal];
            [returnBtn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            returnBtn.layer.cornerRadius = 3;
            returnBtn.clipsToBounds = YES;
            [returnBtn addTarget:self action:@selector(returnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:returnBtn];
            
            UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            stopBtn.frame = CGRectMake(CGRectGetMaxX(returnBtn.frame) + 10 , 0, (MAIN_SCREEN_WIDTH - 40) / 3 , 30);
            [stopBtn setTitle:@"终止" forState:UIControlStateNormal];
            [stopBtn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            stopBtn.layer.cornerRadius = 3;
            stopBtn.clipsToBounds = YES;
            [stopBtn addTarget:self action:@selector(stopClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:stopBtn];
            
            UIButton *passBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [passBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            passBtn.frame = CGRectMake(CGRectGetMaxX(stopBtn.frame) + 10, 0, (MAIN_SCREEN_WIDTH - 40) / 3, 30);
            [passBtn setTitle:@"通过" forState:UIControlStateNormal];
            [passBtn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            passBtn.layer.cornerRadius = 3;
            passBtn.clipsToBounds = YES;
            [passBtn addTarget:self action:@selector(passClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:passBtn];
        } else if (_taskModel.status == 6) {//终止 完结
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(10, 0, (MAIN_SCREEN_WIDTH - 30) / 2, 30);
            [btn setTitle:@"终止" forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn.layer.cornerRadius = 5;
            btn.clipsToBounds = YES;
            [btn addTarget:self action:@selector(stopClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            
            UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn1.frame = CGRectMake(CGRectGetMaxX(btn.frame) + 10, 0, (MAIN_SCREEN_WIDTH - 30) / 2.f, 30);
            [btn1 setTitle:@"完结" forState:UIControlStateNormal];
            [btn1 setBackgroundColor:[UIColor colorWithRed:10/255.f green:185/255.f blue:153/255.f alpha:1]];
            btn1.layer.cornerRadius = 5;
            btn1.clipsToBounds = YES;
            [btn1 addTarget:self action:@selector(passClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn1];
        }
    }
}
//编辑
- (void)updateClicked:(UIButton*)btn {
    if(self.delegate && [self.delegate respondsToSelector:@selector(updateClicked:)]) {
        [self.delegate updateClicked:btn];
    }
}
//接收
- (void)acceptClicked:(UIButton*)btn {
    if(self.delegate && [self.delegate respondsToSelector:@selector(acceptClicked:)]) {
        [self.delegate acceptClicked:btn];
    }
}
//终止
- (void)stopClicked:(UIButton*)btn {
    if(self.delegate && [self.delegate respondsToSelector:@selector(stopClicked:)]) {
        [self.delegate stopClicked:btn];
    }
}
//退回
- (void)returnClicked:(UIButton*)btn {
    if(self.delegate && [self.delegate respondsToSelector:@selector(returnClicked:)]) {
        [self.delegate returnClicked:btn];
    }
}
//通过
- (void)passClicked:(UIButton*)btn {
    if(self.delegate && [self.delegate respondsToSelector:@selector(passClicked:)]) {
        [self.delegate passClicked:btn];
    }
}
//提交
- (void)submitClicked:(UIButton*)btn {
    if(self.delegate && [self.delegate respondsToSelector:@selector(submitClicked:)]) {
        [self.delegate submitClicked:btn];
    }
}
@end
