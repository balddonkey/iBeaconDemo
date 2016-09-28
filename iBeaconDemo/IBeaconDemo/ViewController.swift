//
//  ViewController.swift
//  IBeaconDemo
//
//  Created by Solomon on 16/7/19.
//  Copyright © 2016年 Solomon. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, SLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var messageView: UITextView!
    @IBOutlet weak var handleBtn: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var switcher: UISwitch!
    
    @IBOutlet weak var accuracyLabel: UILabel!
    
    @IBOutlet weak var majorTf: UITextField!
    @IBOutlet weak var minorTf: UITextField!
    
    
    let df: NSDateFormatter = {
        return NSDateFormatter()
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.handleBtn.layer.cornerRadius = 5.0
        self.majorTf.text = String(RoboMajor)
        self.minorTf.text = String(RoboMinor)
        self.df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        SLLocationManager.manager.delegate = self
        SLLocationManager.manager.start {
            print("Start service")
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 如果你想要在停止的时候清楚注册在被监视列表的CLBeaconRegion，你可以使用如下方法
        // 这个方法会在停止服务的同时，从注册表里面移除。
//        SLLocationManager.manager.clear()
    }
    
    @IBAction func pressBtn(sender: UIButton) {
        
        do {
            // 手动执行一些操作
        }
        
        sender.enabled = false
        
        // 设置按钮可用时间间隔
        NSTimer.scheduled(10, operation: {
            sender.enabled = true
        })
    }
    
    @IBAction func pressSwitch(sender: UISwitch) {
        self.contentView.hidden = !sender.on
    }

    func didReciveMessage(message: String) {
        let str = self.df.stringFromDate(NSDate()).stringByAppendingString(": \(message)\n\(self.messageView.text)")
        self.messageView.text = str
    }
    
    func didEnterRegion(region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        UILocalNotification.presentLocalNotification("Inside BeaconRegion: \(beaconRegion.proximityUUID.UUIDString)")
        
        self.didReciveMessage("Inside BeaconRegion: \(beaconRegion.proximityUUID.UUIDString)")
        handleBtn.enabled = true
    }
    
    func didExitRegion(region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        UILocalNotification.presentLocalNotification("Outside BeaconRegion: \(beaconRegion.proximityUUID.UUIDString)")
        
        self.didReciveMessage("Outside BeaconRegion: \(beaconRegion.proximityUUID.UUIDString)")
        handleBtn.enabled = false
    }
    
    // 这里需要细化过滤条件，现在只是判断距离在3.5内。
    func didRangingBeacon(beacon: CLBeacon, inRegion: CLRegion) {
        
        // 显示当前距离
        var checkAddition = true
        if self.switcher.on {
            checkAddition = beacon.major.stringValue == self.majorTf.text && beacon.minor.stringValue == self.minorTf.text
        }
        if checkAddition {
            self.accuracyLabel.text = String(format: "Accuracy: %.3f", beacon.accuracy)
        } else {
            self.accuracyLabel.text = "未检测到匹配 iBeacon"
        }
        
        // 在设备检测到 iBeacon 硬件，但是信号又过差的话，就会返回 －1，需要过滤此无效值。
        if beacon.accuracy <= 3.5 && beacon.accuracy > 0 {
            // 做一些指定的操作
        }
        
        let msg = String(format: "Did ranging beacon: \(beacon.proximityUUID.UUIDString)\nMajor: \(beacon.major), Minor: \(beacon.minor)\nAccuracy: %.3f", beacon.accuracy)
        self.didReciveMessage(msg)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.clearKeyboard()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.clearKeyboard()
        return true
    }
    
    private func clearKeyboard() {
        if self.majorTf.isFirstResponder() {
            self.majorTf.resignFirstResponder()
        } else if self.minorTf.isFirstResponder() {
            self.minorTf.resignFirstResponder()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

