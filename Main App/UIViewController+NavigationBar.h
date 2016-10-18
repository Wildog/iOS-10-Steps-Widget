// The MIT License (MIT)
//
// Copyright (c) 2016 Suyeol Jeon (xoul.kr)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <UIKit/UIKit.h>

@protocol UIViewControllerNavigationBar
@optional
/**
 @return whether the view controller use custom navigation bar instead of built-in navigation bar. Implement this
         method and return `YES` to use custom navigation bar in the view controller. Built-in navigation bar will be
         hidden when this method returns `YES`.
 */
- (BOOL)hasCustomNavigationBar;
@end

@interface UIViewController (NavigationBar) <UIViewControllerNavigationBar>

@property (nonatomic, strong, readonly, nonnull) UINavigationBar *navigationBar;

/**
 @return whether the view controller prefers navigation bar hidden. This method is only used when
         `hasCustomNavigationBar` does not implemented. Override this method and return `YES` if you want to make a
         view controller to hide built-in navigation bar. (default: NO)
 */
- (BOOL)prefersNavigationBarHidden;

@end
