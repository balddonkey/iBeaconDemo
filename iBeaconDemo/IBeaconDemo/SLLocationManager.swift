//
//  SLLocationManager.swift
//  IBeaconDemo
//
//  Created by Solomon on 16/7/20.
//  Copyright © 2016年 Solomon. All rights reserved.
//

import UIKit
import CoreLocation


let RoboUUID = "74278BDA-B644-4520-8F0C-720EAF059935"
let RoboMajor = 10023
let RoboMinor = 10025

let RoboBeaconID = "RoboMingBeaconIdentifier"

protocol SLLocationManagerDelegate: NSObjectProtocol {
    
    func didReciveMessage(message: String)
    func didEnterRegion(region: CLRegion)
    func didExitRegion(region: CLRegion)
    func didRangingBeacon(beacon: CLBeacon, inRegion: CLRegion)
    
}

class SLLocationManager: NSObject, CLLocationManagerDelegate {
    
    
    static var manager: SLLocationManager = {
        return SLLocationManager()
    } ()
    
    private override init() {
        super.init()
    }
    
    // MARK: Public member
    weak var delegate: SLLocationManagerDelegate?
    var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        // 位置更新只是为了保证App手动进入后台依然可运行，所以对这个精度要求不高。
        manager.distanceFilter = 10000
        return manager
    } ()
    
    // 开启监测
    func start(completion: (() -> Void)?) {
        self.requestAuthorization { 
            self.registerIBeacon()
            completion?()
        }
    }
    
    // 停止
    func stop() {
        self.locationManager.stopUpdatingLocation()
        let beaconRegions = self.locationManager.monitoredRegions.flatMap { (region) -> CLBeaconRegion? in
            return region as? CLBeaconRegion
        }
        
        for beaconRegion in beaconRegions {
            // 停止 Ranging。
            self.locationManager.stopRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    func clear() {
        self.locationManager.stopUpdatingLocation()
        let beaconRegions = self.locationManager.monitoredRegions.flatMap { (region) -> CLBeaconRegion? in
            return region as? CLBeaconRegion
        }
        
        for beaconRegion in beaconRegions {
            // 停止 Ranging 并移除 CLBeaconRegion Monitor 操作。
            self.locationManager.stopRangingBeaconsInRegion(beaconRegion)
            self.locationManager.stopMonitoringForRegion(beaconRegion)
        }
    }
    
    private var completionHandler:(() -> Void)?
    private func requestAuthorization(completion: (() -> Void)?) {
        
        // 注册通知
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Badge, .Alert, .Sound], categories: nil))
        
        self.locationManager.delegate = self
        self.completionHandler = {
            [weak self] in
            // 开启定位功能可以保证App手动进入到后台依旧可以继续 Ranging 操作
            self?.locationManager.allowsBackgroundLocationUpdates = true
            self?.locationManager.startUpdatingLocation()
            completion?()
        }
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways
            && CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            self.locationManager.requestAlwaysAuthorization()
        } else {
            self.completionHandler?()
            self.completionHandler = nil
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            self.completionHandler?()
            self.completionHandler = nil
        } else {
            print("授权失败: \(status)")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("did update location")
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        if state == .Inside {
            guard let beaconRegion = region as? CLBeaconRegion else { return }
            // 进入 iBeacon 区域，开启 Ranging 操作。
            self.locationManager.startRangingBeaconsInRegion(beaconRegion)
            self.delegate?.didEnterRegion(region)
        } else if state == .Outside {
            guard let beaconRegion = region as? CLBeaconRegion else { return }
            // 离开 iBeacon 区域，关闭 Ranging 操作。
            self.locationManager.stopRangingBeaconsInRegion(beaconRegion)
            self.delegate?.didExitRegion(region)
        } else {
            UILocalNotification.presentLocalNotification("determine state unknow")
            self.delegate?.didReciveMessage("determine state unknow")
        }
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        // 检测到 iBeacon 硬件，可针对特定 iBeacon 进行操作。
        for beacon in beacons {
            self.delegate?.didRangingBeacon(beacon, inRegion: region)
        }
    }
    
    // 进入 LBS Region 回调方法。
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Did Enter Region")
    }
    
    // 离开 LBS Region 回调方法。
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Did Exit Region")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error.localizedDescription)
    }
    
    // 注册 CLBeaconRegion 检测。（CLBeaconRegion 是被视作 CLRegion 的一个派生类，虽然用的是蓝牙的功能，但是苹果将他定位为基于 LBS 的区域监测系统）
    func registerIBeacon() {
        let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: RoboUUID)!, identifier: RoboBeaconID)
        // 每个App 同时只允许监测20个CLBeaconRegion
        self.locationManager.startMonitoringForRegion(beaconRegion)
    }
    
}

extension UILocalNotification {
    class func presentLocalNotification(title: String, setting: ((UILocalNotification) -> Void)? = nil) {
        let notif = UILocalNotification()
        notif.alertBody = title
        setting?(notif)
        UIApplication.sharedApplication().presentLocalNotificationNow(notif)
    }
}

private class SLTimerBridgeObject: NSObject {
    private var operation: (() -> Void)?
    
    @objc func sl_triggerBlock(timer: NSTimer) {
        self.operation?()
    }
}

extension NSTimer {
    
    class func scheduled(timeInterval: NSTimeInterval, operation: (() -> Void), userInfo: AnyObject? = nil, repeats: Bool = false) -> NSTimer {
        let bridge = SLTimerBridgeObject()
        bridge.operation = operation
        let timer = NSTimer(fireDate: NSDate(timeIntervalSinceNow: timeInterval), interval: 0, target: bridge, selector: #selector(SLTimerBridgeObject.sl_triggerBlock(_:)), userInfo: userInfo, repeats: repeats)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        return timer
    }
    
}
