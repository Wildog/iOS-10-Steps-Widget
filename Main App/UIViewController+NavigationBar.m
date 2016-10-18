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

#import "UIViewController+NavigationBar.h"
#import <objc/runtime.h>

void UIViewControllerNavigationBarSwizzle(Class cls, SEL originalSelector) {
    NSString *originalName = NSStringFromSelector(originalSelector);
    NSString *alternativeName = [NSString stringWithFormat:@"UIViewControllerNavigationBar_%@", originalName];

    SEL alternativeSelector = NSSelectorFromString(alternativeName);

    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method alternativeMethod = class_getInstanceMethod(cls, alternativeSelector);

    class_addMethod(cls,
                    originalSelector,
                    class_getMethodImplementation(cls, originalSelector),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(cls,
                    alternativeSelector,
                    class_getMethodImplementation(cls, alternativeSelector),
                    method_getTypeEncoding(alternativeMethod));

    method_exchangeImplementations(class_getInstanceMethod(cls, originalSelector),
                                   class_getInstanceMethod(cls, alternativeSelector));
}


@interface UIViewController (_NavigationBar) <UINavigationBarDelegate>
@end

@implementation UIViewController (NavigationBar)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIViewControllerNavigationBarSwizzle(self, @selector(navigationItem));
        UIViewControllerNavigationBarSwizzle(self, @selector(setTitle:));
        UIViewControllerNavigationBarSwizzle(self, @selector(viewWillAppear:));
        UIViewControllerNavigationBarSwizzle(self, @selector(viewDidAppear:));
        UIViewControllerNavigationBarSwizzle(self, @selector(viewDidLayoutSubviews));
    });
}


#pragma mark - Properties

- (UINavigationBar *)navigationBar {
    UINavigationBar *navigationBar = objc_getAssociatedObject(self, @selector(navigationBar));
    if (!navigationBar) {
        navigationBar = [[UINavigationBar alloc] init];
        navigationBar.delegate = self;
        objc_setAssociatedObject(self, @selector(navigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return navigationBar;
}

- (UINavigationItem *)UIViewControllerNavigationBar_navigationItem {
    if ([self isKindOfClass:UINavigationController.class]) {
        return self.UIViewControllerNavigationBar_navigationItem;
    }
    if (![self respondsToSelector:@selector(hasCustomNavigationBar)]) {
        return self.UIViewControllerNavigationBar_navigationItem;
    }
    SEL key = @selector(UIViewControllerNavigationBar_navigationItem);
    UINavigationItem *item = objc_getAssociatedObject(self, key);
    if (!item) {
        item = [[UINavigationItem alloc] init];
        objc_setAssociatedObject(self, key, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.navigationBar pushNavigationItem:item animated:NO];
    }
    return item;
}

/**
 UIViewController originally overwrites the value of `navigationItem.title` with the value of `title`. It doesn't work
 property because we have swizzled `navigationItem`. To make it available, swizzle the `setTitle:` method to assign
 the value manually.
 */
- (void)UIViewControllerNavigationBar_setTitle:(NSString *)title {
    [self UIViewControllerNavigationBar_setTitle:title];
    if ([self isKindOfClass:UINavigationController.class]) {
        return;
    }
    if (![self respondsToSelector:@selector(hasCustomNavigationBar)]) {
        return;
    }
    self.navigationItem.title = title;
}

- (BOOL)prefersNavigationBarHidden {
    NSString *className = NSStringFromClass(self.class);
    NSArray *externalClassNames = @[
        @"CKSMSComposeRemoteViewController",
        @"MFMailComposeRemoteViewController",
    ];
    return [externalClassNames containsObject:className];
}


#pragma mark - Updating navigation item

- (void)updateNavigationItem {
    if (![self respondsToSelector:@selector(hasCustomNavigationBar)]) {
        return;
    }
    if (!self.hasCustomNavigationBar) {
        return;
    }
    self.navigationBar.items = @[];
    if (self.navigationController.viewControllers.count > 1) {
        NSInteger index = [self.navigationController.viewControllers indexOfObject:self];
        UIViewController *viewController = self.navigationController.viewControllers[index - 1];
        UINavigationItem *prevItem = [self deepCopy:viewController.navigationItem];
        [self.navigationBar pushNavigationItem:prevItem animated:NO];
    }
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
}


#pragma mark - View life cycle

- (void)UIViewControllerNavigationBar_viewWillAppear:(BOOL)animated {
    [self UIViewControllerNavigationBar_viewWillAppear:animated];
    if ([self isKindOfClass:UINavigationController.class]) {
        return;
    }
    if (![self respondsToSelector:@selector(hasCustomNavigationBar)]) {
        [self.navigationController setNavigationBarHidden:self.prefersNavigationBarHidden animated:animated];
        return;
    }
    [self.navigationController setNavigationBarHidden:self.hasCustomNavigationBar animated:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    [self updateNavigationItem];
}

- (void)UIViewControllerNavigationBar_viewDidAppear:(BOOL)animated {
    [self UIViewControllerNavigationBar_viewDidAppear:animated];
    if ([self isKindOfClass:UINavigationController.class]) {
        return;
    }
    if (![self respondsToSelector:@selector(hasCustomNavigationBar)]) {
        return;
    }
    [self updateNavigationItem];
}

- (void)UIViewControllerNavigationBar_viewDidLayoutSubviews {
    [self UIViewControllerNavigationBar_viewDidLayoutSubviews];
    if ([self isKindOfClass:UINavigationController.class]) {
        return;
    }
    if (![self respondsToSelector:@selector(hasCustomNavigationBar)]) {
        return;
    }
    if (self.hasCustomNavigationBar) {
        if (CGRectIsEmpty(self.navigationBar.frame)) {
            self.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 64);
        }
        [self.view addSubview:self.navigationBar];
    } else {
        [self.navigationBar removeFromSuperview];
    }
}


#pragma mark - Utils

- (id)deepCopy:(id)object {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:object]];
}


#pragma mark - UINavigationBarDelegate

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

@end
