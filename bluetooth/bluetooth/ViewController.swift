//
//  ViewController.swift
//  bluetooth
//
//  Created by haitao on 2017/10/24.
//  Copyright © 2017年 haitao. All rights reserved.
//

import UIKit

class ViewController: UIViewController,BluetoothDelegate {

    var tableView : UITableView?
    var deviceArray : NSMutableArray?
    var bleManage : BLEManage!
    var connectIndex : NSInteger!
    var scanArray:[CBPeripheral]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bleManage = BLEManage.sharedInstance
        bleManage.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.bleManage.startScan()
            self.scanArray = self.bleManage.deviceSet.allObjects as! [CBPeripheral]
            print("扫描数组",self.scanArray)
        }
    }
    //发现蓝牙设备
    func discoverPeripheral(peripheral: CBPeripheral, isMyBluetooth: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

