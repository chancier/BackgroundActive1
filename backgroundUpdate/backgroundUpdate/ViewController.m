
#import "ViewController.h"


#define RUNTIME 10
@interface ViewController ()

@end

@implementation ViewController
@synthesize _locationManager;
@synthesize _mapView;
@synthesize _saveLocations;
@synthesize _updateTimer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    
    //响应后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}



//初始化数据
-(void)initData{
    backgroundUpdateInterval = RUNTIME;//设置计时器时间
    
    
    self._saveLocations = [[NSMutableArray alloc] init];
    self._locationManager = [[CLLocationManager alloc] init];
    self._locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self._locationManager.delegate = self;
    [self._locationManager startUpdatingLocation];
    
}



- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateSpan mySpan = [mapView region].span;
    storedLatitudeDelta = mySpan.latitudeDelta;
    storedLongitudeDelta = mySpan.longitudeDelta;
}


//吏新定位
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    //在地图上加大头针
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = newLocation.coordinate;
    [self._mapView addAnnotation:annotation];//
    [self._saveLocations addObject:annotation];
    
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
    {
        if (backgroundTask != UIBackgroundTaskInvalid)//如果后台没有关闭，结束
        {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        }

        //显示所有的大头针
        for (MKPointAnnotation *annotation in self._saveLocations)
        {
            CLLocationCoordinate2D coordinate = annotation.coordinate;
            
            MKCoordinateRegion region=MKCoordinateRegionMakeWithDistance(coordinate,storedLatitudeDelta ,storedLongitudeDelta);
            MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:region];
            [_mapView setRegion:adjustedRegion animated:NO];
        }
    }
    else
    {
        NSLog(@"applicationD in Background,newLocation:%@", newLocation);
    }
}




//用定时器控制后台运行定位时间
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notication{
    UIApplication* app = [UIApplication sharedApplication];
    
    backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
      NSLog(@"applicationD in Background");
    }];
    
    
    //加入定时器，用来控制后台运行时间
    self._updateTimer = [NSTimer scheduledTimerWithTimeInterval:backgroundUpdateInterval
                                                     target:self
                                                   selector:@selector(stopUpdate)
                                                   userInfo:nil
                                                    repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self._updateTimer forMode:NSRunLoopCommonModes];
    
    
    
    //以下测试不断的调用test方法
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Do the work associated with the task.
        
        while (app.applicationState==UIApplicationStateBackground && backgroundTask!=UIBackgroundTaskInvalid && [app backgroundTimeRemaining] > 10)
        {
            [NSThread sleepForTimeInterval:1];
            NSLog(@"background task %lu left left  time %d.", (unsigned long)backgroundTask, (int)[app backgroundTimeRemaining]);
            
            [self test];
            
            //[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(test) userInfo:nil repeats:YES];
        }
        
        NSLog(@"background task %lu finished.", (unsigned long)backgroundTask);
        [app endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
        
        
    });
}

- (void)test
{
    NSLog(@"test");
}


//时间到，停止后台运行定位
-(void)stopUpdate{
    
    //function1： RUNTIME 时间后停止定位
    [self._locationManager stopUpdatingLocation];

    [self._updateTimer invalidate];
    self._updateTimer = nil;
    if (backgroundTask != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }
    
    
    //function2：播放无声音乐  达到后台长时间保持
    if ([[UIApplication sharedApplication] backgroundTimeRemaining] < 61.0) {
        
        
//        [[CKAudioTool sharedInstance] playSound];
        [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        
    }
}

/*
 [[CKAudioTool sharedInstance] playSound];这段代码是去播放了一个无声的音乐，很关键的一点是
 
 [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error]
 
 这样后台播放就不会影响到别的程序播放音乐了。
 
 我这个计时器每分钟运行一次tik函数，如果发现后台运行时间小于一分钟了，就再去申请一个backgroundTask。
 
 神奇的地方在于：backgroundTask不能在程序已经进入后台的时候申请，可以用一个播放音乐的假前台状态去申请，所以可以做到不断申请到权限，也就完成了长时间后台执行。
 */



- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(interfaceOrientation == UIDeviceOrientationPortrait || interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
		return YES;
	}else {
		return NO;
	}
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
