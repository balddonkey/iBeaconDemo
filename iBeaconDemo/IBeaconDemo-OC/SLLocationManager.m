//
//  SLLocationManager.m
//  IBeaconDemo
//
//  Created by Solomon on 16/7/25.
//  Copyright © 2016年 Solomon. All rights reserved.
//

#import "SLLocationManager.h"
#import <UIKit/UIKit.h>

NSString * const UUID = @"74278BDA-B644-4520-8F0C-720EAF059935";
NSString * const RegionId  = @"BeaconIdentifier";

@interface SLLocationManager () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (copy, nonatomic) void (^authorizeCompletionHandler) (void);

@end

@implementation SLLocationManager

+ (SLLocationManager *)manager {
    static SLLocationManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SLLocationManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = 10000;
        _locationManager.delegate = self;
    }
    return self;
}

#pragma mark - Core method
- (void)start:(void (^) (void))completion {
    [self requestAuthorization:^{
        [self registerIBeacon];
        if (completion) {
            completion();
        }
    }];
}

- (void)stop {
    // 停止定位
    [self.locationManager stopUpdatingLocation];
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        // 停止 Ranging 操作
        if ([region isKindOfClass:[CLBeaconRegion class]]) {
            [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        }
    }
}

- (void)clear {
    [self.locationManager stopUpdatingLocation];
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
        
        if ([region isKindOfClass:[CLBeaconRegion class]]) {
            [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        }
    }
}

- (void)requestAuthorization:(void (^) (void))completion {
    
    // 注册通知
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
    
    __weak typeof(&*self) weakSelf = self;
    self.authorizeCompletionHandler = ^{
        // 开启定位功能可保证App在手动进入后台以后，依旧可以继续 Ranging 操作。
        weakSelf.locationManager.allowsBackgroundLocationUpdates = YES;
        [weakSelf.locationManager startUpdatingLocation];
        if (completion) {
            completion();
        }
    };
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways
        && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager requestAlwaysAuthorization];
    } else {
        self.authorizeCompletionHandler();
        self.authorizeCompletionHandler = nil;
    }
}

- (void)registerIBeacon {
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: UUID] identifier:RegionId];
    [self.locationManager startMonitoringForRegion:region];
}

#pragma mark - CLLocationManagerDelegate method

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (self.authorizeCompletionHandler) {
            self.authorizeCompletionHandler();
            self.authorizeCompletionHandler = nil;
        }
    } else {
        NSLog(@"授权失败: %d", status);
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"did update location");
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        return;
    }
    CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
    if (state == CLRegionStateInside) {
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        if ([self.delegate respondsToSelector:@selector(didEnterRegion:)]) {
            [self.delegate didEnterRegion:beaconRegion];
        }
    } else if (state == CLRegionStateOutside) {
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        if ([self.delegate respondsToSelector:@selector(didExitRegion:)]) {
            [self.delegate didExitRegion:beaconRegion];
        }
    } else {
        NSLog(@"determine state unknow");
        if ([self.delegate respondsToSelector:@selector(didReciveMessage:)]) {
            [self.delegate didReciveMessage:@"determine state unknow"];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NSLog(@"identifier: %@", region.identifier);
    if ([region.identifier isEqualToString:RegionId]) {
        for (CLBeacon *beacon in beacons) {
            
            if ([self.delegate respondsToSelector:@selector(didRangingBeacon:inRegion:)]) {
                [self.delegate didRangingBeacon:beacon inRegion:region];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    NSLog(@"did enter region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region {
    NSLog(@"did exit region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"func: %s, line: %d, error: %@", __PRETTY_FUNCTION__, __LINE__, error.localizedDescription);
}


@end

@implementation UILocalNotification (UILocalNotification_IBeaconDemo_OC)

+ (UILocalNotification *)presentLocalNotification:(NSString *)title setting:(void (^) (UILocalNotification *))setting {
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    localNotif.alertBody = title;
    if (setting) {
        setting(localNotif);
    }
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
    return localNotif;
}

@end
