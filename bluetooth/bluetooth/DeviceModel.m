//
//  DeviceModel.m
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import "DeviceModel.h"

@implementation DeviceModel

+(DeviceModel *)creatBLEDeviceMac:(NSString *)deviceMac deviceName:(NSString *)deviceName openState:(NSString *)openState actionModel:(NSString *)actionModel{
    
    DeviceModel *model = [[DeviceModel alloc]init];
    model.deviceMac = deviceMac;
    model.deviceName = deviceName;
    model.openState = openState;
    model.actionModel = actionModel;
    return model;
}

-(NSString *)description{
    NSString *string = [NSString stringWithFormat:@" _deviceMac:%@  _deviceName:%@ _devicePassword:%@ actionModel:%@",_deviceMac ,_deviceName,_openState,_actionModel];
    return string;
}



@end
