//
//  JMDropMenuView.h
//  animatePractice
//
//  Created by 李健銘 on 2014/3/31.
//  Copyright (c) 2014年 李健銘. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JMDropMenuView;

@protocol JMDropMenuViewDelegate <NSObject>
@optional
- (void)dropMenu:(JMDropMenuView *)menu didSelectAtIndex:(NSInteger)index;
- (void)didFinishedPopOutWithDropMenu:(JMDropMenuView *)menu;
- (void)didFinishedDismissWithDropMenu:(JMDropMenuView *)menu;
@end

typedef NS_ENUM(NSInteger,Animate_Drop_To ) {
    Animate_Drop_To_Top,
    Animate_Drop_To_Bottom,
    Animate_Drop_To_Right,
    Animate_Drop_To_Left
};

@interface JMDropMenuView : UIView

@property (nonatomic, assign) id<JMDropMenuViewDelegate>delegate;
@property (readonly, retain) NSArray *imgViews;
@property (nonatomic)float animateInterval;
@property (nonatomic)NSInteger animateDirect;

- (id)initWithViews:(NSArray *)imgViews;
- (void)setUpViews;
- (void)popOut;
- (void)dismiss;
- (void)resetPosition;

@end
