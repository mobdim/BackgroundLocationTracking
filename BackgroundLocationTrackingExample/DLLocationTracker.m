//
//  KWLocationTracker.m
//  Kawiky
//
//  Created by Denis Lebedev on 3/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DLLocationTracker.h"
//#import "KWConstants.h"

static CGFloat const kMinUpdateDistance = 10.f;
static NSTimeInterval const kMinUpdateTime = 90.f;
static NSTimeInterval const kMaxTimeToLive = 30.f;

static NSString *const kArchivedLocationKey = @"com.Company.Defaults.ArchivedLocation";

@interface DLLocationTracker () {
@private     
    UIBackgroundTaskIdentifier bgTask;
}

@end

@implementation DLLocationTracker

#pragma mark - NSObject

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:    UIApplicationDidEnterBackgroundNotification object:nil];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification handlers

- (void)applicationDidBecomeActive {
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [self.locationManager startUpdatingLocation];
}

- (void)applicationDidEnterBackground {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

#pragma mark - Public

- (void)startUpdatingLocation {
    [self stopUpdatingLocation];
    [self isInBackground] ? [self.locationManager startMonitoringSignificantLocationChanges] : [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)endBackgroundTask {
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}
#pragma mark - Private

- (BOOL)isInBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (oldLocation && ([newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp] < kMinUpdateTime ||
                        [newLocation distanceFromLocation:oldLocation] < kMinUpdateDistance)) {
        return;
    }
    
    if ([self isInBackground]) {
        if (self.locationUpdatedInBackground) {
            bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            }];
            
            self.locationUpdatedInBackground(newLocation);
            [self endBackgroundTask];
        }
    } else {
        if (self.locationUpdatedInForeground) {
            self.locationUpdatedInForeground(newLocation);
        }
    }
}

@end
