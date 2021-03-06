//
//  MainViewController.m
//  RealmDemo
//
//  Created by lottak_mac2 on 16/7/12.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import "MainViewController.h"
#import "IdentityManager.h"
#import "UserManager.h"
#import "GeTuiSdkManager.h"
#import "UserManager.h"
#import "UserHttp.h"
#import "LoginController.h"
#import "WelcomeController.h"
#import "BusinessController.h"

@interface MainViewController () {
    WelcomeController *_welcome;//欢迎界面
    LoginController *_login;//登录界面
    BusinessController *_business;//业务界面
    NSUserDefaults * defaults;
}
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    defaults = [NSUserDefaults standardUserDefaults];
    //从本地读取登录信息
    IdentityManager *manager = [IdentityManager manager];
    [manager readAuthorizeData];
    //保存当前的版本号
    manager.identity.lastSoftVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [manager saveAuthorizeData];
    [self gotoIdentityVC];
    //加上重新登录的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLogin:) name:@"ShowLogin" object:nil];
    //加上欢迎界面和登录界面的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(welcomeDidFinish) name:@"WelcomeDidFinish" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDidFinish) name:@"LoginDidFinish" object:nil];
}
//弹出登录控制器
- (void)showLogin:(NSNotification*)noti{
    //是否不需要弹窗
    if([NSString isBlank:noti.object]) {
        [self gotoIdentityVC];
        return;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:noti.object message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self gotoIdentityVC];
    }];
    [alertVC addAction:ok];
    [self presentViewController:alertVC animated:YES completion:nil];
}
//欢迎界面展示完毕
- (void)welcomeDidFinish {
    //设置登录信息的值
    IdentityManager *manager = [IdentityManager manager];
    manager.identity.firstUseSoft = NO;
    [manager saveAuthorizeData];
    //进入判断逻辑
    [self gotoIdentityVC];
}
//登录界面展示完毕
- (void)loginDidFinish {
    //进入判断逻辑
    [self gotoIdentityVC];
}
//进入判断逻辑
- (void)gotoIdentityVC {
    IdentityManager *identityManager = [IdentityManager manager];
    //需不需要迁移数据
    if([defaults.dictionaryRepresentation.allKeys containsObject:@"WelcomeViewReadssss"]) {
        [self addBGMView];
        [self.view showLoadingTips:@"迁移数据..."];
        //用FMDB来获取旧的数据 这里要注意了，因为上一位同事的数据库表设计，所以这里我们同步的思路如下
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"ReSearch.db"];
        FMDatabase *fMDatabase = [FMDatabase databaseWithPath:writableDBPath];
        [fMDatabase open];
        //是否存在登录用户 如果存在就同步 如果没有就不同步了直接登录
        NSData* data = [defaults objectForKey:@"BangBangUserInfo"];
        if(!data) {
            [defaults removeObjectForKey:@"WelcomeViewReadssss"];
            [self.view dismissTips];
            [self remBGMView];
            [self gotoIdentityVC];
            return;
        }
        identityManager.identity.accessToken = [defaults objectForKey:@"BangBangAccessToken"];
        NSDictionary *userDic = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        User *user = [User new];
        [user mj_setKeyValues:userDic];
        UserManager *userManager = [UserManager manager];
        //这里开始获取必要的信息 圈子、员工
        [userManager loadUserWithGuid:user.user_guid];
        [userManager updateUser:user];
        [UserHttp getCompanysUserGuid:user.user_guid handler:^(id data, MError *error) {
            if(error) {
                [self.navigationController dismissTips];
                [self remBGMView];
                [self gotoIdentityVC];
                return ;
            }
            NSMutableArray *companys = [@[] mutableCopy];
            for (NSDictionary *tempDic in data) {
                Company *company = [Company new];
                [company mj_setKeyValues:tempDic];
                [companys addObject:company];
            }
            [userManager updateCompanyArr:companys];
            if(companys.count != 0) {
                user.currCompany = [companys[0] deepCopy];
            }
            [userManager updateUser:user];
            [UserHttp getEmployeeCompnyNo:0 status:5 userGuid:user.user_guid handler:^(id data, MError *error) {
                if(error) {
                    [self.navigationController dismissTips];
                    [self remBGMView];
                    [self gotoIdentityVC];
                    return ;
                }
                NSMutableArray *array = [@[] mutableCopy];
                for (NSDictionary *dic in data[@"list"]) {
                    Employee *employee = [Employee new];
                    [employee mj_setKeyValues:dic];
                    [array addObject:employee];
                }
                [UserHttp getEmployeeCompnyNo:0 status:0 userGuid:user.user_guid handler:^(id data, MError *error) {
                    if(error) {
                        [self.navigationController dismissTips];
                        [self remBGMView];
                        [self gotoIdentityVC];
                        return ;
                    }
                    for (NSDictionary *dic in data[@"list"]) {
                        Employee *employee = [Employee new];
                        [employee mj_setKeyValues:dic];
                        [array addObject:employee];
                    }
                    [userManager updateEmployee:array companyNo:0];
                    //有登陆用户就同步日程
                    FMResultSet *calendarResultSet = [fMDatabase executeQuery:@"select * from tb_Calendar"];
                    while (calendarResultSet.next) {
                        @synchronized (self) {//必须原子操作
                            //要把这个日程放到哪个用户文件
                            NSString *currentUser = [calendarResultSet stringForColumn:@"currentUser"];
                            [userManager loadUserWithGuid:currentUser];
                            Calendar *calendar = [Calendar new];
                            calendar.id = [calendarResultSet stringForColumn:@"id"].intValue;
                            calendar.company_no = [calendarResultSet stringForColumn:@"company_no"].intValue;
                            calendar.event_name = [calendarResultSet stringForColumn:@"event_name"];
                            calendar.descriptionStr = [calendarResultSet stringForColumn:@"description"];
                            calendar.address = [calendarResultSet stringForColumn:@"address"];
                            calendar.begindate_utc = [calendarResultSet doubleForColumn:@"begindate_utc"];
                            calendar.enddate_utc = [calendarResultSet doubleForColumn:@"enddate_utc"];
                            calendar.is_allday = [calendarResultSet boolForColumn:@"is_allday"];
                            calendar.app_guid = [calendarResultSet stringForColumn:@"app_guid"];
                            calendar.target_id = [calendarResultSet stringForColumn:@"article_id"];
                            calendar.repeat_type = [calendarResultSet intForColumn:@"repeat_type"];
                            calendar.is_alert = [calendarResultSet boolForColumn:@"is_alert"];
                            calendar.alert_minutes_before = [calendarResultSet stringForColumn:@"alert_minutes_before"].intValue;
                            calendar.alert_minutes_after = [calendarResultSet stringForColumn:@"alert_minutes_after"].intValue;
                            calendar.user_guid = [calendarResultSet stringForColumn:@"user_guid"];
                            calendar.created_by = [calendarResultSet stringForColumn:@"created_by"];
                            calendar.createdon_utc = [calendarResultSet stringForColumn:@"createdon_utc"].doubleValue;
                            calendar.updated_by = [calendarResultSet stringForColumn:@"updated_by"];
                            calendar.updatedon_utc = [calendarResultSet stringForColumn:@"updatedon_utc"].doubleValue;
                            calendar.status = [calendarResultSet intForColumn:@"status"];
                            calendar.finishedon_utc = [calendarResultSet stringForColumn:@"finishedon_utc"].doubleValue;
                            calendar.rrule = [calendarResultSet stringForColumn:@"rrule"];
                            calendar.emergency_status = [calendarResultSet intForColumn:@"emergency_status"];
                            calendar.deleted_dates = [calendarResultSet stringForColumn:@"deleted_dates"];
                            calendar.finished_dates = [calendarResultSet stringForColumn:@"finished_dates"];
                            calendar.r_begin_date_utc = [calendarResultSet doubleForColumn:@"r_begin_date_utc"];
                            calendar.r_end_date_utc = [calendarResultSet doubleForColumn:@"r_end_date_utc"];
                            calendar.is_over_day = [calendarResultSet boolForColumn:@"is_over_day"];
                            calendar.members = [calendarResultSet stringForColumn:@"members"];
                            calendar.member_names = [calendarResultSet stringForColumn:@"member_names"];
                            calendar.event_guid = [calendarResultSet stringForColumn:@"event_guid"];
                            calendar.creator_name = [calendarResultSet stringForColumn:@"creator_name"];
                            [userManager addCalendar:calendar];
                        }
                    }
                    //有登陆用户就同步讨论组
                    FMResultSet *userDiscussResultSet = [fMDatabase executeQuery:@"select * from tb_UserDiscuss"];
                    while (userDiscussResultSet.next) {
                        @synchronized (self) {//必须原子操作
                            //要把这个任务放到哪个用户文件
                            NSString *currentUser = [userDiscussResultSet stringForColumn:@"currentUser"];
                            [userManager loadUserWithGuid:currentUser];
                            UserDiscuss *userDiscuss = [UserDiscuss new];
                            userDiscuss.id = [userDiscussResultSet stringForColumn:@"id"].intValue;
                            userDiscuss.user_no = [userDiscussResultSet stringForColumn:@"user_no"].intValue;
                            userDiscuss.user_guid = [userDiscussResultSet stringForColumn:@"user_guid"];
                            userDiscuss.discuss_id = [userDiscussResultSet stringForColumn:@"discuss_id"];
                            userDiscuss.discuss_title = [userDiscussResultSet stringForColumn:@"discuss_title"];
                            userDiscuss.createdon_utc = [userDiscussResultSet doubleForColumn:@"createdon_utc"];
                            [userManager addUserDiscuss:userDiscuss];
                        }
                    }
                    //同步登陆用户的消息中心
                    FMResultSet *fMResultSet = [fMDatabase executeQuery:@"select * from tb_PushMessage"];
                    int index = 1000;
                    while (fMResultSet.next) {
                        @synchronized (self) {//必须原子操作
                            //只插入给自己的 旧数据库是根据这个来辨别推送消息属于谁的
                            int toUserNo = [fMResultSet stringForColumn:@"to_user_no"].intValue;
                            if(toUserNo != user.user_no) continue;
                            PushMessage *pushMessage = [PushMessage new];
                            pushMessage.id = @(index++).stringValue;
                            pushMessage.target_id = [fMResultSet stringForColumn:@"target_id"];
                            pushMessage.type = [fMResultSet stringForColumn:@"type"];
                            pushMessage.content = [fMResultSet stringForColumn:@"content"];
                            pushMessage.icon = [fMResultSet stringForColumn:@"icon"];
                            pushMessage.addTime = [NSDate dateWithTimeIntervalSince1970:[fMResultSet stringForColumn:@"time"].doubleValue / 1000];
                            pushMessage.company_no = [fMResultSet stringForColumn:@"company_no"].intValue;
                            pushMessage.from_user_no = [fMResultSet stringForColumn:@"from_user_no"].intValue;
                            pushMessage.to_user_no = [fMResultSet stringForColumn:@"to_user_no"].intValue;
                            pushMessage.unread = [fMResultSet boolForColumn:@"unread"];
                            pushMessage.action = [fMResultSet stringForColumn:@"action"];
                            pushMessage.entity = [fMResultSet stringForColumn:@"entity"];
                            [userManager addPushMessage:pushMessage];
                        }
                    }
                    //当然有数据了就不是第一次使用软件了
                    identityManager.identity.RYToken = [defaults objectForKey:@"RongYunToken"];
                    identityManager.identity.user_guid = user.user_guid;
                    identityManager.identity.firstUseSoft = NO;
                    [identityManager saveAuthorizeData];
                    [defaults removeObjectForKey:@"WelcomeViewReadssss"];
                    [self remBGMView];
                    [self.navigationController dismissTips];
                    [self gotoIdentityVC];
                }];
            }];
        }];
        return;
    }
    //看用户是不是第一次使用软件
    if(identityManager.identity.firstUseSoft == 1) {
        _welcome = [WelcomeController new];
        _welcome.view.alpha = 0;
        [self addChildViewController:_welcome];
        [self.view addSubview:_welcome.view];
        //如果是从业务界面进来
        if([self.childViewControllers containsObject:_business]) {
            [self transitionFromViewController:_business toViewController:_welcome duration:1 options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut animations:^{
                _welcome.view.alpha = 1;
                _business.view.alpha = 0;
            } completion:^(BOOL finished) {
                [_business.view removeFromSuperview];
                [_business removeFromParentViewController];
            }];
        } else {
            [UIView animateWithDuration:0.5 animations:^{
                _welcome.view.alpha = 1;
            }];
        }
        return;
    }
    //看用户是否登录
    if([NSString isBlank:identityManager.identity.user_guid]) {
        _login = [LoginController new];
        _login.view = 0;
        [self addChildViewController:_login];
        [self.view addSubview:_login.view];
        //如果是从欢迎界面进来
        if([self.childViewControllers containsObject:_welcome]) {
            [self transitionFromViewController:_welcome toViewController:_login duration:1 options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut animations:^{
                _login.view.alpha = 1;
                _welcome.view.alpha = 0;
            } completion:^(BOOL finished) {
                [_welcome.view removeFromSuperview];
                [_welcome removeFromParentViewController];
            }];
        } else if([self.childViewControllers containsObject:_business]){//如果是从业务界面进来
            [self transitionFromViewController:_business toViewController:_login duration:1 options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut animations:^{
                _login.view.alpha = 1;
                _business.view.alpha = 0;
            } completion:^(BOOL finished) {
                [_welcome.view removeFromSuperview];
                [_welcome removeFromParentViewController];
            }];
        } else {
            [UIView animateWithDuration:0.5 animations:^{
                _login.view.alpha = 1;
            }];
        }
        return;
    }
    //已经登陆就加载登陆的用户信息
    [[UserManager manager] loadUserWithGuid:identityManager.identity.user_guid];
    //初始化个推
    [[GeTuiSdkManager manager] startGeTuiSdk];
    //用融云登录聊天
    [[RYChatManager shareInstance] syncRYGroup];
    [[RCIM sharedRCIM] connectWithToken:identityManager.identity.RYToken success:nil error:nil tokenIncorrect:nil];
    _business = [BusinessController new];
    _business.view.alpha = 0;
    [self addChildViewController:_business];
    [self.view addSubview:_business.view];
    //如果是从登录界面进来
    if([self.childViewControllers containsObject:_login]) {
        [self transitionFromViewController:_login toViewController:_business duration:1 options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut animations:^{
            _business.view.alpha = 1;
            _login.view.alpha = 0;
        } completion:^(BOOL finished) {
            [_login.view removeFromSuperview];
            [_login removeFromParentViewController];
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
           _business.view.alpha = 1;
        }];
    }
}
//添加迁移数据的背景图
- (void)addBGMView {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT)];
    imageView.image = [UIImage imageNamed:@"lauch_screen_background"];
    imageView.tag = 10001;
    [self.view addSubview:imageView];
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch_screen_icon"]];
    topImageView.frame = CGRectMake(0.5 * (MAIN_SCREEN_WIDTH - topImageView.frame.size.width), 50, topImageView.frame.size.width, topImageView.frame.size.height);
    topImageView.tag = 10002;
    [imageView addSubview:topImageView];
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, MAIN_SCREEN_HEIGHT - 118, MAIN_SCREEN_WIDTH, 18)];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = @"帮帮，为执行力而生";
    bottomLabel.textColor = [UIColor whiteColor];
    bottomLabel.font = [UIFont systemFontOfSize:15];
    bottomLabel.tag = 10003;
    [imageView addSubview:bottomLabel];
}
//添加迁移数据的背景图
- (void)remBGMView {
    [[self.view viewWithTag:10001] removeFromSuperview];
    [[self.view viewWithTag:10002] removeFromSuperview];
    [[self.view viewWithTag:10003] removeFromSuperview];
}

@end
