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

typedef NS_ENUM(NSUInteger, CHAddStatus) {
    CHAddStatusOK,
    CHAddStatusRetry,
    CHAddStatusError,
};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UIView *moreView;
@property (nonatomic) BOOL autoRuned;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property (nonatomic) NSMutableArray *noEmptyColors;
@property (nonatomic) BOOL firstTimeDone;
@property (nonatomic) NSArray *saveColors;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.moreView.hidden = YES;
    self.autoRuned = NO;
    self.noEmptyColors = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:[self.class noEmptyColorFilePath]] ?: @[]];
    self.saveColors = [NSArray arrayWithContentsOfFile:[self.class saveColorFilePath]] ?: @[];
    if (self.saveColors.count == 0) {
        self.saveColors = @[@"【侠菩提】霹雳衍生十佛周边手链手钏/星沙石手钏/汉服古装配饰",
                            @"【汉服二手】褙子、上襦、半臂等",
                            @"水墨复古线装本仿古速写笔手工本 中国风日记本古风本 礼品",
                            @"福字锁牌古风璎珞项圈 古风汉服配饰 古装COS 创意手工礼品",
                            @"{蝶恋花}璎珞项圈 古风汉服配饰 古装COS 创意手工礼品",
                            @"{寒烟翠}璎珞项圈 古风汉服配饰 古装COS饰品 创意手工礼品",
                            @"青花复古线装本 仿古速写笔 日记本古风本创意文具礼品",
                            @"{水云间}璎珞项圈 古风汉服配饰 古装COS 创意手工礼品",
                            @"青花陶瓷项链古风饰品 /民族风古风毛衣链/创意精美礼品",
                            @"古风饰品龙凤玉佩对佩岫玉汉白玉 汉服配饰 挂件情侣配件",
                            @"古风饰品龙凤玉佩对佩岫玉汉白玉"];
        [self.saveColors writeToFile:[self.class saveColorFilePath] atomically:YES];
    }
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
    self.saveColors = [NSArray arrayWithContentsOfFile:[self.class saveColorFilePath]] ?: @[];
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
    [self addNeedStop:NO];
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
    
    CHAddStatus status = [self addNeedStop:YES];
    if (status == CHAddStatusOK) {
        if ([self.webview nextEnable]) {
            [self.webview next];
        } else if ([self.webview morePageEnable]) {
            NSInteger count = [self.webview listsCount];
            if (count == 1) {
                [self allDone];
            }
            [self.webview morePage];
        } else if (![self.webview isBefore3Months]) {
            [self.webview before3Months];
        } else {
            [self allDone];
        }
        [self retry];
        return;
    } else {
        [self log:@"Retry page %@", @(cur)];
        if ([self.webview nextEnable]) {
            [self.webview next];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.webview prev];
                [self retry];
            });
        } else if ([self.webview prevEnable]) {
            [self.webview prev];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.webview next];
                [self retry];
            });
        } else if ([self.webview isBefore3Months]) {
            [self.webview before3Months];
            [self retry];
        } else {
            [self.webview latest3Months];
            [self retry];
        }
    }
}

- (void)allDone
{
    [self.noEmptyColors writeToFile:[self.class noEmptyColorFilePath] atomically:YES];
    if (!self.firstTimeDone) {
        self.firstTimeDone = YES;
        [self.webview latest3Months];
        [self retry];
        return;
    }
    [self log:@"All done!!"];
    self.autoRuned = NO;
}

- (void)retry
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self autoRunStep];
    });
}

- (CHAddStatus)addNeedStop:(BOOL)needStop {
    NSInteger count = [self.webview listsCount];
    NSInteger failedCount = 0;
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
                failedCount++;
                if (needStop) {
                    if (itemNo.length != 0 &&
                        itemTime.length != 0 &&
                        itemName.length == 0 &&
                        itemPrice.length == 0 &&
                        itemCount.length == 0) {
                        return CHAddStatusRetry;
                    }
                    [self log:@"Unkown Error! No.:%@, Time:%@, Status:%@, Name:%@, Price:%@, Count:%@", itemNo, itemTime, itemStatus, itemName, itemPrice, itemCount];
                    return CHAddStatusError;
                }
                break;
            }
            if (itemColor.length != 0) {
                if (![self.noEmptyColors containsObject:itemName]) {
                    [self.noEmptyColors addObject:itemName];
                }
            } else if (self.autoRuned) {
                if (!self.firstTimeDone) {
                    continue;
                } else if ([self.noEmptyColors containsObject:itemName] && ![self.saveColors containsObject:itemName]) {
                    return CHAddStatusRetry;
                }
            } else {
                if ([self.noEmptyColors containsObject:itemName] && ![self.saveColors containsObject:itemName]) {
                    [self alertWithTitle:@"New color has empty, please check!"];
                    return CHAddStatusOK;
                }
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
    
    if (failedCount == 0) {
        [self toastWithTitle:@"All done! Next!"];
        NSInteger cur = [self.webview currentPage];
        BOOL isBefore = [self.webview isBefore3Months];
        [self log:@"%@ Page %@ done!", isBefore ? @"Before" : @"Recent", @(cur)];
    } else {
        NSString *title = [NSString stringWithFormat:@"%@ items failed. Reflesh and Retry.", @(failedCount)];
        [self alertWithTitle:title];
    }
    
    return CHAddStatusOK;
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

