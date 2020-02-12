//
//  CaptureViewController.m
//  ScanCode
//
//  Created by yxhe on 16/6/2.
//  Copyright © 2016年 yxhe. All rights reserved.
//


#import <AVFoundation/AVFoundation.h>
#import "CaptureViewController.h"
#import "BrowserViewController.h"

//the new process queue indentifier
const char *kScanCodeQueueName = "ScanCodeQueue";


@interface CaptureViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    //the session of captrue
    AVCaptureSession *session;
    BOOL isLightOpen;
}

@property (nonatomic, strong) UIView *cameraView;      //the camera frame view
@property (nonatomic, strong) UIButton *openLightBtn;  //open the light

@end

@implementation CaptureViewController
#pragma mark - system delegate functions
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //add the cameara view
    _cameraView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width)];
    _cameraView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_cameraView];
    
    //add a button to switch light
    isLightOpen = NO;
    UIButton *lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    lightButton.frame = CGRectMake(self.view.frame.size.width/2 - 50, 500, 100, 50);
    [lightButton setTitle:@"打开闪光灯" forState:UIControlStateNormal];
    [lightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [lightButton setTitleColor:[UIColor greenColor] forState:UIControlEventTouchDown];
    [lightButton addTarget: self action:@selector(switchLight) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:lightButton];
    //start capture
    [self initCapture];
    [session startRunning];
}

- (void)loadView
{
    [super loadView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - capture delegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects && metadataObjects.count>0)
    {
        //stop the capture
        [session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        //do sth to handle the capture result
        [self performSelectorOnMainThread:@selector(handleResult:) withObject:metadataObject waitUntilDone:NO];
    }
}

#pragma mark - helper funtions
- (void)initCapture
{
    //get the camera device
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //create the session
    session = [[AVCaptureSession alloc]init];
    
    //create input
    NSError *error;
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if(!input)
    {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    [session addInput:input];
    
    //create output
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    [session addOutput:output];
    
    //make it run at a new process
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create(kScanCodeQueueName, NULL);
    [output setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    //set the sampling rate
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    //set the code type ,ex:QR and bar code
    if([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode])
    {
        [output setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, nil]];
    }
    
    //add the camera layer
    AVCaptureVideoPreviewLayer *captureLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    captureLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    captureLayer.frame=self.cameraView.layer.bounds;
    [self.cameraView.layer insertSublayer:captureLayer atIndex:0];
    
    //or use the addsublayer
    //    [self.cameraView.layer addSublayer:captureLayer];
}

- (void)handleResult:(AVMetadataMachineReadableCodeObject *)metadataObject
{
    NSLog(@"%@", metadataObject.type);
    if([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode])
    {
        NSLog(@"QR code");
    }
    else
    {
        NSLog(@"other code");

    }
    NSString* urlprefix = @"https://linux.ustc.edu.cn/2020/test.php?gid=";
    NSString* gid = [metadataObject.stringValue substringToIndex:10];
    NSString *captureStr =  [urlprefix stringByAppendingString:gid];
    
    NSLog(@"%@",captureStr);
    BrowserViewController *browserViewController = [[BrowserViewController alloc] init];
    browserViewController.urlStr = captureStr;
        
    [self.navigationController pushViewController:browserViewController animated:YES];

    if(0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"scan result"
                                                        message:captureStr
                                                       delegate:nil
                                              cancelButtonTitle:@"ok"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

- (void)switchLight
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //toggle the light
    isLightOpen = !isLightOpen;
    
    //turn on or off the light
    if([device hasTorch])
    {
        [device lockForConfiguration:nil];
        
        if(isLightOpen)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        
        [device unlockForConfiguration];
    }
}

//use regular expression to recognize URL
- (BOOL)isURL:(NSString *)str
{
    NSString *regex = @"[a-zA-z]+://[^s]*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:str];
}

@end
