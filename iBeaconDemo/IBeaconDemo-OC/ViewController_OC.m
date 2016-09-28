//
//  ViewController.m
//  IBeaconDemo-OC
//
//  Created by Solomon on 16/7/25.
//  Copyright © 2016年 Solomon. All rights reserved.
//

#import "ViewController_OC.h"
#import "SLLocationManager.h"

@interface ViewController_OC () <SLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *messageView;
@property (strong, nonatomic) NSDateFormatter *df;

@end

@implementation ViewController_OC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    [SLLocationManager manager].delegate = self;
    [[SLLocationManager manager] start:^{
        NSLog(@"start service");
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[SLLocationManager manager] stop];
    
    // 如果你想要在停止的时候清楚注册在被监视列表的CLBeaconRegion，你可以使用如下方法
    // 这个方法会在停止服务的同时，从注册表里面移除。
//    [[SLLocationManager manager] clear];
}

#pragma mark - RBLocationManagerDelegate method
- (void)didReciveMessage:(NSString *)message {
    // ...
    NSString *str = [[self.df stringFromDate:[NSDate date]] stringByAppendingFormat:@": %@\n%@", message, self.messageView.text];
    self.messageView.text = str;
}

- (void)didEnterRegion:(CLBeaconRegion *)region {
    NSString *message = [NSString stringWithFormat:@"Inside BeaconRegion: %@\n", region.proximityUUID.UUIDString];
    [self didReciveMessage:message];
    [UILocalNotification presentLocalNotification:message setting:nil];
}

- (void)didExitRegion:(CLBeaconRegion *)region {
    NSString *message = [NSString stringWithFormat:@"Outside BeaconRegion: %@\n", region.proximityUUID.UUIDString];
    [self didReciveMessage:message];
    [UILocalNotification presentLocalNotification:message setting:nil];
}

- (void)didRangingBeacon:(CLBeacon *)beacon inRegion:(CLRegion *)region {
    // ...
    NSString *str = [NSString stringWithFormat:@"Did ranging beacon:\nUUID: %@\nMajor: %@\nMinor: %@\nAccuracy: %.1f\n", beacon.proximityUUID.UUIDString, beacon.major, beacon.minor, beacon.accuracy];
    [self didReciveMessage:str];
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
