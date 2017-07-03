//
//  ViewController.m
//  LineChart
//
//  Created by Wildog on 9/16/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

//#import <HealthKit/HealthKit.h>
#import <CoreMotion/CoreMotion.h>
#import "MainViewController.h"
#import "WDLineChartView.h"
#import "AppDelegate.h"

@interface MainViewController () <WDLineChartViewDataSource, WDLineChartViewDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    NSUInteger _lastSelected;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _errorOccurred;
    BOOL _firstTimeLoaded;
    NSInteger _currentMax;
}

@property (weak, nonatomic) IBOutlet WDLineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISwitch *unitSwitch;
@property (weak, nonatomic) IBOutlet UILabel *kmLabel;
@property (weak, nonatomic) IBOutlet UILabel *miLabel;
@property (weak, nonatomic) IBOutlet UILabel *statLabel;
//@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) CMPedometer *pedometer;

@end

@implementation MainViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _errorOccurred = NO;
        _firstTimeLoaded = YES;
        _numberCount = 7;
        _lastSelected = _numberCount - 1;
        _currentMax = 0;
        _shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.wil.dog.iSteps"];
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"M/d"];
        //_healthStore = [[HKHealthStore alloc] init];
        _pedometer = [[CMPedometer alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_unitSwitch addTarget:self action:@selector(unitSwitched:) forControlEvents:UIControlEventValueChanged];
    [_lineChartView setDataSource:self];
    [_lineChartView setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)checkUnitState {
    NSString *unit = [_shared stringForKey:@"unit"];
    if (unit != nil) {
        _unit = unit;
        if ([_unit isEqualToString:@"km"]) {
            _unitSwitch.on = YES;
            _kmLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.4 alpha:1];
            _miLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        } else {
            _unitSwitch.on = NO;
            _miLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.4 alpha:1];
            _kmLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        }
    } else {
        _unit = @"km";
        [_shared setObject:_unit forKey:@"unit"];
        [_shared synchronize];
    }
}

- (void)reload {
    if (!_firstTimeLoaded) {
        [_lineChartView setAnimated:NO];
    }
    _firstTimeLoaded = NO;
    [self checkUnitState];
    [self readHealthKitData];
}

- (void)unitSwitched:(id)sender {
    if ([sender isOn]) {
        _kmLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.4 alpha:1];
        _miLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        _unit = @"km";
    } else {
        _miLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.4 alpha:1];
        _kmLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        _unit = @"mi";
    }
    [_shared setObject:_unit forKey:@"unit"];
    [_shared synchronize];
    [self readHealthKitData];
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] createShortcutItems];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - HealthKit methods
- (void)queryHealthData
{
    NSMutableArray *arrayForValues = [NSMutableArray arrayWithCapacity:_numberCount];
    NSMutableArray *arrayForLabels = [NSMutableArray arrayWithCapacity:_numberCount];
    NSMutableArray *arrayForDistances = [NSMutableArray arrayWithCapacity:_numberCount];
    NSMutableArray *arrayForFlights = [NSMutableArray arrayWithCapacity:_numberCount];
    for (NSUInteger i = 0; i < _numberCount; i++) {
        [arrayForValues addObject:@(0)];
        [arrayForLabels addObject:@""];
        [arrayForDistances addObject:@(0)];
        [arrayForFlights addObject:@(0)];
    }
    _elementValues = (NSArray*)arrayForValues;
    
    dispatch_group_t hkGroup = dispatch_group_create();
    
    //HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //HKQuantityType *distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    //HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    
    NSDate *day = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    
    for (NSUInteger i = 0; i < _numberCount; i++) {
        arrayForLabels[_numberCount - 1 - i] = [_formatter stringFromDate:day];
        
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:day];
        components.hour = components.minute = components.second = 0;
        NSDate *beginDate = [calendar dateFromComponents:components];
        NSDate *endDate = day;
        if (i != 0) {
            components.hour = 24;
            components.minute = components.second = 0;
            endDate = [calendar dateFromComponents:components];
        }
        // switch from HealthKit to CoreMotion due to its realtime updates and fast data retrieval
        dispatch_group_enter(hkGroup);
        [self.pedometer queryPedometerDataFromDate:beginDate toDate:endDate withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if (error != nil) _errorOccurred = YES;
            arrayForValues[_numberCount - 1 - i] = pedometerData.numberOfSteps ? pedometerData.numberOfSteps : @(0);
            arrayForFlights[_numberCount - 1 - i] = pedometerData.floorsAscended ? pedometerData.floorsAscended : @(0);
            if ([_unit isEqualToString:@"km"]) {
                arrayForDistances[_numberCount - 1 - i] = @(pedometerData.distance.doubleValue / 1000.0);
            } else {
                arrayForDistances[_numberCount - 1 - i] = @(pedometerData.distance.doubleValue * 0.000621371);
            }
            if (pedometerData.numberOfSteps.integerValue > _currentMax) {
                _currentMax = pedometerData.numberOfSteps.integerValue;
            }
            dispatch_group_leave(hkGroup);
        }];
        //NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:beginDate endDate:endDate options:HKQueryOptionStrictStartDate];
        //
        //HKStatisticsQuery *squery = [[HKStatisticsQuery alloc]
        //                             initWithQuantityType:stepType
        //                             quantitySamplePredicate:predicate
        //                             options:HKStatisticsOptionCumulativeSum
        //                             completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        //        if (error != nil) _errorOccurred = YES;
        //        HKQuantity *quantity = result.sumQuantity;
        //        double step = [quantity doubleValueForUnit:[HKUnit countUnit]];
        //        [arrayForValues setObject:[NSNumber numberWithDouble:step] atIndexedSubscript:_numberCount - 1 - i];
        //        if (step > _currentMax) _currentMax = step;
        //        dispatch_group_leave(hkGroup);
        //}];
        //HKStatisticsQuery *fquery = [[HKStatisticsQuery alloc]
        //                             initWithQuantityType:flightsType
        //                             quantitySamplePredicate:predicate
        //                             options:HKStatisticsOptionCumulativeSum
        //                             completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        //        if (error != nil) _errorOccurred = YES;
        //        HKQuantity *quantity = result.sumQuantity;
        //        double flight = [quantity doubleValueForUnit:[HKUnit countUnit]];
        //        [arrayForFlights setObject:[NSNumber numberWithDouble:flight] atIndexedSubscript:_numberCount - 1 - i];
        //        dispatch_group_leave(hkGroup);
        //}];
        //HKStatisticsQuery *dquery = [[HKStatisticsQuery alloc]
        //                             initWithQuantityType:distanceType
        //                             quantitySamplePredicate:predicate
        //                             options:HKStatisticsOptionCumulativeSum
        //                             completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        //        if (error != nil) _errorOccurred = YES;
        //        HKQuantity *quantity = result.sumQuantity;
        //        double distance = [quantity doubleValueForUnit:[HKUnit unitFromString:_unit]];
        //        [arrayForDistances setObject:[NSNumber numberWithDouble:distance] atIndexedSubscript:_numberCount - 1 - i];
        //        dispatch_group_leave(hkGroup);
        //}];
        //dispatch_group_enter(hkGroup);
        //[_healthStore executeQuery:squery];
        //dispatch_group_enter(hkGroup);
        //[_healthStore executeQuery:fquery];
        //dispatch_group_enter(hkGroup);
        //[_healthStore executeQuery:dquery];
        
        day = [day dateByAddingTimeInterval: -3600 * 24];
    }
    dispatch_group_notify(hkGroup, dispatch_get_main_queue(),^{
        if (!_errorOccurred && _currentMax > 0) {
            _elementValues = (NSArray*)arrayForValues;
            _elementDistances = (NSArray*)arrayForDistances;
            _elementFlights = (NSArray*)arrayForFlights;
            _elementLables = (NSArray*)arrayForLabels;
            [_lineChartView loadDataWithSelectedKept];
            [self changeTextWithNodeAtIndex:_lastSelected];
            _statLabel.text = [NSString stringWithFormat:@"Daily Average: %.0f steps, Total: %.0f steps", [self averageValue], [self totalValue]];
        } else if (!_errorOccurred && _currentMax <= 0) {
            _label.text = @"No data";
        } else {
            _label.text = @"Motion data not accessible";
        }
    });
}

- (void)readHealthKitData
{
    //if ([HKHealthStore isHealthDataAvailable]) {
    //    HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //    HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    //    HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    //    [_healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:stepType, distanceType, flightsType, nil] completion:^(BOOL success, NSError *error) {
    //        if (success) {
    //            [self queryHealthData];
    //        } else {
    //            _label.text = @"Health Data Permission Denied";
    //        }
    //    }];
    //} else {
    //    _label.text = @"Health Data Not Available";
    //}
    if (![CMPedometer isStepCountingAvailable] || ![CMPedometer isFloorCountingAvailable] || ![CMPedometer isDistanceAvailable]) {
        _label.text = @"Motion Data Not Available";
        return;
    }
    [self queryHealthData];
}

#pragma mark - LineChartViewDataSource methods

- (NSUInteger)numberOfElements {
    return _numberCount;
}

- (CGFloat)maxValue {
    return [[_elementValues valueForKeyPath:@"@max.self"] doubleValue];
}

- (CGFloat)minValue {
    return [[_elementValues valueForKeyPath:@"@min.self"] doubleValue];
}

- (CGFloat)averageValue {
    return [[_elementValues valueForKeyPath:@"@avg.self"] doubleValue];
}

- (CGFloat)totalValue {
    return [[_elementValues valueForKeyPath:@"@sum.self"] doubleValue];
}

- (CGFloat)valueForElementAtIndex:(NSUInteger)index {
    return [(NSNumber*)_elementValues[index] floatValue];
}

- (NSString*)labelForElementAtIndex:(NSUInteger)index {
    return (NSString*)_elementLables[index];
}

#pragma mark - LineChartViewDelegate methods

- (void)clickedNodeAtIndex:(NSUInteger)index {
    [self changeTextWithNodeAtIndex:index];
    _lastSelected = index;
}

- (void)changeTextWithNodeAtIndex:(NSUInteger)index {
    NSString *result = [NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[index] floatValue], [(NSNumber*)_elementDistances[index] floatValue], _unit, [(NSNumber*)_elementFlights[index] floatValue]];
    _label.text = result;
}

@end
