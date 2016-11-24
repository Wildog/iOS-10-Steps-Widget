//
//  LineChartView.m
//  LineChart
//
//  Created by Wildog on 9/16/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import "WDLineChartView.h"
#import "WDChartNodeView.h"

@interface WDLineChartView() {
    NSUInteger _lastSelected;
    BOOL _dataLoaded;
}
@end

@implementation WDLineChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults {
    _marginH = 30;
    _marginV = 15;
    _labelHeight = 20;
    self.backgroundColor = [UIColor clearColor];
    _backgroundLineWidth = 0.5;
    _backgroundLineColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
    _averageLineColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
    _labelColor = [UIColor colorWithHue:0 saturation:0 brightness:0.5 alpha:1];
    _chartLineColor = [UIColor colorWithHue:0.52 saturation:1 brightness:0.83 alpha:1];
    _gradientColors = @[(__bridge id)[UIColor colorWithHue:0.57 saturation:0.74 brightness:0.86 alpha:1].CGColor,
                            (__bridge id)[UIColor colorWithHue:0.52 saturation:1 brightness:0.76 alpha:1].CGColor,
                            (__bridge id)[UIColor colorWithHue:0.52 saturation:1 brightness:0.83 alpha:1].CGColor];
    _chartLineWidth = 3;
    _nodeSize = 13;
    _animationDuration = 1.2;
    _animated = YES;
    _gradiented = YES;
    _showLabel = YES;
    _showAverageLine = YES;
    _dataLoaded = NO;
}

- (void)setDelegate:(id<WDLineChartViewDelegate>)delegate {
    _delegate = delegate;
    _lastSelected = [_dataSource numberOfElements] - 1;
}

- (void)loadData {
    _lastSelected = [_dataSource numberOfElements] - 1;
    _dataLoaded = YES;
    [self setNeedsDisplay];
}

- (void)loadDataWithSelectedKept {
    _dataLoaded = YES;
    [self setNeedsDisplay];
}

- (void)removeSublayers {
    [[self.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

- (void)drawRect:(CGRect)rect {
    [self removeSublayers];
    
    NSUInteger numberCount = [_dataSource numberOfElements];
    CGFloat maxValue = [_dataSource maxValue];
    CGFloat minValue = [_dataSource minValue];
    CGFloat labelWidth = 30;
    if (!_showLabel) _labelHeight = 0;
    
    if (_marginV < 10) _marginV = 10;
    CGFloat chartHeight = self.frame.size.height - _marginV * 2 - _labelHeight;
    CGFloat startX = _marginH;
    CGFloat interval = (self.frame.size.width - _marginH * 2) / (numberCount - 1);
    
    UIBezierPath *chartLine = [UIBezierPath bezierPath];
    NSMutableArray *nodesArray = [[NSMutableArray alloc] initWithCapacity:numberCount];
    
    for (NSUInteger i = 0; i < numberCount; i++) {
        //draw background lines
        CGFloat xPos = startX + i * interval;
        UIBezierPath* verticalLine = [UIBezierPath bezierPath];
        [verticalLine moveToPoint: CGPointMake(xPos, _marginV - 5)];
        [verticalLine addLineToPoint: CGPointMake(xPos, _marginV + chartHeight + 5)];
        [_backgroundLineColor setStroke];
        verticalLine.lineWidth = _backgroundLineWidth;
        verticalLine.lineCapStyle = kCGLineCapRound;
        [verticalLine stroke];
        
        //draw labels
        if (_showLabel && [_delegate respondsToSelector:@selector(labelForElementAtIndex:)]) {
            NSString *labelText   = [_dataSource labelForElementAtIndex:i];
            UILabel *label        = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, _labelHeight)];
            label.center          = CGPointMake(xPos, _marginV + chartHeight + 10 + _labelHeight);
            label.text            = labelText;
            label.font            = [UIFont fontWithName:@"Avenir" size:11.0];
            label.textColor       = _labelColor;
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment   = NSTextAlignmentCenter;
            label.numberOfLines   = 0;
            [self addSubview:label];
        }
        
        if (_dataLoaded) {
            //make nodes
            CGPoint nodeCenter = CGPointMake(xPos, _marginV + chartHeight * (1 - ([_dataSource valueForElementAtIndex:i] - minValue) / (maxValue - minValue)));
            WDChartNodeView *node = [[WDChartNodeView alloc] initWithFrame:CGRectMake(0, 0, _nodeSize * 2, _nodeSize * 2)];
            node.center = nodeCenter;
            node.index = i;
            if (_animated) {
                node.transform = CGAffineTransformMakeScale(0, 0);
                node.alpha = 0;
            }
            if (i == _lastSelected) node.isActive = YES;
            [nodesArray addObject:node];
            
            //construct chart lines
            if (i == 0) [chartLine moveToPoint: nodeCenter];
            else        [chartLine addLineToPoint: nodeCenter];
        }
    }
    
    if (_dataLoaded) {
        //draw average line
        if (_showAverageLine && [_delegate respondsToSelector:@selector(averageValue)]) {
            CGFloat average = [_dataSource averageValue];
            CGFloat yPos = _marginV + chartHeight * (1 - (average - minValue) / (maxValue - minValue));
            
            UIBezierPath* averageLine = [UIBezierPath bezierPath];
            [averageLine moveToPoint: CGPointMake(startX, yPos)];
            [averageLine addLineToPoint: CGPointMake(self.frame.size.width - _marginH, yPos)];
            
            CAShapeLayer *averageLineShape = [CAShapeLayer layer];
            averageLineShape.path          = averageLine.CGPath;
            averageLineShape.lineWidth     = _backgroundLineWidth;
            averageLineShape.strokeColor   = _averageLineColor.CGColor;
            averageLineShape.fillColor     = [UIColor clearColor].CGColor;
            averageLineShape.lineCap       = kCALineCapButt;
            
            if (_animated) {
                CGFloat upBy = chartHeight * (average - minValue) / (maxValue - minValue) + 5;
                averageLineShape.position = CGPointMake(averageLineShape.position.x, averageLineShape.position.y + upBy);
                averageLineShape.opacity = 0;

                CASpringAnimation *positionYAnimation  = [CASpringAnimation animationWithKeyPath:@"position.y"];
                positionYAnimation.beginTime           = CACurrentMediaTime() + _animationDuration * 3/4;
                positionYAnimation.duration            = _animationDuration / 2;
                positionYAnimation.removedOnCompletion = NO;
                positionYAnimation.fillMode            = kCAFillModeForwards;
                positionYAnimation.byValue             = [NSNumber numberWithDouble:-upBy];
                positionYAnimation.timingFunction      = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
                [averageLineShape addAnimation:positionYAnimation forKey:@"positionYAnimation"];
                
                CABasicAnimation *opacityAnimation   = [CABasicAnimation animationWithKeyPath:@"opacity"];
                opacityAnimation.beginTime           = CACurrentMediaTime() + _animationDuration * 3/4;
                opacityAnimation.duration            = _animationDuration / 2;
                opacityAnimation.removedOnCompletion = NO;
                opacityAnimation.fillMode            = kCAFillModeForwards;
                opacityAnimation.byValue             = [NSNumber numberWithDouble:1];
                opacityAnimation.timingFunction      = [CAMediaTimingFunction functionWithControlPoints: 0.090 : 0.271 : 0.223 : 0.841];
                [averageLineShape addAnimation:opacityAnimation forKey:@"opacityAnimation"];
            }
            [self.layer addSublayer:averageLineShape];
        }
    
        //draw chart line shape masked gradient layer
        CAShapeLayer *chartLineShape = [CAShapeLayer layer];
        chartLineShape.path          = chartLine.CGPath;
        chartLineShape.lineWidth     = _chartLineWidth;
        chartLineShape.strokeColor   = [UIColor colorWithHue:0.52 saturation:1 brightness:0.83 alpha:1].CGColor;
        chartLineShape.fillColor     = [UIColor clearColor].CGColor;
        chartLineShape.lineCap       = kCALineCapRound;
        chartLineShape.lineJoin      = kCALineJoinRound;
        
        if (_animated) {
            CABasicAnimation *drawAnimation   = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            drawAnimation.duration            = _animationDuration;
            drawAnimation.repeatCount         = 1.0;
            drawAnimation.removedOnCompletion = YES;
            drawAnimation.fromValue           = [NSNumber numberWithFloat:0.0f];
            drawAnimation.toValue             = [NSNumber numberWithFloat:1.0f];
            drawAnimation.timingFunction      = [CAMediaTimingFunction functionWithControlPoints: 0.348 : 0.000 : 0.285 : 0.743];
            [chartLineShape addAnimation:drawAnimation forKey:@"drawChartLineAnimation"];
        }
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame            = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        NSArray *gradient              = _gradientColors;
        if (!_gradiented) gradient = @[(__bridge id)_chartLineColor.CGColor,(__bridge id)_chartLineColor.CGColor];
        gradientLayer.colors           = gradient;
        gradientLayer.startPoint       = CGPointMake(0,0.5);
        gradientLayer.endPoint         = CGPointMake(1,0.5);
        
        [self.layer addSublayer:gradientLayer];
        gradientLayer.mask = chartLineShape;
        
        //popup animation for nodes
        CGFloat delay = 0;
        CGFloat delta = _animationDuration / (numberCount + 1);
        for (WDChartNodeView* node in nodesArray) {
            [self addSubview:node];
            if (_animated) {
                [UIView animateWithDuration:0.5 delay:delay usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{
                    node.alpha = 1;
                    node.transform = CGAffineTransformMakeScale(1, 1);
                } completion:^(BOOL finished){}];
                delay += delta;
            }
        }
    }
}

#pragma mark - touch detection

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchPoint:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchPoint:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    UIView *touchView = [self hitTest:touchPoint withEvent:nil];
    
    if ([touchView isKindOfClass:[WDChartNodeView class]]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[WDChartNodeView class]]) {
                WDChartNodeView *nodeView = (WDChartNodeView*)subview;
                if (nodeView.isActive) [nodeView toggleState];
            }
        }
        WDChartNodeView *touchNode = (WDChartNodeView*)touchView;
        [touchNode toggleState];
        _lastSelected = touchNode.index;
        if ([_delegate respondsToSelector:@selector(clickedNodeAtIndex:)]) {
            [_delegate clickedNodeAtIndex:_lastSelected];
        }
    }
}

@end
