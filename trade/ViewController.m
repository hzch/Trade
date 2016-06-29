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

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [CHDBManager sharedInstance];
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.taobao.com"]]];
}

- (IBAction)go:(id)sender {
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://trade.taobao.com/trade/itemlist/list_sold_items.htm"]]];
}

- (IBAction)add:(id)sender {
    NSString *count = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('item-mod__trade-order___2LnGB').length"];
    NSInteger failedCount = 0;
    for (NSInteger i = 0; i != count.integerValue; i++) {
        NSString *itemjs = [NSString stringWithFormat:@"document.getElementsByClassName('item-mod__trade-order___2LnGB')[%@]", @(i)];
        
        NSString *itemKeysjs = [itemjs stringByAppendingString:@".getElementsByClassName('item-mod__checkbox-label___cRGUj')[0]"];
        NSString *itemNojs = [itemKeysjs stringByAppendingString:@".getElementsByTagName('span')[2].innerHTML"];
        NSString *itemTimejs = [itemKeysjs stringByAppendingString:@".getElementsByTagName('span')[5].innerHTML"];
        NSString *refundsjs = [itemjs stringByAppendingString:@".getElementsByClassName('text-mod__link___36nmM')[0].innerHTML"];
        NSString *refunds = [self.webview stringByEvaluatingJavaScriptFromString:refundsjs];
        NSString *itemStatusjs;
        if (refunds.length == 0) {
            itemStatusjs = [itemjs stringByAppendingString:@".getElementsByClassName('text-mod__link___36nmM')[1].innerHTML"];
        } else {
            itemStatusjs = [itemjs stringByAppendingString:@".getElementsByClassName('text-mod__link___36nmM')[2].innerHTML"];
        }
        NSString *itemNo = [self.webview stringByEvaluatingJavaScriptFromString:itemNojs];
        NSString *itemTime = [self.webview stringByEvaluatingJavaScriptFromString:itemTimejs];
        NSString *itemStatus = [self.webview stringByEvaluatingJavaScriptFromString:itemStatusjs];
        NSLog(@" ");
        NSLog(@"订单号:%@，时间:%@，状态:%@", itemNo, itemTime, itemStatus);
        
        NSString *itemCountjs = [itemjs stringByAppendingString:@".getElementsByClassName('suborder-mod__item___dY2q5').length"];
        NSString *itemCount = [self.webview stringByEvaluatingJavaScriptFromString:itemCountjs];
        for (NSInteger j = 0; j != itemCount.integerValue; j++) {
            NSString *subItemjs = [NSString stringWithFormat:@"%@.getElementsByClassName('suborder-mod__item___dY2q5')[%@]", itemjs, @(j)];
            
            NSString *itemRefundsjs = [itemjs stringByAppendingString:@".getElementsByClassName('text-mod__link___36nmM')[0].innerHTML"];
            NSString *itemNamejs = [subItemjs stringByAppendingString:@".getElementsByTagName('span')[2].innerHTML"];
            NSString *itemPricejs = [subItemjs stringByAppendingString:@".getElementsByTagName('td')[1].getElementsByTagName('p')[0].innerHTML"];
            NSString *itemCountjs = [subItemjs stringByAppendingString:@".getElementsByTagName('td')[2].getElementsByTagName('p')[0].innerHTML"];
            NSString *itemColorjs = [subItemjs stringByAppendingString:@".getElementsByTagName('span')[6].getElementsByTagName('span')[2].innerHTML"];
            
            NSString *itemRefunds = [self.webview stringByEvaluatingJavaScriptFromString:itemRefundsjs];
            NSString *itemName = [self.webview stringByEvaluatingJavaScriptFromString:itemNamejs];
            NSString *itemPrice = [self.webview stringByEvaluatingJavaScriptFromString:itemPricejs];
            NSString *itemCount = [self.webview stringByEvaluatingJavaScriptFromString:itemCountjs];
            NSString *itemColor = [self.webview stringByEvaluatingJavaScriptFromString:itemColorjs];
            NSLog(@"Name:%@，Price:%@, Count:%@, Color:%@", itemName, itemPrice, itemCount, itemColor);
            
            if (itemNo.length == 0 ||
                itemTime.length == 0 ||
                itemStatus.length == 0 ||
                itemName.length == 0 ||
                itemPrice.length == 0 ||
                itemCount.length == 0) {
                failedCount++;
                break;
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
    failedCount = 1;
    if (failedCount == 0) {
        [self toastWithTitle:@"All done! Next!"];
    } else {
        NSString *title = [NSString stringWithFormat:@"%@ items failed. Reflesh and Retry.", @(failedCount)];
        [self alertWithTitle:title];
    }
}

- (IBAction)next:(id)sender {
    [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('pagination-next')[0].click()"];
}

- (IBAction)fresh:(id)sender {
    [self.webview reload];
}
- (IBAction)foot:(id)sender {
    [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('pagination-next')[0].scrollIntoView()"];
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

- (void)toastWithTitle:(NSString*)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:NULL];
        });
    }];
}

- (void)alertWithTitle:(NSString*)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:NULL];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:NULL];
}

@end
