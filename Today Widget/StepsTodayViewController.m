//
//  TodayViewController.m
//  Widget
//
//  Created by Wildog on 9/17/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import "StepsTodayViewController.h"
#import "WDLineChartView.h"
//#import <HealthKit/HealthKit.h>
#import <NotificationCenter/NotificationCenter.h>
#import <CoreMotion/CoreMotion.h>

@interface StepsTodayViewController () <NCWidgetProviding, WDLineChartViewDataSource, WDLineChartViewDelegate, CAAnimationDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    NSInteger _currentMax;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _labelChanged;
    BOOL _errorOccurred;
    BOOL _firstLoaded;
    BOOL _collapsed;
}
@property (weak, nonatomic) IBOutlet WDLineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UILabel *statLabel;
//@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) CMPedometer *pedometer;
@end

@implementation StepsTodayViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _numberCount = 7;
        _currentMax = 0;
        _labelChanged = NO;
        _errorOccurred = NO;
        _firstLoaded = YES;
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"M/d"];
        //_healthStore = [[HKHealthStore alloc] init];
        _pedometer = [[CMPedometer alloc] init];
        _shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.wil.dog.iSteps"];
        
        NSString *unit = [_shared stringForKey:@"unit"];
        if (unit != nil) {
            _unit = unit;
        } else {
            _unit = @"km";
            [_shared setObject:_unit forKey:@"unit"];
            [_shared synchronize];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
    
    NSString *snapshot = [_shared stringForKey:@"snapshot"];
    if (snapshot != nil) {
        _label.text = snapshot;
    } else {
        _label.text = [NSString stringWithFormat:@"\uF3BB  ----   \uE801  ---- %@   \uF148  -- F", _unit];
    }
    NSString *stat = [_shared stringForKey:@"stat"];
    if (stat != nil) {
        _statLabel.text = stat;
    } else {
        _statLabel.text = @"Daily Average: ---- steps, Total: ----- steps";
    }
    
    [_statLabel.layer setOpacity:0];
    [_lineChartView setBackgroundLineColor:[UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:0.75]];
    [_lineChartView setAverageLineColor:[UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:0.75]];
    [_lineChartView setDataSource:self];
    [_lineChartView setDelegate:self];
    [self readHealthKitData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_labelChanged) {
        if (_collapsed) {
            [_lineChartView removeSublayers];
        } else {
            [_lineChartView setNeedsDisplay];
        }
    }
    _labelChanged = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    
    completionHandler(NCUpdateResultNewData);
}

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize {
    if (activeDisplayMode == NCWidgetDisplayModeExpanded) {
        _collapsed = NO;
        [_lineChartView setHidden:NO];
        self.preferredContentSize = CGSizeMake(0.0, 280.0);
        if (_firstLoaded) {
            _label.layer.transform = CATransform3DMakeTranslation(0, -20, 0);
            [_statLabel.layer setOpacity:1];
        } else {
            [self expandAnimation];
        }
    } else if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        _collapsed = YES;
        [_lineChartView setHidden:YES];
        self.preferredContentSize = maxSize;
        if (!_firstLoaded) [self collapseAnimation];
    }
    _firstLoaded = NO;
}

- (void)expandAnimation {
    //today label move up
    CAKeyframeAnimation *moveUpAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D transform = CATransform3DMakeTranslation(0, -20, 0);
    [moveUpAnimation setValues:[NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                [NSValue valueWithCATransform3D:transform],
                                nil]];
    moveUpAnimation.removedOnCompletion = NO;
    moveUpAnimation.fillMode = kCAFillModeForwards;
    moveUpAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
    [moveUpAnimation setDuration: 0.5];
    [_label.layer addAnimation:moveUpAnimation forKey:@"moveUpText"];
    
    //stat label fade in
    CAKeyframeAnimation *fadeInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [fadeInAnimation setValues:[NSArray arrayWithObjects:@(0), @(1), nil]];
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.354 : 0.000 : 0.223 : 0.841];
    [fadeInAnimation setDuration: 1];
    [_statLabel.layer addAnimation:fadeInAnimation forKey:@"fadeInText"];
}

- (void)collapseAnimation {
    //today label move down
    CAKeyframeAnimation *moveDownAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D before = CATransform3DMakeTranslation(0, -20, 0);
    [moveDownAnimation setValues:[NSArray arrayWithObjects:
                                  [NSValue valueWithCATransform3D:before],
                                  [NSValue valueWithCATransform3D:CATransform3DIdentity],
                                  nil]];
    moveDownAnimation.removedOnCompletion = NO;
    moveDownAnimation.fillMode = kCAFillModeForwards;
    moveDownAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
    [moveDownAnimation setDuration: 0.5];
    [_label.layer addAnimation:moveDownAnimation forKey:@"moveDownText"];
    
    //stat label fade out
    CAKeyframeAnimation *fadeOutAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [fadeOutAnimation setValues:[NSArray arrayWithObjects:@(1), @(0), nil]];
    fadeOutAnimation.removedOnCompletion = NO;
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    fadeOutAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.000 : 0.076 : 0.104 : 1.000];
    [fadeOutAnimation setDuration: 0.4];
    [_statLabel.layer addAnimation:fadeOutAnimation forKey:@"fadeOutText"];
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
            [_lineChartView loadData];
            
            NSString *stat = [NSString stringWithFormat:@"Daily Average: %.0f steps, Total: %.0f steps", [self averageValue], [self totalValue]];
            _statLabel.text = stat;
            [_shared setObject:stat forKey:@"stat"];
            
            [self changeTextWithNodeAtIndex:_numberCount - 1];
            [_shared setObject:[NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[_numberCount-1] floatValue], [(NSNumber*)_elementDistances[_numberCount-1] floatValue], _unit, [(NSNumber*)_elementFlights[_numberCount-1] floatValue]] forKey:@"snapshot"];
            
            [_shared synchronize];
        } else if (!_errorOccurred && _currentMax <= 0) {
            _errorLabel.text = @"No data";
        } else {
            _errorLabel.text = @"Motion data not accessible";
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

- (CGFloat)valueForElementAtIndex:(NSUInteger)index {
    return [(NSNumber*)_elementValues[index] floatValue];
}

- (CGFloat)averageValue {
    return [[_elementValues valueForKeyPath:@"@avg.self"] doubleValue];
}

- (CGFloat)totalValue {
    return [[_elementValues valueForKeyPath:@"@sum.self"] doubleValue];
}

- (NSString*)labelForElementAtIndex:(NSUInteger)index {
    return (NSString*)_elementLables[index];
}

#pragma mark - LineChartViewDelegate methods

- (void)clickedNodeAtIndex:(NSUInteger)index {
    [self changeTextWithNodeAtIndex:index];
    _labelChanged = YES;
}

- (void)changeTextWithNodeAtIndex:(NSUInteger)index {
    NSString *result = [NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[index] floatValue], [(NSNumber*)_elementDistances[index] floatValue], _unit, [(NSNumber*)_elementFlights[index] floatValue]];
    _label.text = result;
}

@end
