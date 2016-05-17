//
//  WCActionSheet.m
//  WCActionSheet
//
//  Created by Wojciech Czekalski on 27.02.2014.
//  Copyright (c) 2014 Wojciech Czekalski. All rights reserved.
//

#import "WCActionSheet.h"

#define kButtonHeight 50.f
#define kTitleButtonHeight 50.f
#define kCancelButtonHeight 60.f

#define kAnimationDuration 0.2f

#define kSeparatorWidth .5f

#define kMargin 0.f
#define kBottomMargin 0.f

@interface WCActionSheet ()
@property (nonatomic, readonly) CGSize screenSize;

@property (nonatomic, strong, readonly) NSMutableArray *buttonTitles;

@property (nonatomic, strong, readonly) NSMutableArray *buttons;

@property (nonatomic, strong, readonly) NSMutableDictionary *buttonTitleAttributes;

@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong, readonly) NSArray *separators;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) NSMutableDictionary *actionBlockForButtonIndex;

- (void)setTitle:(NSString *)title;
- (void)setCancelButtonWithTitle:(NSString *)title;


- (void)dismissWithClickedButton:(UIButton *)button;

- (void)dismissWithCancelButton:(UIButton *)cancelButton;

- (void)dismissAnimated:(BOOL)animated clickedButtonIndex:(NSInteger)index;

- (void)dismissTransition;
- (void)dismissCompletionWithButtonAtIndex:(NSInteger)index;

- (NSInteger)indexOfButton:(UIButton *)button;

@end

static UIWindow *__sheetWindow = nil;

@implementation WCActionSheet {
    UIColor *__backgroundColor;
}

@synthesize buttonTitles = _buttonTitles;
@synthesize buttons = _buttons;
@synthesize buttonTitleAttributes = _buttonTitleAttributes;

#pragma mark -

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // Initialization code
        [self __commonInit];
        
        [self setCancelButtonWithTitle:@"Cancel"];
    }
    return self;
}

- (instancetype)init {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        ;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<WCActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle title:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ... {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self __commonInit];
        
        _delegate = delegate;
        [self setCancelButtonWithTitle:cancelButtonTitle];
        [self setTitle:title];
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *title = otherButtonTitles; title != nil; title = va_arg(args, NSString*))
        {
            [self addButtonWithTitle:title];
        }
        va_end(args);
        
    }
    
    return self;
}

- (void)__commonInit {
    
    self.backgroundColor = [UIColor whiteColor];
    _highlightedButtonColor = [UIColor colorWithWhite:0.93f alpha:1.f];
    _separatorColor = [UIColor colorWithWhite:0.8 alpha:1.f];
    
    self.clipsToBounds = YES;
}

#pragma mark -

- (NSInteger)addButtonWithTitle:(NSString *)title {
    if (!title) {
        [self.buttonTitles addObject:@""];
    } else [self.buttonTitles addObject:title];
    
    UIButton *newButton = [UIButton buttonWithType:UIButtonTypeSystem];
    newButton.titleLabel.font = [UIFont systemFontOfSize:19.f];
    [newButton setFrame:CGRectMake(0, 0, self.screenSize.width, kButtonHeight)];
    [newButton setTitle:title forState:UIControlStateNormal];
    [newButton addTarget:self action:@selector(dismissWithClickedButton:) forControlEvents:UIControlEventTouchUpInside];
    NSUInteger index = [self.buttons count];
    
    [self addSubview:newButton];
    [self.buttons addObject:newButton];
//    [self.buttonTitles addObject:title];
    
    return index;
    
}

- (NSInteger)addButtonWithTitle:(NSString *)title actionBlock:(void (^)())actionBlock {
    NSInteger index = [self addButtonWithTitle:title];
    [self.actionBlockForButtonIndex setObject:actionBlock forKey:[NSNumber numberWithInteger:index]];
    return index;
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == self.cancelButtonIndex) {
        return [self.cancelButton titleForState:UIControlStateNormal];
    }
    return self.buttonTitles[buttonIndex];
}

- (void)setButtonTextAttributes:(NSDictionary *)attributes withIndex:(NSInteger)buttonIndex state:(UIControlState )state {
    UIButton *button = self.buttons[buttonIndex];
    NSAttributedString *attributedTitleForState = [[NSAttributedString alloc] initWithString:[button titleForState:state] attributes:attributes];
    [button setAttributedTitle:attributedTitleForState forState:state];    
}

#pragma mark -

- (void)setTitle:(NSString *)title {
    if (title) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

        [button setFrame:CGRectMake(0, 0, self.screenSize.width, kTitleButtonHeight)];
        button.titleLabel.numberOfLines = 2;
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [button setAdjustsImageWhenHighlighted:NO];
        
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:5];
        [style setAlignment:NSTextAlignmentCenter];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attributedTitle addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14],NSForegroundColorAttributeName:[UIColor grayColor]} range:NSMakeRange(0,title.length)];
        [attributedTitle addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, title.length)];
        [button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        self.titleButton = button;
        
        [self addSubview:button];
        [self.buttons insertObject:button atIndex:0];
        [self.buttonTitles insertObject:title atIndex:0];
    }
}

- (void)setCancelButtonWithTitle:(NSString *)title {
    if (self.cancelButton) {
        [self.cancelButton removeFromSuperview];
        self.cancelButton = nil;
    }
    if (title) {
        UIButton *newCancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        newCancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:19.f];
        [newCancelButton setFrame:CGRectMake(0, 0, self.screenSize.width, kCancelButtonHeight)];
        [newCancelButton setTitle:title forState:UIControlStateNormal];
        [newCancelButton addTarget:self action:@selector(dismissWithCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        self.cancelButton = newCancelButton;

        [self addSubview:newCancelButton];
    }
}

#pragma mark -

- (void)layoutSubviews {
    [super layoutSubviews];
    // calculate frames here
    
    CGSize screenSize = self.screenSize;
    
    CGFloat contentWidth = screenSize.width - (2*kMargin);
    
//    CGFloat sheetHeight = ([self.buttons count] * kButtonHeight) + kCancelButtonHeight;
    CGFloat sheetHeight = 0.f;
    if (self.titleButton) {
        sheetHeight = (([self.buttons count] -1) * kButtonHeight) + kCancelButtonHeight + kTitleButtonHeight;
    } else {
        sheetHeight = ([self.buttons count] * kButtonHeight) + kCancelButtonHeight;
    }
    
    CGFloat contentOffset = screenSize.height - sheetHeight  - kBottomMargin;
    
    self.frame = CGRectMake(kMargin, contentOffset, contentWidth, sheetHeight);
    
    contentOffset = 0.f;
    
    for (UIButton *button in self.buttons) {
        if (button == self.titleButton) {
            button.frame = CGRectMake(0.f, contentOffset, contentWidth, kTitleButtonHeight);
            contentOffset += kTitleButtonHeight;
        } else {
            button.frame = CGRectMake(0.f, contentOffset, contentWidth, kButtonHeight);
            contentOffset += kButtonHeight;
        }
    }
    
    if (self.cancelButton) {
        self.cancelButton.frame = CGRectMake(0.f, contentOffset, contentWidth, kCancelButtonHeight);
        contentOffset += kCancelButtonHeight;
    }
}

#pragma mark - Show

- (void)show {
    UIWindow *window = [[UIWindow alloc] initWithFrame:(CGRect) {{0.f, 0.f}, self.screenSize}];
    window.windowLevel = UIWindowLevelNormal;
    window.backgroundColor = [UIColor colorWithRed:84 / 255.0 green:84 / 255.0 blue:84 / 255.0 alpha:0.4];
    [self layoutIfNeeded];
    UITapGestureRecognizer *closeWindow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissWindow)];
    [window addGestureRecognizer:closeWindow];
    
    for (UIView *separator in self.separators) {
        [self addSubview:separator];
    }
    
    [window addSubview:self];
	
    [window makeKeyAndVisible];
    
    self.frame = CGRectOffset(self.frame, 0.f, self.frame.size.height+kMargin);

    if ([self.delegate respondsToSelector:@selector(willPresentActionSheet:)]) {
        [self.delegate willPresentActionSheet:self];
    }

    [UIView animateWithDuration:kAnimationDuration delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.frame = CGRectOffset(self.frame, 0.f, -(self.frame.size.height+kMargin));
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(didPresentActionSheet:)]) {
            [self.delegate didPresentActionSheet:self];
        }
    }];
    
    __sheetWindow = window;
}

#pragma mark - Dismissal

- (void)dismissWindow {
    [self dismissWithCancelButton:nil];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    [self dismissAnimated:animated clickedButtonIndex:buttonIndex];
}

- (void)dismissWithClickedButton:(UIButton *)button {
    NSInteger buttonIndex = [self indexOfButton:button];
    
    void (^actionBlockForButton)() = [self.actionBlockForButtonIndex objectForKey:[NSNumber numberWithInteger:buttonIndex]];
    
    if (actionBlockForButton) {
        actionBlockForButton();
    } else if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
        [self.delegate actionSheet:self clickedButtonAtIndex:buttonIndex];
    }
    [self dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

- (void)dismissWithCancelButton:(UIButton *)cancelButton {
    if ([self.delegate respondsToSelector:@selector(actionSheetCancel:)]) {
        [self.delegate actionSheetCancel:self];
    } else if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
        [self.delegate actionSheet:self clickedButtonAtIndex:self.cancelButtonIndex];
    }
    [self dismissAnimated:YES clickedButtonIndex:self.cancelButtonIndex];
}

- (void)dismissAnimated:(BOOL)animated clickedButtonIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)]) {
        [self.delegate actionSheet:self willDismissWithButtonIndex:index];
    }
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [self dismissTransition];
        } completion:^(BOOL finished) {
            [self dismissCompletionWithButtonAtIndex:index];
        }];
    } else {
        [self dismissCompletionWithButtonAtIndex:index];
    }
}

- (void)dismissTransition {
    self.frame = CGRectOffset(self.frame, 0.f, self.frame.size.height + kBottomMargin);
}

- (void)dismissCompletionWithButtonAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)]) {
        [self.delegate actionSheet:self didDismissWithButtonIndex:index];
    }
    __sheetWindow.hidden = YES;
    __sheetWindow = nil;
}


#pragma mark - Appearance

- (void)setTitleButtonTextAttributes:(NSDictionary *)attributes forState:(UIControlState)state {
    [UIView performWithoutAnimation:^{
        // change titleForState to attributedTitleForState
        NSAttributedString *attributedTitleForState = [[NSAttributedString alloc] initWithString:[self.titleButton titleForState:UIControlStateNormal] attributes:attributes];
        [self.titleButton setAttributedTitle:attributedTitleForState forState:state];
    }];
}

- (NSDictionary *)titleButtonTextAttributesForState:(UIControlState)state {
    return [[self.titleButton attributedTitleForState:state] attributesAtIndex:0 effectiveRange:0];
}

- (void)setCancelButtonTextAttributes:(NSDictionary *)attributes forState:(UIControlState)state {
    [UIView performWithoutAnimation:^{
        NSAttributedString *attributedTitleForState = [[NSAttributedString alloc] initWithString:[self.cancelButton titleForState:state] attributes:attributes];
        [self.cancelButton setAttributedTitle:attributedTitleForState forState:state];
    }];
}

- (NSDictionary *)cancelButtonTextAttributesForState:(UIControlState)state {
    return [[self.cancelButton attributedTitleForState:state] attributesAtIndex:0 effectiveRange:0];
}

- (void)setButtonTextAttributes:(NSDictionary *)attributes forState:(UIControlState)state {
    [UIView performWithoutAnimation:^{
        [self.buttonTitleAttributes setObject:attributes forKey:[NSNumber numberWithInt:state]];
        for (UIButton *button in self.buttons) {
            if (button != self.titleButton) {
                NSAttributedString *attributedTitleForState = [[NSAttributedString alloc] initWithString:[button titleForState:state] attributes:attributes];
                [button setAttributedTitle:attributedTitleForState forState:state];
            }
        }
    }];
}

- (NSDictionary *)buttonTextAttributesForState:(UIControlState)state {
    return [self.buttonTitleAttributes objectForKey:[NSNumber numberWithInt:state]];
}

#pragma mark - Getters

- (NSInteger)indexOfButton:(UIButton *)button {
    if (button == self.cancelButton) {
        return [self cancelButtonIndex];
    }
    return [self.buttons indexOfObject:button];
}

- (NSInteger)titleButtonIndex {
    return self.titleButton ? 0 : NSNotFound;
}

- (NSInteger)cancelButtonIndex {
    return [self.buttons count];
}

- (NSMutableDictionary *)actionBlockForButtonIndex {
    if (!_actionBlockForButtonIndex) {
        _actionBlockForButtonIndex = [NSMutableDictionary dictionary];
    }
    return _actionBlockForButtonIndex;
}
- (NSMutableDictionary *)buttonTitleAttributes {
    if (!_buttonTitleAttributes) {
        _buttonTitleAttributes = [@{@(UIControlStateNormal): @{}, @(UIControlStateHighlighted): @{}, @(UIControlStateDisabled): @{}, @(UIControlStateSelected): @{}, @(UIControlStateApplication): @{}, @(UIControlStateReserved): @{}} mutableCopy];
    }
    return _buttonTitleAttributes;
}

- (NSInteger)numberOfButtons {
    return [self.buttons count] + 1; //Add cancel button to the count.
}

- (NSArray *)separators {
    NSInteger buttonCount = self.buttons.count;
    NSMutableArray *mutableSeparators = [NSMutableArray arrayWithCapacity:buttonCount];
    
    // CGFloat contentOffset = kButtonHeight - kSeparatorWidth;
    //change
    
     CGFloat contentOffset = 0.f;
    if (self.titleButton) {
        contentOffset = kTitleButtonHeight - kSeparatorWidth;
    } else {
        contentOffset = kButtonHeight - kSeparatorWidth;
    }
    
    for (int i = 0; i < buttonCount; i++) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, contentOffset, self.frame.size.width, kSeparatorWidth)];
        separator.backgroundColor = self.separatorColor;
        contentOffset += kButtonHeight;
        [mutableSeparators addObject:separator];
    }
    
    return [mutableSeparators copy];
}

- (CGSize)screenSize {
    return [[UIScreen mainScreen] bounds].size;
}

- (UIColor *)separatorColor {
    if (!_separatorColor) {
        return [UIColor clearColor];
    }
    return _separatorColor;
}

- (BOOL)isVisible {
    return [self window] ? YES : NO;
}

- (NSMutableArray *)buttonTitles {
    if (!_buttonTitles) {
        _buttonTitles = [NSMutableArray array];
    }
    return _buttonTitles;
}

- (NSMutableArray *)buttons {
    if (!_buttons) {
        _buttons = [NSMutableArray array];
    }
    return _buttons;
}

@end