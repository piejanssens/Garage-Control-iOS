//
//  ViewController.m
//  Garage Control
//
//  Created by Pieter Janssens on 09/12/13.
//  Copyright (c) 2013 Pieter Janssens. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MRProgress.h"
//
//To add some form of authentication:
//Change the BLE_PINCODE bytes to any random combination of valid unsigned bytes (0-255)
//Use Google e.g. "76 to hex" will result in "0x4C"
//Define the same 4 pincode bytes in the Arduino Garage Control sketch

const UInt8 BLE_PINCODE[4] = {0x01, 0x01, 0x01, 0x01};

@interface ViewController ()
@end

@implementation ViewController
bool alreadyStarted;
NSTimer *progressTimer;
typedef enum PortStateType : NSInteger PortStateType;
enum PortStateType : NSInteger {
    PortStateClosed,
    PortStateOpening,
    PortStateStopped,
    PortStateClosing,
    PortStateOpen,
    PortStateUnkown
};
PortStateType portState;
@synthesize ble;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.portControlButton.layer.cornerRadius = 4;
    self.portProgressView.progress = 1;
    [self.portControlButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    ble = [[BLE alloc] init];
    [ble controlSetup];
    ble.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    if ([MRProgressOverlayView allOverlaysForView:self.view].count == 0) {
        [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
        [MRProgressOverlayView overlayForView:self.view].titleLabelText = @"Verbinden ...";
    }
    NSLog(@"did become active notification");
    portState = PortStateUnkown; //port status must be 0 or 1 - use 2 to detect initial status
    [self reconnect];
}

- (void)reconnect {
    [self clearLabels];
    if ([ble CM].state == CBCentralManagerStatePoweredOn) {
        [ble scanForPeripheral];
    }
    else {
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(reconnect)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)appWillResignActive:(NSNotification *)notification {
    NSLog(@"will resign active notification");
    [MRProgressOverlayView dismissOverlayForView:self.view animated:YES];
    if ([ble activePeripheral]) {
        [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
    }
    else {
        [[ble CM] stopScan];
    }
}

- (void)clearLabels {
    [self.lichtLbl setText:@""];
    [self updateTemperature:-40.0];
    [self.temperatureLbl setText:@"-- °C"];
    [self.portStatusLbl setText:@"--"];
    [self.rssiLbl setText:@"--"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)changeProgress {
    if (portState == PortStateClosing) { //Closing
        [self.portProgressView setProgress:self.portProgressView.progress + 1.0/190 animated:NO];
    }
    else if (portState == PortStateOpening) { //Opening
        [self.portProgressView setProgress:self.portProgressView.progress - 1.0/140 animated:NO];
        if (self.portProgressView.progress == 0) {
            portState = PortStateOpen;
            [self.portStatusLbl setText:@"Open"];
            [self.portControlButton.titleLabel setText:@"Sluit Poort"];
        }
    }
}

- (IBAction)controlPort:(id)sender {
    [progressTimer invalidate];

    switch (portState) {
        case PortStateClosed:
            portState = PortStateOpening;
            [self.portStatusLbl setText:@"Gaat Open"];
            [self.portControlButton.titleLabel setText:@"Stop"];
            break;
        case PortStateClosing:
            portState = PortStateOpening;
            [self.portStatusLbl setText:@"Gaat Open"];
            [self.portControlButton.titleLabel setText:@"Stop"];
            break;
        case PortStateOpening:
            portState = PortStateStopped;
            [self.portStatusLbl setText:@"Gestopt"];
            [self.portControlButton.titleLabel setText:@"Sluit"];
            break;
        case PortStateStopped:
            portState = PortStateOpening;
            [self.portStatusLbl setText:@"Gaat Open"];
            [self.portControlButton.titleLabel setText:@"Stop"];
            break;
        case PortStateOpen:
            portState = PortStateClosing;
            [self.portStatusLbl setText:@"Gaat Dicht"];
            [self.portControlButton.titleLabel setText:@"Open"];
            break;
        default:
            break;
    }
    
    if (portState != PortStateStopped) {
        progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                         target:self
                                                       selector:@selector(changeProgress)
                                                       userInfo:nil
                                                        repeats:YES];
    }

    UInt8 buf[5] = {
        0x01,
        BLE_PINCODE[0],
        BLE_PINCODE[1],
        BLE_PINCODE[2],
        BLE_PINCODE[3],
    };

    [ble write:[[NSData alloc] initWithBytes:buf length:5]];
}

- (void)updateTemperature: (float)temperature {
    [self.temperatureLbl setText:[NSString stringWithFormat:@"%.2f °C", temperature]];
    self.temperatureBarHeight.constant = (((temperature - (-40)) * (138 - 7)) / (50-(-40))) + 7;
    [UIView animateWithDuration:0.5 animations:^{[self.view layoutIfNeeded];}];
}

- (void)updateLight: (float)Rlight {
    NSString *lightDescription = nil;
    if (Rlight < 3)
        lightDescription = @"Fel";
    else if (Rlight >= 3 && Rlight < 3.3)
        lightDescription = @"Veel";
    else if (Rlight >= 3.3 && Rlight < 10.0)
        lightDescription = @"Weinig";
    else if (Rlight >= 10 && Rlight < 14)
        lightDescription = @"Zwak";
    else if (Rlight >= 14 && Rlight < 20)
        lightDescription = @"Schemer";
    else if (Rlight >= 20 && Rlight < 40)
        lightDescription = @"Nauwelijks";
    else if (Rlight >= 40)
        lightDescription = @"Pikdonker";
    
    [self.lichtLbl setText:[NSString stringWithFormat:@"%@ - R%.2f", lightDescription, Rlight]];
}

#pragma mark - BLE delegate

NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
    [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
    [MRProgressOverlayView overlayForView:self.view].titleLabelText = @"Verbinden ...";
    [self reconnect];
    [rssiTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    self.rssiLbl.text = [NSString stringWithFormat:@"RSSI %@", rssi.stringValue];
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [ble readRSSI];
}

// When disconnected, this will be called
-(void) bleDidConnect
{
    [MRProgressOverlayView dismissOverlayForView:self.view animated:YES];

    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        //NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);
        
        if (data[i] == 0x0A) {
            UInt16 lightSensorValue = data[i+2] | data[i+1] << 8;
            float Rlightsensor=(float)(1023-lightSensorValue)*10/lightSensorValue;
            [self updateLight:Rlightsensor];
        }
        else if (data[i] == 0x0B) {
            UInt16 tempSenorValue = data[i+2] | data[i+1] << 8;
            const int B=3975;
            float Rtempsensor=(float)(1023-tempSenorValue)*10000/tempSenorValue;
            double celcius=1/(log(Rtempsensor/10000)/B+1/298.15)-273.15;
            [self updateTemperature:celcius];
        }
        else if (data[i] == 0x0C) {
            if (data[i+1] == 0x01 && (portState == PortStateUnkown || portState != PortStateClosed)) { //PORT CLOSED
                portState = PortStateClosed;
                [self.portStatusLbl setText:@"Gesloten"];
                [self.portControlButton.titleLabel setText:@"Open"];
                [self.portProgressView setProgress:1 animated:YES];
            }
            else if (data[i+1] == 0x00 && (portState == PortStateUnkown || portState == PortStateClosed)) {
                portState = PortStateOpening;
                if (![progressTimer isValid]) {
                    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                     target:self
                                                                   selector:@selector(changeProgress)
                                                                   userInfo:nil
                                                                    repeats:YES];
                }
                
                [self.portStatusLbl setText:@"Gaat Open"];
                [self.portControlButton.titleLabel setText:@"Sluit"];
            }
        }
    }
}

@end
