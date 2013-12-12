//
//  ViewController.h
//  Garage Control
//
//  Created by Pieter Janssens on 09/12/13.
//  Copyright (c) 2013 Pieter Janssens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>
@property (weak, nonatomic) IBOutlet UILabel *temperatureLbl;
@property (weak, nonatomic) IBOutlet UILabel *lichtLbl;
@property (weak, nonatomic) IBOutlet UIProgressView *portProgressView;
@property (weak, nonatomic) IBOutlet UILabel *portStatusLbl;
@property (weak, nonatomic) IBOutlet UIButton *portControlButton;
@property (weak, nonatomic) IBOutlet UIView *temperatureView;
- (IBAction)controlPort:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *temperatureBarHeight;
@property (strong, nonatomic) BLE *ble;
@property (weak, nonatomic) IBOutlet UILabel *rssiLbl;

@end
