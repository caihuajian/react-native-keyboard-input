//
//  RCTCustomInputController.m
//
//  Created by Leo Natan (Wix) on 13/12/2016.
//  Copyright © 2016 Leo Natan. All rights reserved.
//

#import "RCTCustomInputController.h"
#import "RCTUIManager.h"
#import "RCTCustomKeyboardViewController.h"

NSString *const RCTCustomInputControllerKeyboardResigendEvent = @"keyboardResigned";

@protocol _WXInputHelperViewDelegate <NSObject>
-(void)_WXInputHelperViewResignFirstResponder:(UIView*)wxInputHelperView;
@end

@interface _WXInputHelperView : UIView

@property (nullable, nonatomic, readwrite, strong) UIInputViewController *inputViewController;
@property (nonatomic, weak) id<_WXInputHelperViewDelegate> delegate;

@end

@implementation _WXInputHelperView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    BOOL rv = [super resignFirstResponder];
    
    [self removeFromSuperview];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(_WXInputHelperViewResignFirstResponder:)])
    {
        [self.delegate _WXInputHelperViewResignFirstResponder:self];
    }
    
    return rv;
}

@end


@interface RCTCustomInputController () <_WXInputHelperViewDelegate>

@property(nonatomic) BOOL customInputComponentPresented;

@end

@implementation RCTCustomInputController

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[RCTCustomInputControllerKeyboardResigendEvent];
}

RCT_EXPORT_MODULE(CustomInputController)

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.customInputComponentPresented = NO;
    }
    return self;
}

-(BOOL)reactCanBecomeFirstResponder:(UIView*)inputField
{
    if([inputField respondsToSelector:@selector(reactWillMakeFirstResponder)])
    {
        [inputField performSelector:@selector(reactWillMakeFirstResponder)];
    }
    return [inputField canBecomeFirstResponder];
}

-(void)reactDidMakeFirstResponder:(UIView*)inputField
{
    if([inputField respondsToSelector:@selector(reactDidMakeFirstResponder)])
    {
        [inputField performSelector:@selector(reactDidMakeFirstResponder)];
    }
}

RCT_EXPORT_METHOD(presentCustomInputComponent:(nonnull NSNumber*)inputFieldTag params:(nonnull NSDictionary*)params)
{
    UIView* inputField = [self.bridge.uiManager viewForReactTag:inputFieldTag];
    BOOL canBecomeFirstResponder = [self reactCanBecomeFirstResponder:inputField];
    if(canBecomeFirstResponder)
    {
        [self reactDidMakeFirstResponder:inputField];
    }
    
    RCTBridge* bridge = [self.bridge valueForKey:@"parentBridge"];
    if(bridge != nil)
    {
        RCTRootView* rv = [[RCTRootView alloc] initWithBridge:bridge moduleName:params[@"component"] initialProperties:params[@"initialProps"]];
        RCTCustomKeyboardViewController* customKeyboardController = [[RCTCustomKeyboardViewController alloc] initWithRootView:rv];
        
        _WXInputHelperView* helperView = [[_WXInputHelperView alloc] initWithFrame:CGRectZero];
        helperView.delegate = self;
        helperView.backgroundColor = [UIColor clearColor];
        [inputField.superview addSubview:helperView];
        [inputField.superview sendSubviewToBack:helperView];
        
        helperView.inputViewController = customKeyboardController;
        [helperView reloadInputViews];
        [helperView becomeFirstResponder];
        
        self.customInputComponentPresented = YES;
    }
}

RCT_EXPORT_METHOD(resetInput:(nonnull NSNumber*)inputFieldTag)
{
    self.customInputComponentPresented = NO;
    
    UIView* inputField = [self.bridge.uiManager viewForReactTag:inputFieldTag];
    if([self reactCanBecomeFirstResponder:inputField])
    {
        [inputField becomeFirstResponder];
        [self reactDidMakeFirstResponder:inputField];
    }
}

#pragma mark - _WXInputHelperViewDelegate methods

-(void)_WXInputHelperViewResignFirstResponder:(UIView*)wxInputHelperView
{
    if(self.customInputComponentPresented)
    {
        [self sendEventWithName:RCTCustomInputControllerKeyboardResigendEvent body:nil];
    }
    self.customInputComponentPresented = NO;
}

@end
