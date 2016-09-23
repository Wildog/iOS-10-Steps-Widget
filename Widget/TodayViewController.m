//
//  TodayViewController.m
//  Widget
//
//  Created by Wildog on 9/17/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import "TodayViewController.h"
#import "LineChartView.h"
#import <HealthKit/HealthKit.h>
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding, LineChartViewDataSource, LineChartViewDelegate, CAAnimationDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    CGFloat _currentMax;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _labelChanged;
    BOOL _errorOccurred;
    BOOL _firstLoaded;
    BOOL _collapsed;
}
@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UILabel *statLabel;
@property (nonatomic, strong) HKHealthStore *healthStore;
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
    self.healthStore = [[HKHealthStore alloc] init];
    _numberCount = 7;
    _currentMax = 0;
    _labelChanged = NO;
    _errorOccurred = NO;
    _firstLoaded = YES;
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"M/d"];
    _shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.dog.wil.steps"];
    
    NSString *unit = [_shared stringForKey:@"unit"];
    if (unit != nil) {
        _unit = unit;
    } else {
        _unit = @"km";
        [_shared setObject:_unit forKey:@"unit"];
        [_shared synchronize];
    }
    
    NSString *snapshot = [_shared stringForKey:@"snapshot"];
    if (snapshot != nil) {
        self.label.text = snapshot;
    } else {
        self.label.text = [NSString stringWithFormat:@"\uF3BB  ----   \uE801  ---- %@   \uF148  -- F", _unit];
    }
    NSString *stat = [_shared stringForKey:@"stat"];
    if (stat != nil) {
        self.statLabel.text = stat;
    } else {
        self.statLabel.text = @"Daily Average: ---- steps, Total: ----- steps";
    }
    
    [self.statLabel.layer setOpacity:0];
    [self.lineChartView setBackgroundLineColor:[UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:0.75]];
    [self.lineChartView setAverageLineColor:[UIColor colorWithHue:0 saturation:0 brightness:0.75 alpha:0.75]];
    [self.lineChartView setDataSource:self];
    [self.lineChartView setDelegate:self];
    [self readHealthKitData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_labelChanged) {
        if (_collapsed) {
            [self.lineChartView removeSublayers];
        } else {
            [self.lineChartView setNeedsDisplay];
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
        [self.lineChartView setHidden:NO];
        self.preferredContentSize = CGSizeMake(0.0, 280.0);
        if (_firstLoaded) {
            self.label.layer.transform = CATransform3DMakeTranslation(0, -20, 0);
            [self.statLabel.layer setOpacity:1];
        } else {
            [self expandAnimation];
        }
    } else if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        _collapsed = YES;
        [self.lineChartView setHidden:YES];
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
    [self.label.layer addAnimation:moveUpAnimation forKey:@"moveUpText"];
    
    //stat label fade in
    CAKeyframeAnimation *fadeInAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [fadeInAnimation setValues:[NSArray arrayWithObjects:@(0), @(1), nil]];
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.354 : 0.000 : 0.223 : 0.841];
    [fadeInAnimation setDuration: 1];
    [self.statLabel.layer addAnimation:fadeInAnimation forKey:@"fadeInText"];
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
    [[self.label layer] addAnimation:moveDownAnimation forKey:@"moveDownText"];
    
    //stat label fade out
    CAKeyframeAnimation *fadeOutAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [fadeOutAnimation setValues:[NSArray arrayWithObjects:@(1), @(0), nil]];
    fadeOutAnimation.removedOnCompletion = NO;
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    fadeOutAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.000 : 0.076 : 0.104 : 1.000];
    [fadeOutAnimation setDuration: 0.4];
    [self.statLabel.layer addAnimation:fadeOutAnimation forKey:@"fadeOutText"];
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
    
    HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantityType *distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    
    NSDate *day = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    
    for (NSUInteger i = 0; i < _numberCount; i++) {
        [arrayForLabels setObject:[_formatter stringFromDate:day] atIndexedSubscript:_numberCount - 1 - i];
        
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:day];
        components.hour = components.minute = components.second = 0;
        NSDate *beginDate = [calendar dateFromComponents:components];
        NSDate *endDate = day;
        if (i != 0) {
            components.hour = 24;
            components.minute = components.second = 0;
            endDate = [calendar dateFromComponents:components];
        }
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:beginDate endDate:endDate options:HKQueryOptionStrictStartDate];
        
        HKStatisticsQuery *squery = [[HKStatisticsQuery alloc]
                                     initWithQuantityType:stepType
                                     quantitySamplePredicate:predicate
                                     options:HKStatisticsOptionCumulativeSum
                                     completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                if (error != nil) _errorOccurred = YES;
                HKQuantity *quantity = result.sumQuantity;
                double step = [quantity doubleValueForUnit:[HKUnit countUnit]];
                [arrayForValues setObject:[NSNumber numberWithDouble:step] atIndexedSubscript:_numberCount - 1 - i];
                if (step > _currentMax) _currentMax = step;
                dispatch_group_leave(hkGroup);
        }];
        HKStatisticsQuery *fquery = [[HKStatisticsQuery alloc]
                                     initWithQuantityType:flightsType
                                     quantitySamplePredicate:predicate
                                     options:HKStatisticsOptionCumulativeSum
                                     completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                if (error != nil) _errorOccurred = YES;
                HKQuantity *quantity = result.sumQuantity;
                double flight = [quantity doubleValueForUnit:[HKUnit countUnit]];
                [arrayForFlights setObject:[NSNumber numberWithDouble:flight] atIndexedSubscript:_numberCount - 1 - i];
                dispatch_group_leave(hkGroup);
        }];
        HKStatisticsQuery *dquery = [[HKStatisticsQuery alloc] initWithQuantityType:distanceType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                if (error != nil) _errorOccurred = YES;
                HKQuantity *quantity = result.sumQuantity;
                double distance = [quantity doubleValueForUnit:[HKUnit unitFromString:_unit]];
                [arrayForDistances setObject:[NSNumber numberWithDouble:distance] atIndexedSubscript:_numberCount - 1 - i];
                dispatch_group_leave(hkGroup);
        }];
        dispatch_group_enter(hkGroup);
        [self.healthStore executeQuery:squery];
        dispatch_group_enter(hkGroup);
        [self.healthStore executeQuery:fquery];
        dispatch_group_enter(hkGroup);
        [self.healthStore executeQuery:dquery];
        
        day = [day dateByAddingTimeInterval: -3600 * 24];
    }
    dispatch_group_notify(hkGroup, dispatch_get_main_queue(),^{
        if (!_errorOccurred && _currentMax > 0) {
            _elementValues = (NSArray*)arrayForValues;
            _elementDistances = (NSArray*)arrayForDistances;
            _elementFlights = (NSArray*)arrayForFlights;
            _elementLables = (NSArray*)arrayForLabels;
            [self.lineChartView loadData];
            
            NSString *stat = [NSString stringWithFormat:@"Daily Average: %.0f steps, Total: %.0f steps", [self averageValue], [self totalValue]];
            self.statLabel.text = stat;
            [_shared setObject:stat forKey:@"stat"];
            
            [self changeTextWithNodeAtIndex:_numberCount - 1];
            [_shared setObject:[NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[_numberCount-1] floatValue], [(NSNumber*)_elementDistances[_numberCount-1] floatValue], _unit, [(NSNumber*)_elementFlights[_numberCount-1] floatValue]] forKey:@"snapshot"];
            
            [_shared synchronize];
        } else if (!_errorOccurred && _currentMax <= 0) {
            self.errorLabel.text = @"No data";
        } else {
            self.errorLabel.text = @"Cannot access full Health data from lock screen";
        }
    });
}

- (void)readHealthKitData
{
    if ([HKHealthStore isHealthDataAvailable]) {
        HKQuantityType *stepType =[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        HKQuantityType *flightsType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:stepType, distanceType, flightsType, nil] completion:^(BOOL success, NSError *error) {
            if (success) {
                [self queryHealthData];
            } else {
                self.label.text = @"Health Data Permission Denied";
            }
        }];
    } else {
        self.label.text = @"Health Data Not Available";
    }
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
    self.label.text = result;
}

@end
