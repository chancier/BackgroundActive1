
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@interface ViewController : UIViewController<CLLocationManagerDelegate>
{
    CLLocationDistance storedLatitudeDelta;
    CLLocationDistance storedLongitudeDelta;
    UIBackgroundTaskIdentifier backgroundTask;
    NSTimeInterval backgroundUpdateInterval;
}

@property (nonatomic, strong) CLLocationManager *_locationManager;
@property (nonatomic, strong) IBOutlet MKMapView *_mapView;
@property (nonatomic, strong) NSMutableArray *_saveLocations;
@property (nonatomic, strong) NSTimer *_updateTimer;


@end
