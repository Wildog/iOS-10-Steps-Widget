//
//  LineChartView.m
//  LineChart
//
//  Created by Wildog on 9/16/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import "LineChartView.h"
#import "ChartNodeView.h"

@interface LineChartView() {
    NSUInteger _lastSelected;
    BOOL _dataLoaded;
}
@end

@implementation LineChartView

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
    self.marginH = 30;
    self.marginV = 15;
    self.backgroundColor = [UIColor clearColor];
    self.backgroundLineWidth = 0.5;
    self.backgroundLineColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
    self.averageLineColor = [UIColor colorWithHue:0 saturation:0 brightness:0.8 alpha:0.3];
    self.labelColor = [UIColor colorWithHue:0 saturation:0 brightness:0.5 alpha:1];
    self.chartLineColor = [UIColor colorWithHue:0.52 saturation:1 brightness:0.83 alpha:1];
    self.gradientColors = @[(__bridge id)[UIColor colorWithHue:0.57 saturation:0.74 brightness:0.86 alpha:1].CGColor,
                            (__bridge id)[UIColor colorWithHue:0.52 saturation:1 brightness:0.76 alpha:1].CGColor,
                            (__bridge id)[UIColor colorWithHue:0.52 saturation:1 brightness:0.83 alpha:1].CGColor];
    self.chartLineWidth = 3;
    self.nodeSize = 13;
    self.animationDuration = 1.2;
    self.animated = YES;
    self.gradiented = YES;
    self.showLabel = YES;
    self.showAverageLine = YES;
    _dataLoaded = NO;
}

- (void)setDelegate:(id<LineChartViewDelegate>)delegate {
    _delegate = delegate;
    _lastSelected = [self.dataSource numberOfElements] - 1;
}

- (void)loadData {
    _lastSelected = [self.dataSource numberOfElements] - 1;
    _dataLoaded = YES;
    [self setNeedsDisplay];
}

- (void)loadDataWithSelectedKept {
    _dataLoaded = YES;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [[self.layer sublayers] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    NSUInteger numberCount = [self.dataSource numberOfElements];
    CGFloat maxValue = [self.dataSource maxValue];
    CGFloat minValue = [self.dataSource minValue];
    CGFloat labelWidth = 30;
    CGFloat labelHeight = 0;
    if (self.showLabel) labelHeight = 20;
    
    if (self.marginV < 10) self.marginV = 10;
    CGFloat chartHeight = self.frame.size.height - self.marginV * 2 - labelHeight;
    CGFloat startX = self.marginH;
    CGFloat interval = (self.frame.size.width - self.marginH * 2) / (numberCount - 1);
    
    UIBezierPath *chartLine = [UIBezierPath bezierPath];
    NSMutableArray *nodesArray = [[NSMutableArray alloc] initWithCapacity:numberCount];
    
    for (NSUInteger i = 0; i < numberCount; i++) {
        //draw background lines
        CGFloat xPos = startX + i * interval;
        UIBezierPath* verticalLine = [UIBezierPath bezierPath];
        [verticalLine moveToPoint: CGPointMake(xPos, self.marginV - 5)];
        [verticalLine addLineToPoint: CGPointMake(xPos, self.marginV + chartHeight + 5)];
        [self.backgroundLineColor setStroke];
        verticalLine.lineWidth = self.backgroundLineWidth;
        verticalLine.lineCapStyle = kCGLineCapRound;
        [verticalLine stroke];
        
        //draw labels
        if (self.showLabel && [self.delegate respondsToSelector:@selector(labelForElementAtIndex:)]) {
            NSString *labelText   = [self.dataSource labelForElementAtIndex:i];
            UILabel *label        = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, labelHeight)];
            label.center          = CGPointMake(xPos, self.marginV + chartHeight + 10 + 20);
            label.text            = labelText;
            label.font            = [UIFont fontWithName:@"Avenir" size:11.0];
            label.textColor       = self.labelColor;
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment   = NSTextAlignmentCenter;
            label.numberOfLines   = 0;
            [self addSubview:label];
        }
        
        if (_dataLoaded) {
            //make nodes
            CGPoint nodeCenter = CGPointMake(xPos, self.marginV + chartHeight * (1 - ([self.dataSource valueForElementAtIndex:i] - minValue) / (maxValue - minValue)));
            ChartNodeView *node = [[ChartNodeView alloc] initWithFrame:CGRectMake(0, 0, self.nodeSize * 2, self.nodeSize * 2)];
            node.center = nodeCenter;
            node.index = i;
            if (self.animated) {
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
        if (self.showAverageLine && [self.delegate respondsToSelector:@selector(averageValue)]) {
            CGFloat average = [self.dataSource averageValue];
            CGFloat yPos = self.marginV + chartHeight * (1 - (average - minValue) / (maxValue - minValue));
            
            UIBezierPath* averageLine = [UIBezierPath bezierPath];
            [averageLine moveToPoint: CGPointMake(startX, yPos)];
            [averageLine addLineToPoint: CGPointMake(self.frame.size.width - self.marginH, yPos)];
            
            CAShapeLayer *averageLineShape = [CAShapeLayer layer];
            averageLineShape.path          = averageLine.CGPath;
            averageLineShape.lineWidth     = self.backgroundLineWidth;
            averageLineShape.strokeColor   = self.averageLineColor.CGColor;
            averageLineShape.fillColor     = [UIColor clearColor].CGColor;
            averageLineShape.lineCap       = kCALineCapButt;
            
            if (self.animated) {
                CGFloat upBy = chartHeight * (average - minValue) / (maxValue - minValue) + 5;
                averageLineShape.position = CGPointMake(averageLineShape.position.x, averageLineShape.position.y + upBy);
                averageLineShape.opacity = 0;

                CASpringAnimation *positionYAnimation  = [CASpringAnimation animationWithKeyPath:@"position.y"];
                positionYAnimation.beginTime           = CACurrentMediaTime() + self.animationDuration * 3/4;
                positionYAnimation.duration            = self.animationDuration / 2;
                positionYAnimation.removedOnCompletion = NO;
                positionYAnimation.fillMode            = kCAFillModeForwards;
                positionYAnimation.byValue             = [NSNumber numberWithDouble:-upBy];
                positionYAnimation.timingFunction      = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
                [averageLineShape addAnimation:positionYAnimation forKey:@"positionYAnimation"];
                
                CABasicAnimation *opacityAnimation   = [CABasicAnimation animationWithKeyPath:@"opacity"];
                opacityAnimation.beginTime           = CACurrentMediaTime() + self.animationDuration * 3/4;
                opacityAnimation.duration            = self.animationDuration / 2;
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
        chartLineShape.lineWidth     = self.chartLineWidth;
        chartLineShape.strokeColor   = [UIColor colorWithHue:0.52 saturation:1 brightness:0.83 alpha:1].CGColor;
        chartLineShape.fillColor     = [UIColor clearColor].CGColor;
        chartLineShape.lineCap       = kCALineCapRound;
        chartLineShape.lineJoin      = kCALineJoinRound;
        
        if (self.animated) {
            CABasicAnimation *drawAnimation   = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            drawAnimation.duration            = self.animationDuration;
            drawAnimation.repeatCount         = 1.0;
            drawAnimation.removedOnCompletion = YES;
            drawAnimation.fromValue           = [NSNumber numberWithFloat:0.0f];
            drawAnimation.toValue             = [NSNumber numberWithFloat:1.0f];
            drawAnimation.timingFunction      = [CAMediaTimingFunction functionWithControlPoints: 0.348 : 0.000 : 0.285 : 0.743];
            [chartLineShape addAnimation:drawAnimation forKey:@"drawChartLineAnimation"];
        }
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame            = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        NSArray *gradient              = self.gradientColors;
        if (!self.gradiented) gradient = @[(__bridge id)self.chartLineColor.CGColor,(__bridge id)self.chartLineColor.CGColor];
        gradientLayer.colors           = gradient;
        gradientLayer.startPoint       = CGPointMake(0,0.5);
        gradientLayer.endPoint         = CGPointMake(1,0.5);
        
        [self.layer addSublayer:gradientLayer];
        gradientLayer.mask = chartLineShape;
        
        //popup animation for nodes
        CGFloat delay = 0;
        CGFloat delta = self.animationDuration / (numberCount + 1);
        for (ChartNodeView* node in nodesArray) {
            [self addSubview:node];
            if (self.animated) {
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
    
    if ([touchView isKindOfClass:[ChartNodeView class]]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[ChartNodeView class]]) {
                ChartNodeView *nodeView = (ChartNodeView*)subview;
                if (nodeView.isActive) [nodeView toggleState];
            }
        }
        ChartNodeView *touchNode = (ChartNodeView*)touchView;
        [touchNode toggleState];
        _lastSelected = touchNode.index;
        if ([self.delegate respondsToSelector:@selector(clickedNodeAtIndex:)]) {
            [self.delegate clickedNodeAtIndex:_lastSelected];
        }
    }
}

@end
