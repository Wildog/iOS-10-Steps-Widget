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

@interface TodayViewController () <NCWidgetProviding, LineChartViewDataSource, LineChartViewDelegate> {
    NSArray *_elementValues;
    NSArray *_elementLables;
    NSArray *_elementDistances;
    NSArray *_elementFlights;
    NSUInteger _numberCount;
    CGFloat _maxValue;
    CGFloat _minValue;
    NSDateFormatter *_formatter;
    NSString *_unit;
    NSUserDefaults *_shared;
    BOOL _labelChanged;
    BOOL _errorOccurred;
}
@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (nonatomic, strong) HKHealthStore *healthStore;
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
    self.healthStore = [[HKHealthStore alloc] init];
    _maxValue = _minValue = 0;
    _labelChanged = NO;
    _errorOccurred = NO;
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
        self.label.text = [NSString stringWithFormat:@"\uF3BB  ----   \uE801  ---- %@   \uF148  -- F", _unit];;
    }
    
    [self readHealthKitData];
    [self.lineChartView setDataSource:self];
    [self.lineChartView setDelegate:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_labelChanged) {
        [self.lineChartView setNeedsDisplay];
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
        self.preferredContentSize = CGSizeMake(0.0, 290.0);
    } else if (activeDisplayMode == NCWidgetDisplayModeCompact) {
        self.preferredContentSize = maxSize;
    }
}

#pragma mark - HealthKit methods
- (void)queryHealthData
{
    _numberCount = 7;
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
        
        HKStatisticsQuery *squery = [[HKStatisticsQuery alloc] initWithQuantityType:stepType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
            if (error != nil) _errorOccurred = YES;
            HKQuantity *quantity = result.sumQuantity;
            double step = [quantity doubleValueForUnit:[HKUnit countUnit]];
            [arrayForValues setObject:[NSNumber numberWithDouble:step] atIndexedSubscript:_numberCount - 1 - i];
            if (_minValue == _maxValue && _minValue == 0) _minValue = _maxValue = step;
            if (step > _maxValue) _maxValue = step;
            if (step < _minValue) _minValue = step;
            dispatch_group_leave(hkGroup);
        }];
        HKStatisticsQuery *fquery = [[HKStatisticsQuery alloc] initWithQuantityType:flightsType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
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
        if (!_errorOccurred && _maxValue > 0) {
            _elementValues = (NSArray*)arrayForValues;
            _elementDistances = (NSArray*)arrayForDistances;
            _elementFlights = (NSArray*)arrayForFlights;
            _elementLables = (NSArray*)arrayForLabels;
            [self.lineChartView loadData];
            [self changeTextWithNodeAtIndex:_numberCount - 1];
            [_shared setObject:[NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[_numberCount-1] floatValue], [(NSNumber*)_elementDistances[_numberCount-1] floatValue], _unit, [(NSNumber*)_elementFlights[_numberCount-1] floatValue]] forKey:@"snapshot"];
            [_shared synchronize];
        } else if (_maxValue <= 0) {
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
    return _maxValue;
}

- (CGFloat)minValue {
    return _minValue;
}

- (CGFloat)valueForElementAtIndex:(NSUInteger)index {
    return [(NSNumber*)_elementValues[index] floatValue];
}

- (NSString*)labelForElementAtIndex:(NSUInteger)index {
    return (NSString*)_elementLables[index];
}

#pragma mark - LineChartViewDataSource methods

- (void)clickedNodeAtIndex:(NSUInteger)index {
    [self changeTextWithNodeAtIndex:index];
    _labelChanged = YES;
}

- (void)changeTextWithNodeAtIndex:(NSUInteger)index {
    NSString *result = [NSString stringWithFormat:@"\uF3BB  %.0f   \uE801  %.2f %@   \uF148  %.0f F", [(NSNumber*)_elementValues[index] floatValue], [(NSNumber*)_elementDistances[index] floatValue], _unit, [(NSNumber*)_elementFlights[index] floatValue]];
    self.label.text = result;
}

@end
