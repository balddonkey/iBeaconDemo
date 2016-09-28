//
//  RBLocationManager.h
//  IBeaconDemo
//
//  Created by Solomon on 16/7/25.
//  Copyright © 2016年 Solomon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

extern NSString * const UUID;
extern NSString * const RegionId;

@protocol SLLocationManagerDelegate <NSObject>

@optional
- (void)didReciveMessage:(NSString *)message;
- (void)didEnterRegion:(CLBeaconRegion *)region;
- (void)didExitRegion:(CLBeaconRegion *)region;
- (void)didRangingBeacon:(CLBeacon *)beacon inRegion:(CLRegion *)region;

@end

@interface SLLocationManager : NSObject

@property (weak, nonatomic) id <SLLocationManagerDelegate>delegate;

+ (SLLocationManager *)manager;

// 开启服务
- (void)start:(void (^) (void))completion;

// 停止服务，但不清除已注册的 CLBeaconRegion。
- (void)stop;

// 停止服务，并清除已注册 CLBeaconRegion。
- (void)clear;

@end

@interface UILocalNotification (UILocalNotification_IBeaconDemo_OC)

+ (UILocalNotification *)presentLocalNotification:(NSString *)title setting:(void (^) (UILocalNotification *))setting;

@end
