//
//  BLEManage.swift
//  bluetooth
//
//  Created by haitao on 2017/10/24.
//  Copyright © 2017年 haitao. All rights reserved.
//

import UIKit
import CoreBluetooth

enum SendDataType: Int {
    case ReplyCode = 0
    case Concentration = 1//浓度
    case HumidityAndTemperature = 2
    case Open = 3
    case Close = 4
    case ManualModel = 5//手动模式
    case AutoModel = 6
    case Spray = 7
    case BatteryInfo = 8
    case getState = 9
}

@objc protocol BluetoothDelegate {
    @objc optional func discoverPeripheral(peripheral: CBPeripheral, isMyBluetooth: Bool)
    @objc optional func connectPeripheral(peripheral: CBPeripheral, isSuccess: Bool)
    @objc optional func disconnectPeripheral(peripheral: CBPeripheral)
    @objc optional func receriveBatteryInfo(percent: Int)
    @objc optional func retrievePeripheral(peripheral: CBPeripheral)
    @objc optional func findCharacteristic(peripheral: CBPeripheral)
    @objc optional func deviceIsOnOpenState(isReady:UInt8,batteryState:UInt8,solutionState:UInt8,automodel:UInt8)
    @objc optional func getTemperatureAndHumidity(temperature:String,humidity:String)
    @objc optional func getBattery(battery:String)
    
    
    
}

class BLEManage: NSObject,CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: 全局变量
    var centralManager: CBCentralManager!
    var bluetoothIsReady: Bool = false
    var batteryCharacteristic: CBCharacteristic?
    var immediateAlertCharacteristic: CBCharacteristic?
    var delegate: BluetoothDelegate?
    var deviceSet: NSMutableSet!
    var lostDistanceArray: [(peripheral: CBPeripheral, lostDistance: Int)]!
    var connectPeripheral : CBPeripheral!
    // 单例
    static let sharedInstance = BLEManage()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : true])
        deviceSet = NSMutableSet()
        
        lostDistanceArray = []
        
    }
    
    // MARK: 对内蓝牙管理
    // 蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn:
            print("Bluetooth Status: Turned On")
            bluetoothIsReady = true
        case .poweredOff:
            print("Bluetooth Status: Turned Off")
            bluetoothIsReady = false
        case .resetting:
            print("Bluetooth Status: Resetting")
            bluetoothIsReady = false
        case .unauthorized:
            print("Bluetooth Status: Not Authorized")
            bluetoothIsReady = false
        case .unsupported:
            print("Bluetooth Status: Not Supported")
            bluetoothIsReady = false
        default:
            print("Bluetooth Status: Unknown")
            bluetoothIsReady = false
            
        }
    }
    
    // 发现蓝牙设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("发现外设: \(peripheral)")
        //        if (peripheral.name == "GmanBlueTooth" || peripheral.name == "GhostyuSerialApp"){
        self.deviceSet.add(peripheral)
        print(self.deviceSet)
        self.delegate?.discoverPeripheral?(peripheral: peripheral, isMyBluetooth: true)
        //        }
    }
    
    
    // 连接蓝牙失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        self.delegate?.connectPeripheral?(peripheral: peripheral, isSuccess: false)
        
        print("\nFail to connect \(peripheral)")
    }
    
    
    // 连接蓝牙成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("\nConnect Success \(peripheral) ")
        self.connectPeripheral = peripheral
        self.delegate?.connectPeripheral?(peripheral: peripheral, isSuccess: true)
        
        hadAddDeviceInTuples(peripheral: peripheral, tuples: (peripheral, 100))
        
        // 搜索服务
        peripheral.delegate = self
        peripheral.discoverServices(nil); print("\nSearching Service....")
    }
    
    // 判断是否已经添加过蓝牙设备
    func hadAddDeviceInTuples(peripheral: CBPeripheral, tuples: (peripheral: CBPeripheral, lostDistance: Int)) {
        var hadAdd = false
        for tuples in lostDistanceArray {
            if tuples.peripheral == peripheral {
                hadAdd = true
            }
        }
        if hadAdd == false {
            lostDistanceArray.append(tuples)
        }
    }
    
    // 发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil { return }
        
        for service in peripheral.services! {
            // 搜索特征
            print("\nDiscover Service: \(service)")
            peripheral.discoverCharacteristics(nil, for: service )
        }
    }
    
    //MARK: 发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil { return }
        
        for characteristic in service.characteristics! {
            print("\nDiscover characteristic: \(characteristic)")
            
            let notiUUID = CBUUID.init(string: "fff4")
            if characteristic.uuid .isEqual(notiUUID) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
        }
        
    }
    
    // 定阅状态改变
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        characteristic.isNotifying ? print("\nNotifing \(characteristic)") : print("\nUnNotifing \(characteristic)")
        
        if characteristic.isNotifying {
            self.sendDataToDevice(sendDataType: SendDataType.getState)
            
            self.sendDataToDevice(sendDataType: .HumidityAndTemperature)
            self.sendDataToDevice(sendDataType: .BatteryInfo)
            
            
        }
    }
    // 蓝牙连接断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        self.delegate?.disconnectPeripheral?(peripheral: peripheral)
        removeDisconnectPeripheral(peripheral: peripheral)
        print("\nDisconnect Peripheral !")
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: "蓝牙断开")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "蓝牙断开"), object: nil)
        
    }
    
    //MARK: 从特征收到数据
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("\nReceriveing Data from characteristic error");
            return
        }
        // 收到的数据
        dealWithReceiveData(bleData: characteristic.value! as NSData)
        
    }
    //MARK: 解析数据
    func dealWithReceiveData (bleData:NSData){
        print("接收数据---------:",bleData);
        var dataVal = [UInt8](repeating: 0,count:8)
        bleData.getBytes(&dataVal, length: bleData.length)
        
        switch dataVal[1] {
        case 0x00://应答码
            print("应答码")
            if dataVal[0] == 0 {
                print("success")
            }else{
                print("失败")
            }
            
            break
        case 0x02://浓度
            
            
            break
        case 0x04://湿度温度
            let temp1 = String(dataVal[2])
            let temp2 = String(dataVal[3])
            let temperature = temp1 + "." + temp2
            print("温度",temperature)
            
            let humidity1 = String(dataVal[4])
            let humidity2 = String(dataVal[5])
            let humidity = humidity1 + "." + humidity2
            print("湿度",humidity)
            self.delegate?.getTemperatureAndHumidity?(temperature: temp1, humidity: humidity1)
            break
        case 0x09://警告信息
            
            
            break
        case 0x11://电量信息
            
            let battery = String(dataVal[2])
            print("电池电量",battery)
            self.delegate?.getBattery?(battery: battery)
            break
        case 0x13://设备状态
            
            let deviceState = dataVal[2] & 0x03//设备开关状态
            let openState = dataVal[2] & 0x04
            let model = dataVal[2] & (0x01<<3)
            let solutionState = dataVal[2] & (0x01<<4)
            let batteryState = dataVal[2] & (0x01<<5)
            let 人体距离状态 = dataVal[2] & (0x01<<6)
            
            print("电源状态:",deviceState,"雾化状态:",openState,"模式",model,"溶液",solutionState,"电量状态:",batteryState,"人体距离状态:",人体距离状态)
            
            self.delegate?.deviceIsOnOpenState?(isReady: deviceState, batteryState: batteryState, solutionState: solutionState,automodel:model)
            
            break
        default:
            break
        }
        
        
    }
    
    func 累加和(data: NSData) -> Int {
        var dataVal = [UInt8](repeating: 0,count:20)
        data.getBytes(&dataVal, length: data.length)
        
        var sum = 0
        for i in 0..<data.length {
            sum += Int(dataVal[i])
        }
        return sum & 0xff
    }
    
    // 重新找回已经连接的设备
    func retrievePeripherals() {
        let retrievePeripherals: [CBPeripheral] = self.centralManager.retrieveConnectedPeripherals(withServices: [CBUUID(string: "0xfff0")])
        for retrievePeripheral in retrievePeripherals {
            print("已经连接过的设备: \(retrievePeripheral)")
        }
    }
    
    // MARK: 对外接口
    //MARK: 发送数据
    internal func sendDataToDevice(sendDataType :SendDataType){
        
        var dataValue = [UInt8](repeating: 0,count:8)
        
        dataValue[0] = 0xaa
        
        switch sendDataType {
        case .ReplyCode:
            dataValue[1] = 0x00
            dataValue[2] = 0x00
            break
        case .Concentration:
            dataValue[1] = 0x01
            dataValue[2] = 0x00
            break
        case .HumidityAndTemperature:
            dataValue[1] = 0x03
            dataValue[2] = 0x00
            break
        case .Open:
            dataValue[1] = 0x05
            dataValue[2] = 0x00
            break
        case .Close:
            dataValue[1] = 0x06
            dataValue[2] = 0x00
            break
        case .ManualModel:
            dataValue[1] = 0x07
            dataValue[2] = 0x00
            break
        case .AutoModel:
            dataValue[1] = 0x07
            dataValue[2] = 0x01
            break
        case .Spray:
            dataValue[1] = 0x08
            dataValue[2] = 0x00
            break
        case .BatteryInfo:
            dataValue[1] = 0x10
            dataValue[2] = 0x00
            break
        case .getState:
            dataValue[1] = 0x12
            dataValue[2] = 0x00
            break
        }
        
        dataValue[3] = 0x00
        dataValue[4] = 0x00
        dataValue[5] = 0x00
        dataValue[6] = 0xff
        
        let data = NSData.init(bytes: dataValue, length: 7)
        dataValue[7] = UInt8(累加和(data: data))
        let sendData = NSData.init(bytes: dataValue, length: 8)
        print("发送指令:",sendData)
        let sUUID = CBUUID.init(string:"0xfff0")
        let cUUID = CBUUID.init(string:"0xfff1")
        BLEUtility.writeCharacteristic(self.connectPeripheral, sCBUUID: sUUID, cCBUUID: cUUID, data: sendData as Data!)
        
    }
    
    // 开始扫描蓝牙设备
    internal func startScan () {
        bluetoothIsReady ? centralManager.scanForPeripherals(withServices: nil , options: nil) : print("蓝牙没有准备完毕")
    }
    // 停止扫描设备
    internal func stopScan () {
        centralManager.stopScan()
    }
    // 连接蓝牙设备
    internal func startConnect(deviceM: DeviceModel) {
        print("正在连接外设 >>>>> \(deviceM)")
        for peripheral in self.deviceSet {
            if deviceM.deviceMac == (peripheral as! CBPeripheral).identifier.uuidString {
                centralManager.connect(peripheral as! CBPeripheral, options: nil)
                
            }
        }
        
    }
    // 停止连接设备
    internal func stopConnect (deviceM: DeviceModel) {
        for peripheral in self.deviceSet {
            if deviceM.deviceMac == (peripheral as! CBPeripheral).identifier.uuidString {
                centralManager.cancelPeripheralConnection(peripheral as! CBPeripheral)
                print("正在停止连接外设 >>>>> \(peripheral )")
            }
        }
        
    }
    // 向设备写数据
    internal func writeData(peripheral: CBPeripheral,characteristic: CBCharacteristic, data:NSData) {
        peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    
    
    // 读特征值
    internal func readCharacteristic(peripheral: CBPeripheral,characteristic: CBCharacteristic) {
        
        peripheral.readValue(for: characteristic)
    }
    
    // MARK: 其它方法
    
    // 读所有蓝牙的信号值
    func readingRssi() {
        for peripheral in deviceSet {
            (peripheral as AnyObject).readRSSI()
        }
    }
    // 移除断开连接的耳机
    func removeDisconnectPeripheral(peripheral: CBPeripheral) {
        
        var index = Int.max
        for i in 0..<lostDistanceArray.count {
            if lostDistanceArray[i].peripheral == peripheral {
                index = i
            }
        }
        if index != Int.max {
            lostDistanceArray.remove(at: index)
        }
    }
    
    
    
}

