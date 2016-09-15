//
//  ViewController.m
//  bPeripheral
//
//  Created by Yuichiro Nakada on 2016/09/09.
//  Copyright © 2016 Yuichiro Nakada. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "PulsingHaloLayer.h"

#define UUID        @"7485B0B6-7596-48D5-92EB-B1E1EB67563C"
#define IDENTIFIER  @"jp.yui.region"

#define kMaxRadius 160

@interface ViewController () <CBPeripheralManagerDelegate> {
    
    int btn;
}

@property (nonatomic) NSUUID *proximityUUID;
@property (nonatomic) CBPeripheralManager *peripheralManager;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) NSDictionary *myBeaconData;
@property (weak, nonatomic) IBOutlet UILabel *lbUUID;

// Beacon
@property (weak, nonatomic) IBOutlet UIImageView *beaconView;

@property (nonatomic, strong) PulsingHaloLayer *halo;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // ボタン初期値
    btn = 1;
    
    // 背景に画像をセット
    UIImage *image = [UIImage imageNamed:@"bg02"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    // Create a NSUUID object
    // 生成したUUIDから送信NSUUIDオブジェクトを作成します。送受信同じNSUUID
    self.proximityUUID = [[NSUUID alloc] initWithUUIDString:UUID];
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// [発信]ボタンを押した時
- (IBAction)btStat:(id)sender {
    
    // Statボタン２度押し禁止
    if (btn == 1) {
        
        //////////////////////////////////////////////////////////////////
        // Initialize the Beacon Region
        // ビーコン領域を初期化します Region:領域、範囲
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                                               major:1
                                                                               minor:2
                                                                          identifier:IDENTIFIER];
        // Get the beacon data to advertise
        // 発信、公開
        // ビーコンデータを広告することを得る peripheral:周辺 With:共に Measured:測定された
        // peripheralDataWithMeasuredPower: ペリフェラルの 1m 地点での電波強度を表す NSNumber 型
        NSDictionary *beaconPeripheralData = [beaconRegion peripheralDataWithMeasuredPower:nil];
        [self.peripheralManager startAdvertising:beaconPeripheralData];
        
        ///////////////////////////////////////////////////////////////////
        
        // パルス波形表示設定
        [self puls:1];
        
        self.statusLabel.text = @"発信中";
        
        // UUIDの表示
        NSString *lbuuid = beaconRegion.proximityUUID.UUIDString;
        self.lbUUID.text = [NSString stringWithFormat:@"UUID: %@", lbuuid];
        
        btn = 0;
    }
}

// [停止]ボタンを押した時
- (IBAction)btStop:(id)sender {
    if (btn == 0) {
        // パルス波形表示設定
        [self puls:0];
        self.lbUUID.text = nil;
        
        // BLEアドバタイズ停止処理
        [self.peripheralManager stopAdvertising];
        btn = 1;
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error) {
        [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"%@", error]];
    } else {
        [self sendLocalNotificationForMessage:@"アドバタイズ（発信）スタート"];
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSString *message;
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOff:
            message = @"電源OFF";
            break;
        case CBPeripheralManagerStatePoweredOn:
            message = @"電源ON";
            //[self startAdvertising];
            break;
        case CBPeripheralManagerStateResetting:
            message = @"リセット";
            break;
        case CBPeripheralManagerStateUnauthorized:
            message = @"許可されていません";
            break;
        case CBPeripheralManagerStateUnknown:
            message = @"不明";
            break;
        case CBPeripheralManagerStateUnsupported:
            message = @"サポート対象外";
            break;
            
        default:
            break;
    }
    
    [self sendLocalNotificationForMessage:[@"ペリフェラル（アドバタイズ・発信公開）を行いました: " stringByAppendingString:message]];
}

#pragma mark - Private methods

// iBeaconパルス波形表示設定　引数１つ半径 arg01(ON:1 OFF:0)
- (void)puls:(int)arg01 {
    // arg01(ON:1 OFF:0)
    if (arg01 == 1) {
        // プロパティに所望の値をセットすれば、半径が変わります。
        self.halo = [PulsingHaloLayer layer];
        
        self.beaconView.hidden = NO; //表示にする
        // Beacon
        self.halo.position = self.beaconView.center;
        
        [self.view.layer insertSublayer:self.halo below:self.beaconView.layer];
        
        self.halo.radius = 1.0;
        
        // Beacon ON:1
        self.halo.radius = 1.0 * kMaxRadius;
        
        // 色を変える
        UIColor *color = [UIColor colorWithRed:0.6    // 0
                                         green:0.0    // 0.487
                                          blue:0.5    // 1.0
                                         alpha:1.0];
        
        self.halo.backgroundColor = color.CGColor;
    } else {
        //self.beaconView.hidden = YES; //非表示にする
        self.halo.backgroundColor = nil; //非表示にする
        self.statusLabel.text = @"停止中";
        self.statusLabel.textColor = [UIColor redColor];
    }
}

- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
