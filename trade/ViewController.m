//
//  ViewController.m
//  trade
//
//  Created by Jiang on 16/6/28.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (nonatomic) NSMutableString *log;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.log = [NSMutableString stringWithString:@""];
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.taobao.com"]]];
}

- (IBAction)go:(id)sender {
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://trade.taobao.com/trade/itemlist/list_sold_items.htm"]]];
}

- (IBAction)add:(id)sender {
    NSString *count = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('item-mod__trade-order___2LnGB').length"];
    for (NSInteger i = 0; i != count.integerValue; i++) {
        NSString *itemjs = [NSString stringWithFormat:@"document.getElementsByClassName('item-mod__trade-order___2LnGB')[%@]", @(i)];
        
        NSString *itemKeysjs = [itemjs stringByAppendingString:@".getElementsByClassName('item-mod__checkbox-label___cRGUj')[0]"];
        NSString *itemNojs = [itemKeysjs stringByAppendingString:@".getElementsByTagName('span')[2].innerHTML"];
        NSString *itemTimejs = [itemKeysjs stringByAppendingString:@".getElementsByTagName('span')[5].innerHTML"];
        NSString *itemStatusjs = [itemjs stringByAppendingString:@".getElementsByClassName('text-mod__link___36nmM')[1].innerHTML"];
        NSString *itemNo = [self.webview stringByEvaluatingJavaScriptFromString:itemNojs];
        NSString *itemTime = [self.webview stringByEvaluatingJavaScriptFromString:itemTimejs];
        NSString *itemStatus = [self.webview stringByEvaluatingJavaScriptFromString:itemStatusjs];
        NSLog(@" ");
        NSLog(@"订单号:%@，时间:%@，状态:%@", itemNo, itemTime, itemStatus);
        [self.log appendString:[NSString stringWithFormat:@"\nNo.:%@ Date:%@ Status:%@\n", itemNo, itemTime, itemStatus]];
        
        NSString *itemCountjs = [itemjs stringByAppendingString:@".getElementsByClassName('suborder-mod__item___dY2q5').length"];
        NSString *itemCount = [self.webview stringByEvaluatingJavaScriptFromString:itemCountjs];
        for (NSInteger j = 0; j != itemCount.integerValue; j++) {
            NSString *subItemjs = [NSString stringWithFormat:@"%@.getElementsByClassName('suborder-mod__item___dY2q5')[%@]", itemjs, @(j)];
            NSString *itemNamejs = [subItemjs stringByAppendingString:@".getElementsByTagName('span')[2].innerHTML"];
            NSString *itemPricejs = [subItemjs stringByAppendingString:@".getElementsByTagName('p')[3].innerHTML"];
            NSString *itemCountjs = [subItemjs stringByAppendingString:@".getElementsByTagName('p')[4].innerHTML"];
            NSString *itemColorjs = [subItemjs stringByAppendingString:@".getElementsByTagName('span')[6].getElementsByTagName('span')[2].innerHTML"];
            
            NSString *itemName = [self.webview stringByEvaluatingJavaScriptFromString:itemNamejs];
            NSString *itemPrice = [self.webview stringByEvaluatingJavaScriptFromString:itemPricejs];
            NSString *itemCount = [self.webview stringByEvaluatingJavaScriptFromString:itemCountjs];
            NSString *itemColor = [self.webview stringByEvaluatingJavaScriptFromString:itemColorjs];
            NSLog(@"Name:%@，Price:%@, Count:%@, Color:%@", itemName, itemPrice, itemCount, itemColor);
            [self.log appendString:[NSString stringWithFormat:@"Name:%@，Price:%@, Count:%@, Color:%@\n", itemName, itemPrice, itemCount, itemColor]];
        }
    }
    NSString *title = [NSString stringWithFormat:@"%@ items done.", count];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:NULL];
        });
    }];
    
}

- (IBAction)copy:(id)sender {
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    pboard.string = self.log;
}

@end
