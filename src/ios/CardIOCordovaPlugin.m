//
//  CardIOCordovaPlugin.m
//
//  Copyright 2013 PayPal Inc.
//  MIT licensed
//

#import "CardIOCordovaPlugin.h"

#pragma mark -

@interface CardIOCordovaPlugin ()

@property (nonatomic, copy, readwrite) NSString *scanCallbackId;

- (void)sendSuccessTo:(NSString *)callbackId withObject:(id)objwithObject;
- (void)sendFailureTo:(NSString *)callbackId;

@end

#pragma mark -

@implementation CardIOCordovaPlugin


- (void)execute:(CDVInvokedUrlCommand *)command {
    [self scan:command];
}

- (void)scan:(CDVInvokedUrlCommand *)command {
    self.scanCallbackId = command.callbackId;
    NSDictionary* options = [command.arguments objectAtIndex:0];

    CardIOPaymentViewController *paymentViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];

    NSNumber *collectCVV = [options objectForKey:@"cvv"];
    if(collectCVV) {
        paymentViewController.collectCVV = [collectCVV boolValue];
    }

    NSNumber *collectZip = [options objectForKey:@"zip"];
    if(collectZip) {
        paymentViewController.collectPostalCode = [collectZip boolValue];
    }

    NSNumber *collectExpiry = [options objectForKey:@"expiry"];
    if(collectExpiry) {
        paymentViewController.collectExpiry = [collectExpiry boolValue];
    }

    NSNumber *disableManualEntryButtons = [options objectForKey:@"supressManual"];
    if(disableManualEntryButtons) {
        paymentViewController.disableManualEntryButtons = [disableManualEntryButtons boolValue];
    }

    // if it is nil, its ok.
    NSString *languageOrLocale = [[[NSLocale alloc] initWithLocaleIdentifier:[options objectForKey:@"languageOrLocale"]] localeIdentifier];
    if (languageOrLocale) {
        paymentViewController.languageOrLocale = languageOrLocale;
    }

    [self.viewController presentViewController:paymentViewController animated:YES completion:nil];

}

- (void)canScan:(CDVInvokedUrlCommand *)command {
    BOOL canScan = [CardIOUtilities canReadCardWithCamera];
    [self sendSuccessTo:command.callbackId withObject:[NSNumber numberWithBool:canScan]];
}

- (void)version:(CDVInvokedUrlCommand *)command {
    NSString *version = [CardIOUtilities libraryVersion];

    if(version) {
        [self sendSuccessTo:command.callbackId withObject:version];
    } else {
        [self sendFailureTo:command.callbackId];
    }
}


#pragma mark - CardIOPaymentViewControllerDelegate methods

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)pvc {

    [pvc dismissViewControllerAnimated:YES completion:^{
      // Convert CardIOCreditCardInfo into dictionary for passing back to javascript
      NSMutableDictionary *response = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       info.cardNumber, @"card_number",
                                       info.redactedCardNumber, @"redacted_card_number",
                                       [CardIOCreditCardInfo displayStringForCardType:info.cardType
                                                                usingLanguageOrLocale:pvc.languageOrLocale],
                                       @"card_type",
                                       nil];
      if(info.expiryMonth > 0 && info.expiryYear > 0) {
        [response setObject:[NSNumber numberWithUnsignedInteger:info.expiryMonth] forKey:@"expiry_month"];
        [response setObject:[NSNumber numberWithUnsignedInteger:info.expiryYear] forKey:@"expiry_year"];
      }
      if(info.cvv.length > 0) {
        [response setObject:info.cvv forKey:@"cvv"];
      }
      if(info.postalCode.length > 0) {
        [response setObject:info.postalCode forKey:@"zip"];
      }

      [self sendSuccessTo:self.scanCallbackId withObject:response];
    }];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)pvc {

    [pvc dismissViewControllerAnimated:YES completion:^{
      [self sendFailureTo:self.scanCallbackId];
    }];
}

#pragma mark - Cordova callback helpers

- (void)sendSuccessTo:(NSString *)callbackId withObject:(id)obj {
    CDVPluginResult *result = nil;

    if([obj isKindOfClass:[NSString class]]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:obj];
    } else if([obj isKindOfClass:[NSDictionary class]]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:obj];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        // all the numbers we return are bools
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[obj intValue]];
    } else if(!obj) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        NSLog(@"Success callback wrapper not yet implemented for class %@", [obj class]);
    }

    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)sendFailureTo:(NSString *)callbackId {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

@end
