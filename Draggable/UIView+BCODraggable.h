//
//  UIView+BCODraggable.h
//  Draggable
//
//  Created by 阿部耕平 on 2014/06/09.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (BCODraggable)

@property (nonatomic, getter=isDraggable) BOOL draggable;
@property (nonatomic, readonly) BOOL isDragging;

@end
