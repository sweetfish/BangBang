//
//  RepCalendarEditController.m
//  RealmDemo
//
//  Created by lottak_mac2 on 16/7/20.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import "RepCalendarEditController.h"
#import "SelectDateController.h"
#import "Employee.h"
#import "CalendarSelectAlertTime.h"
#import "RepCalendarView.h"
#import "MuliteSelectController.h"
#import "CalendarRepSelect.h"
#import "Calendar.h"
#import "UserManager.h"
#import "UserHttp.h"

@interface RepCalendarEditController ()<MuliteSelectDelegate,CalendarRepSelectDelegate,RepCalendarViewDelegate>{
    RepCalendarView *_repCalendarView;
    Calendar *_calendar;
    UserManager *_userManager;
}

@end

@implementation RepCalendarEditController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"日程编辑";
    _userManager = [UserManager manager];
    _repCalendarView = [[RepCalendarView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT)];
    _repCalendarView.data = _calendar;
    _repCalendarView.delegate = self;
    _repCalendarView.isDetail = NO;
    _repCalendarView.isEdit = YES;
    [self.view addSubview:_repCalendarView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(rightClicked:)];
    //确定按钮是否能够被点击
    RACSignal *nameSignal = RACObserve(_calendar, event_name);
    RAC(self.navigationItem.rightBarButtonItem,enabled) = [nameSignal map:^(NSString* name) {
        if([NSString isBlank:name])
            return @(NO);
        return @(YES);
    }];
    // Do any additional setup after loading the view.
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)dataDidChange {
    _calendar = [self.data deepCopy];
}
- (void)rightClicked:(UIBarButtonItem*)item {
    [self.view endEditing:YES];
    if([NSString isBlank:_calendar.event_name]) {
        [self.navigationController.view showMessageTips:@"请填写事务名称"];
        return;
    }
    if(_calendar.r_end_date_utc < _calendar.r_begin_date_utc) {
        [self.navigationController.view showMessageTips:@"重复开始时间不能晚于重复结束时间"];
        return;
    }
    Scheduler * s = [[Scheduler alloc] initWithDate:[NSDate dateWithTimeIntervalSince1970:_calendar.begindate_utc/1000] andRule:_calendar.rrule];
    //得到所有的时间 起始时间不会算在里面（*）
    NSArray * occurences = [s occurencesBetween:[NSDate dateWithTimeIntervalSince1970:_calendar.r_begin_date_utc/1000] andDate:[NSDate dateWithTimeIntervalSince1970:_calendar.r_end_date_utc/1000]];
    int count = occurences.count;
    if(count == 0) {
        [self.navigationController.view showMessageTips:@"重复间隔应小于重复时间段"];
        return;
    }
    NSDate *firstDate = occurences[0];
    if(firstDate.timeIntervalSince1970 < (_calendar.r_begin_date_utc / 1000))
        count -- ;
    if(count == 0) {
        [self.navigationController.view showMessageTips:@"重复间隔应小于重复时间段"];
        return;
    }
    //修改日程
    [UserHttp updateUserCalendar:_calendar handler:^(id data, MError *error) {
        [self.navigationController.view dismissTips];
        if(error) {
            if(error.statsCode == -1009) {//断网也可以操作，只是离线的而已
                _calendar.needSync = YES;
                _calendar.updated_by = _userManager.user.user_guid;
                _calendar.updatedon_utc = [NSDate date].timeIntervalSince1970 * 1000;
                if(self.delegate && [self.delegate respondsToSelector:@selector(RepCalendarEdit:)])
                    [self.delegate RepCalendarEdit:_calendar];
                [_userManager updateCalendar:_calendar];
                [self.navigationController popViewControllerAnimated:YES];
                return ;
            }
            [self.navigationController.view showFailureTips:error.statsMsg];
            return ;
        }
        if(self.delegate && [self.delegate respondsToSelector:@selector(RepCalendarEdit:)])
            [self.delegate RepCalendarEdit:_calendar];
        [_userManager updateCalendar:_calendar];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark --
#pragma mark -- RepCalendarViewDelegate
//例行开始时间
- (void)RepCalendarViewBegin {
    SelectDateController *select = [SelectDateController new];
    select.datePickerMode = UIDatePickerModeTime;
    select.selectDateBlock = ^(NSDate *date) {
        _calendar.begindate_utc = [date timeIntervalSince1970] * 1000;
        //结束时间自动加30分钟
        _calendar.enddate_utc = [date timeIntervalSince1970] * 1000 + 1000 * 30 * 60;
        _repCalendarView.data = _calendar;
    };
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
}
//例行结束时间
- (void)RepCalendarViewEnd {
    SelectDateController *select = [SelectDateController new];
    select.datePickerMode = UIDatePickerModeTime;
    select.selectDateBlock = ^(NSDate *date) {
        _calendar.enddate_utc = [date timeIntervalSince1970] * 1000;
        _repCalendarView.data = _calendar;
    };
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
}
//重复性选择
- (void)RepCalendarSelectRep {
    CalendarRepSelect *select = [CalendarRepSelect new];
    select.delegate = self;
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
}
-(void)calendarRepSelect:(EKRecurrenceRule *)eKRecurrenceRule {
    _calendar.repeat_type = eKRecurrenceRule.frequency + 1;
    _calendar.rrule = [eKRecurrenceRule rRuleString];
    _repCalendarView.data = _calendar;
}
//例行重复时间开始
- (void)RepCalendarViewRepBegin {
    SelectDateController *select = [SelectDateController new];
    select.datePickerMode = UIDatePickerModeDate;
    select.selectDateBlock = ^(NSDate *date) {
        _calendar.r_begin_date_utc = [date timeIntervalSince1970] * 1000;
        _repCalendarView.data = _calendar;
    };
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
}
//例行重复时间结束
- (void)RepCalendarViewRepEnd {
    SelectDateController *select = [SelectDateController new];
    select.datePickerMode = UIDatePickerModeDate;
    select.selectDateBlock = ^(NSDate *date) {
        _calendar.r_end_date_utc = [date timeIntervalSince1970] * 1000;
        _repCalendarView.data = _calendar;
    };
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
}
//一般事务事前提醒
- (void)ComCanendarAlertBefore {
    CalendarSelectAlertTime *select = [CalendarSelectAlertTime new];
    select.calendarSelectTime = ^(int date) {
        _calendar.alert_minutes_before = date;
        _calendar.is_alert = YES;
        _repCalendarView.data = _calendar;
    };
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
    
}
//一般事务事后提醒
- (void)ComCanendarAlertAfter {
    CalendarSelectAlertTime *select = [CalendarSelectAlertTime new];
    select.calendarSelectTime = ^(int date) {
        _calendar.alert_minutes_after = date;
        _calendar.is_alert = YES;
        _repCalendarView.data = _calendar;
    };
    select.providesPresentationContextTransitionStyle = YES;
    select.definesPresentationContext = YES;
    select.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:select animated:NO completion:nil];
}
//一般事务事后分享
- (void)ComCanendarShare {
    MuliteSelectController *mulite = [MuliteSelectController new];
    Employee *employee = [_userManager getEmployeeWithGuid:_userManager.user.user_guid companyNo:_userManager.user.currCompany.company_no];
    mulite.outEmployees = [@[employee] mutableCopy];
    mulite.delegate = self;
    [self.navigationController pushViewController:mulite animated:YES];
}
#pragma mark --
#pragma mark -- MuliteSelectDelegate
//多选回调
- (void)muliteSelect:(NSMutableArray<Employee*>*)employeeArr {
    NSMutableArray *guidArr = [@[] mutableCopy];
    NSMutableArray *nameArr = [@[] mutableCopy];
    for (Employee *employee in employeeArr) {
        [guidArr addObject:employee.user_guid];
        [nameArr addObject:employee.real_name];
    }
    //如果有数据，就要加上自己（应付服务器）
    if(employeeArr.count) {
        [guidArr addObject:[UserManager manager].user.user_guid];
        [nameArr addObject:[UserManager manager].user.real_name];
    }
    _calendar.members = [guidArr componentsJoinedByString:@","];
    _calendar.member_names = [nameArr componentsJoinedByString:@","];
    _repCalendarView.data = _calendar;
}

@end

