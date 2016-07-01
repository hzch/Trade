//
//  ViewController.m
//  trade
//
//  Created by Jiang on 16/6/28.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "ViewController.h"
#import "CHDBManager.h"
#import "CHTradeItem.h"
#import "UIWebView+CHTrade.h"


@interface NSDate (String)
@end
@implementation NSDate (String)
+ (NSString *)currentString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:[NSDate date]];
}
@end

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UIView *moreView;
@property (nonatomic) BOOL autoRuned;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.moreView.hidden = YES;
    self.autoRuned = NO;
    [CHDBManager sharedInstance];
    
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.taobao.com"]]];
}

+ (NSString *)noEmptyColorFilePath {
    return [[self documentsPath] stringByAppendingPathComponent:@"noEmpty.plist"];
}

+ (NSString *)saveColorFilePath {
    return [[self documentsPath] stringByAppendingPathComponent:@"save.plist"];
}

+ (NSString *)documentsPath {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

#pragma mark - action
- (IBAction)autoRun:(id)sender {
    self.autoRuned = !self.autoRuned;
    if (self.autoRuned) {
        [self autoRunStep];
    }
}

- (IBAction)go:(id)sender {
    [self.webview latest3Months];
}

- (IBAction)prev:(id)sender {
    [self.webview prev];
}

- (IBAction)next:(id)sender {
    [self.webview next];
}

- (IBAction)fresh:(id)sender {
    [self.webview reload];
}

- (IBAction)foot:(id)sender {
    [self.webview foot];
}

- (IBAction)more:(id)sender {
    self.moreView.hidden = !self.moreView.hidden;
}

- (IBAction)add:(id)sender {
    [self add];
}

- (IBAction)save:(id)sender {
    NSError *error = [CHDBManager save];
    if (error == nil) {
        [self toastWithTitle:@"Successed!"];
    } else {
        NSString *title = [NSString stringWithFormat:@"Error:%@", error];
        [self alertWithTitle:title];
    }
}

- (IBAction)clean:(id)sender {
    NSError *error = [CHDBManager clean];
    if (error == nil) {
        [self toastWithTitle:@"Successed!"];
    } else {
        NSString *title = [NSString stringWithFormat:@"Error:%@", error];
        [self alertWithTitle:title];
    }
}

#pragma mark - alert
- (void)toastWithTitle:(NSString*)title
{
    if (self.autoRuned) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:NULL];
        });
    }];
}

- (void)alertWithTitle:(NSString*)title
{
    if (self.autoRuned) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:NULL];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - private
- (void)autoRunStep
{
    if (!self.autoRuned) {
        return;
    }
    
    NSInteger cur = [self.webview currentPage];
    if (cur == 0) {
        [self log:@"Can't find currentPage, refresh with manual."];
        [self retry];
        return;
    }
    
    BOOL success = [self add];
    if (success) {
        if ([self.webview nextEnable]) {
            [self.webview next];
        } else if ([self.webview morePageEnable]) {
            NSInteger count = [self.webview listsCount];
            if (count == 1) {
                [self allDone];
                return;
            }
            [self.webview morePage];
        } else if (![self.webview isBefore3Months]) {
            [self.webview before3Months];
        } else {
            [self allDone];
            return;
        }
        [self retry];
        return;
    }
    self.autoRuned = NO;
}

- (void)allDone
{
    [self log:@"All done!!"];
    self.autoRuned = NO;
}

- (void)retry
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self autoRunStep];
    });
}

- (BOOL)add {
    NSInteger count = [self.webview listsCount];
    for (NSInteger i = 0; i != count; i++) {
        NSString *itemNo = [self.webview itemNoWithIndex:i];
        NSString *itemTime = [self.webview itemTimeWithIndex:i];
        NSString *itemStatus = [self.webview itemStatusWithIndex:i];
        NSLog(@" ");
        NSLog(@"订单号:%@，时间:%@，状态:%@", itemNo, itemTime, itemStatus);
        
        NSInteger itemsCount = [self.webview itemsCountWithIndex:i];
        for (NSInteger j = 0; j != itemsCount; j++) {
            NSString *itemRefunds = [self.webview itemRefundsWithIndex:i jIndex:j];
            NSString *itemName = [self.webview itemNameWithIndex:i jIndex:j];
            NSString *itemPrice = [self.webview itemPriceWithIndex:i jIndex:j];
            NSString *itemCount = [self.webview itemCountWithIndex:i jIndex:j];
            NSString *itemColor = [self.webview itemColorWithIndex:i jIndex:j];
            NSLog(@"Name:%@，Price:%@, Count:%@, Color:%@", itemName, itemPrice, itemCount, itemColor);
            
            if (itemNo.length == 0 ||
                itemTime.length == 0 ||
                itemStatus.length == 0 ||
                itemName.length == 0 ||
                itemPrice.length == 0 ||
                itemCount.length == 0) {
                [self log:@"Unkown Error! No.:%@, Time:%@, Status:%@, Name:%@, Price:%@, Count:%@", itemNo, itemTime, itemStatus, itemName, itemPrice, itemCount];
                [self alertWithTitle:@"Failed. Look log for detail."];
                return NO;
            }
            if (itemColor.length == 0) {
                itemColor = @"无";
            }
            CHTradeItem *item = [[CHTradeItem alloc] init];
            item.number = itemNo;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
            item.date = [dateFormatter dateFromString:itemTime];
            item.dateString = itemTime;
            item.status = itemStatus;
            item.refunds = itemRefunds;
            item.name = itemName;
            item.color = itemColor;
            item.price = @(itemPrice.doubleValue);
            item.count = @(itemCount.integerValue);
            [[CHDBManager sharedInstance] addItem:item];
        }
    }
    
    [self toastWithTitle:@"All done! Next!"];
    NSInteger cur = [self.webview currentPage];
    BOOL isBefore = [self.webview isBefore3Months];
    [self log:@"%@ Page %@ done!", isBefore ? @"Before" : @"Recent", @(cur)];
    return YES;
}

- (void)log:(NSString *)content, ...
{
    va_list vl;
    va_start(vl, content);
    NSString* allContent = [[NSString alloc] initWithFormat:content arguments:vl];
    va_end(vl);
    allContent = [NSString stringWithFormat:@"[%@] %@\n", [NSDate currentString], allContent];
    self.logTextView.text = [allContent stringByAppendingString:self.logTextView.text];
}

#pragma mark - getter && setter
- (void)setAutoRuned:(BOOL)autoRuned
{
    _autoRuned = autoRuned;
    [self log:autoRuned ? @"Auto Run!" : @"Auto Stop!"];
}
@end

