//
//  CardIOPGPlugin.h
//
//  Copyright 2013 PayPal Inc.
//  MIT licensed
//

#import <Cordova/CDV.h>
#import "CardIO.h"


@interface CardIOPGPlugin : CDVPlugin<CardIOPaymentViewControllerDelegate>

- (void)scan:(NSMutableArray *)args withDict:(NSMutableDictionary *)options;
- (void)canScan:(NSMutableArray *)args withDict:(NSMutableDictionary *)options;
- (void)version:(NSMutableArray *)args withDict:(NSMutableDictionary *)options;

@end
