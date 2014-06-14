//
//  UIView+BCODraggable.m
//  Draggable
//
//  Created by 阿部耕平 on 2014/06/09.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "UIView+BCODraggable.h"
#import <objc/runtime.h>

// IMPSwapInfo
@interface _IMPSwapInfo : NSObject
@property (nonatomic) IMP orgIMP;
@property (nonatomic) IMP altIMP;
@end

@implementation _IMPSwapInfo
@end

@interface _IMPSwapInfoManager : NSObject

@property (nonatomic, strong) NSMutableArray *swapInfoArray;

+ (_IMPSwapInfoManager *)sharedManager;
- (void)addSwapInfoWithOriginalIMP:(IMP)orgIMP alternativeIMP:(IMP)altIMP;
- (IMP)originalIMPWithAlternativeIMP:(IMP)altIMP;

@end

@implementation _IMPSwapInfoManager

+ (_IMPSwapInfoManager *)sharedManager
{
    static _IMPSwapInfoManager *_manager = nil;
    if (_manager == nil) {
        _manager = [[_IMPSwapInfoManager alloc] init];
    }
    return _manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _swapInfoArray = @[].mutableCopy;
    }
    return self;
}

- (void)addSwapInfoWithOriginalIMP:(IMP)orgIMP alternativeIMP:(IMP)altIMP
{
    _IMPSwapInfo *swapInfo = [[_IMPSwapInfo alloc] init];
    swapInfo.orgIMP = orgIMP;
    swapInfo.altIMP = altIMP;
    [_swapInfoArray addObject:swapInfo];
}

- (IMP)originalIMPWithAlternativeIMP:(IMP)altIMP
{
    for (_IMPSwapInfo *swapInfo in _swapInfoArray) {
        if (swapInfo.altIMP == altIMP)
            return swapInfo.orgIMP;
    }
    return NULL;
}

@end

// BCODraggable
@implementation UIView (BCODraggable)

@dynamic draggable;

- (BOOL)isDraggable
{
    NSNumber* isDraggable = objc_getAssociatedObject(self, @selector(isDraggable));
    if (!isDraggable)
        return NO;
    
    return isDraggable.boolValue;
}

- (void)setDraggable:(BOOL)draggable
{
    if ([self p_isFirstCallForThisInstance])
        [self p_replaceMethods];
    
    objc_setAssociatedObject(self, @selector(isDraggable), @(draggable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDragging
{
    NSNumber* isDragging = objc_getAssociatedObject(self, @selector(isDragging));
    if (!isDragging)
        return NO;
    
    return isDragging.boolValue;
}

#pragma mark - replaced method

- (void)touchesMoved_alt:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self isKindOfClass:[UIView class]])
        return;
    
    [self p_touchEvent:@selector(touchesMoved:withEvent:) touches:touches event:event dragging:YES];
}

- (void)touchesEnded_alt:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self isKindOfClass:[UIView class]])
        return;
    
    [self p_touchEvent:@selector(touchesEnded:withEvent:) touches:touches event:event dragging:NO];
}

- (void)touchesCancelled_alt:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self isKindOfClass:[UIView class]])
        return;
    
    [self p_touchEvent:@selector(touchesCancelled:withEvent:) touches:touches event:event dragging:NO];
}

- (void)p_touchEvent:(SEL)selector touches:(NSSet *)touches event:(UIEvent *)event dragging:(BOOL)isDragging
{
    if ([self isDraggable])
        [self p_dragToTouch:[touches anyObject]];
    
    [self p_callOriginalMethodForSelector:selector
                                  touches:touches
                                withEvent:event];
    
    if ([self isDragging])
        [self p_setDragging:isDragging];
}

#pragma mark - private

- (void)p_setDragging:(BOOL)isDragging
{
    objc_setAssociatedObject(self, @selector(isDragging), @(isDragging), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)p_dragToTouch:(UITouch *)touch
{
    CGPoint prevPoint = [touch previousLocationInView:self.superview];
    CGPoint currentPoint = [touch locationInView:self.superview];
    CGPoint diff = CGPointMake(currentPoint.x - prevPoint.x, currentPoint.y - prevPoint.y);
    self.frame = CGRectOffset(self.frame, diff.x, diff.y);
}

- (void)p_callOriginalMethodForSelector:(SEL)selector touches:(NSSet *)touches withEvent:(UIEvent *)event
{
    IMP currentIMP = [self methodForSelector:selector];
    IMP orgIMP = [[_IMPSwapInfoManager sharedManager] originalIMPWithAlternativeIMP:currentIMP];
    if (orgIMP != NULL) {
        void (*imp)(id,SEL,id,id) = (void(*)(id,SEL,id,id))orgIMP;
        imp(self, selector, touches, event);
    }
}

- (BOOL)p_isFirstCallForThisInstance
{
    if (objc_getAssociatedObject(self, @selector(isDraggable)))
        return NO;
    
    return YES;
}

- (void)p_replaceMethods
{
    // メソッドを入れ替え
    [self p_replaceMethod:@selector(touchesMoved:withEvent:)
                 toMethod:@selector(touchesMoved_alt:withEvent:)];
    [self p_replaceMethod:@selector(touchesEnded:withEvent:)
                 toMethod:@selector(touchesEnded_alt:withEvent:)];
    [self p_replaceMethod:@selector(touchesCancelled:withEvent:)
                 toMethod:@selector(touchesCancelled_alt:withEvent:)];
}


- (void)p_replaceMethod:(SEL)originalSEL toMethod:(SEL)altSEL
{
    // UIViewの子クラスでなければreturn
    if (![self isKindOfClass:[UIView class]])
        return;
    
    // すでに置き換えされていればreturn
    IMP orgIMP = [self methodForSelector:originalSEL];
    if ([[_IMPSwapInfoManager sharedManager] originalIMPWithAlternativeIMP:orgIMP] != NULL)
        return;
    
    // メソッドの実装入れ替え
    IMP altIMP = [self methodForSelector:altSEL];
    void(^altBlock)(id, id, id) = ^(id selfRef, id touches, id event) {
        void (*imp)(id,SEL,id,id) = (void(*)(id,SEL,id,id))altIMP;
        imp(selfRef, altSEL, touches, event);
    };
    
    IMP newAltImp = imp_implementationWithBlock(altBlock);
    Method originalMethod = class_getInstanceMethod([self class], originalSEL);
    method_setImplementation(originalMethod, newAltImp);
    
    // 元のメソッドを保存
    [[_IMPSwapInfoManager sharedManager] addSwapInfoWithOriginalIMP:orgIMP
                                                     alternativeIMP:newAltImp];
}

@end
