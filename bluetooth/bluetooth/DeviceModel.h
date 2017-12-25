//
//  DeviceModel.h
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceModel : NSObject

@property (nonatomic,strong) NSString *deviceMac;
@property (nonatomic,strong) NSString *deviceName;
@property (nonatomic,strong) NSString *openState;//开启、关闭状态
@property (nonatomic,strong) NSString *actionModel;//手动模式、自动模式

+(DeviceModel *)creatBLEDeviceMac:(NSString *)deviceMac deviceName:(NSString *)deviceName openState:(NSString *)openState actionModel:(NSString *)actionModel;

@end
