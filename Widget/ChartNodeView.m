//
//  ChartNodeView.m
//  LineChart
//
//  Created by Wildog on 9/16/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import "ChartNodeView.h"

@interface ChartNodeView()
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *activeColor;
@property (nonatomic, strong) UIColor *shadowColor;
@end

@implementation ChartNodeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.color = [UIColor colorWithRed:0.221 green:0.687 blue:0.904 alpha:1.000];
        self.activeColor = [UIColor colorWithRed:1 green:0.6 blue:0 alpha:1];
        self.shadowColor = [UIColor colorWithRed: 0.184 green: 0.506 blue: 0.718 alpha: 1];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CAShapeLayer *nodeShape = [CAShapeLayer layer];
    nodeShape.path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(rect.origin.x + rect.size.width / 4, rect.origin.y + rect.size.height / 4, rect.size.width / 2, rect.size.height / 2)].CGPath;
    nodeShape.anchorPoint = CGPointMake(0.5, 0.5);
    if (self.isActive) {
        nodeShape.fillColor = self.activeColor.CGColor;
        self.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.3);
    } else {
        nodeShape.fillColor = self.color.CGColor;
    }
    nodeShape.strokeColor = [UIColor whiteColor].CGColor;
    nodeShape.lineWidth = 2;
    nodeShape.shadowColor = self.shadowColor.CGColor;
    nodeShape.shadowOpacity = 0.5;
    nodeShape.shadowOffset = CGSizeMake(0, 0.5);
    nodeShape.shadowRadius = 2;
    
    [self.layer addSublayer:nodeShape];
}

- (void)toggleState {
    CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
    colorAnimation.duration            = 0.2;
    colorAnimation.repeatCount         = 1.0;
    colorAnimation.fillMode            = kCAFillModeForwards;
    colorAnimation.removedOnCompletion = NO;
    if (self.isActive) {
        colorAnimation.fromValue       = (id)self.activeColor.CGColor;
        colorAnimation.toValue         = (id)self.color.CGColor;
    } else {
        colorAnimation.fromValue       = (id)self.color.CGColor;
        colorAnimation.toValue         = (id)self.activeColor.CGColor;
    }
    colorAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
    [[[self.layer sublayers] lastObject] addAnimation:colorAnimation forKey:@"colorAnimation"];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.duration            = 0.2;
    scaleAnimation.repeatCount         = 1.0;
    scaleAnimation.fillMode            = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = NO;
    if (self.isActive) {
        scaleAnimation.fromValue       = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.3, 1.3, 1.0)];
        scaleAnimation.toValue         = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
        self.isActive = NO;
    } else {
        scaleAnimation.fromValue       = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
        scaleAnimation.toValue         = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.3, 1.3, 1.0)];
        self.isActive = YES;
    }
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints: 0.299 : 0.000 : 0.292 : 0.910];
    [self.layer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
}

@end
