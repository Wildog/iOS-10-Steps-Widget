//
//  LineChartView.h
//  LineChart
//
//  Created by Wildog on 9/16/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LineChartViewDataSource, LineChartViewDelegate;

@interface LineChartView : UIView

@property (nonatomic, assign) CGFloat marginH;
@property (nonatomic, assign) CGFloat marginV;
@property (nonatomic, strong) UIColor *backgroundLineColor;
@property (nonatomic, assign) CGFloat backgroundLineWidth;
@property (nonatomic, strong) NSArray *gradientColors;
@property (nonatomic, strong) UIColor *chartLineColor;
@property (nonatomic, assign) CGFloat chartLineWidth;
@property (nonatomic, strong) UIColor *labelColor;
@property (nonatomic, assign) CGFloat nodeSize;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) BOOL animated;
@property (nonatomic, assign) BOOL gradiented;
@property (nonatomic, assign) BOOL showLabel;

@property (nonatomic, weak) id<LineChartViewDataSource> dataSource;
@property (nonatomic, weak) id<LineChartViewDelegate> delegate;

- (void)loadData;
- (void)loadDataWithSelectedKept;

@end

@protocol LineChartViewDataSource <NSObject>
@required
- (NSUInteger)numberOfElements;
- (CGFloat)maxValue;
- (CGFloat)minValue;
- (CGFloat)valueForElementAtIndex:(NSUInteger)index;
- (NSString*)labelForElementAtIndex:(NSUInteger)index;
@end

@protocol LineChartViewDelegate <NSObject>
@optional
- (void)clickedNodeAtIndex:(NSUInteger)index;
@end
