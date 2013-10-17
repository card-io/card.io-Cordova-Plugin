//
//  CardIOPGPlugin.m
//
//  Copyright 2013 PayPal Inc.
//  MIT licensed
//

#import "CardIOPGPlugin.h"

#pragma mark -

@interface CardIOPGPlugin ()

  @property (nonatomic, strong, readwrite) CardIOPaymentViewController *paymentViewController;
  @property (nonatomic, copy, readwrite) NSString *scanCallbackId;

- (void)sendSuccessTo:(NSString *)callbackId withObject:(id)objwithObject;
- (void)sendFailureTo:(NSString *)callbackId;

@end

#pragma mark -

@implementation CardIOPGPlugin


- (void)scan:(CDVInvokedUrlCommand *)command {
  self.scanCallbackId = command.callbackId;
  NSString *appToken = [command.arguments objectAtIndex:0];
  NSDictionary* options = [command.arguments objectAtIndex:1];
  
  self.paymentViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
  self.paymentViewController.appToken = appToken;

  NSNumber *collectCVV = [options objectForKey:@"collect_cvv"];
  if(collectCVV) {
    self.paymentViewController.collectCVV = [collectCVV boolValue];
  }

  NSNumber *collectZip = [options objectForKey:@"collect_zip"];
  if(collectZip) {
    self.paymentViewController.collectPostalCode = [collectZip boolValue];
  }

  NSNumber *collectExpiry = [options objectForKey:@"collect_expiry"];
  if(collectExpiry) {
    self.paymentViewController.collectExpiry = [collectExpiry boolValue];
  }

  NSNumber *disableManualEntryButtons = [options objectForKey:@"disable_manual_entry_buttons"];
  if(disableManualEntryButtons) {
    self.paymentViewController.disableManualEntryButtons = [disableManualEntryButtons boolValue];
  }

  // if it is nil, its ok.
  NSString *languageOrLocale = [[[NSLocale alloc] initWithLocaleIdentifier:[options objectForKey:@"languageOrLocale"]] localeIdentifier];
  if (languageOrLocale) {
    self.paymentViewController.languageOrLocale = languageOrLocale;
  }

  [self.viewController presentModalViewController:self.paymentViewController animated:YES];
}

- (void)canScan:(CDVInvokedUrlCommand *)command {
  BOOL canScan = [CardIOPaymentViewController canReadCardWithCamera];
  [self sendSuccessTo:command.callbackId withObject:[NSNumber numberWithBool:canScan]];
}

- (void)version:(CDVInvokedUrlCommand *)command {
  NSString *version = [CardIOPaymentViewController libraryVersion];

  if(version) {
    [self sendSuccessTo:command.callbackId withObject:version];
  } else {
    [self sendFailureTo:command.callbackId];
  }
}


#pragma mark - CardIOPaymentViewControllerDelegate methods

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)pvc {
  if(![pvc isEqual:self.paymentViewController]) {
    NSLog(@"card.io received unexpected callback (expected from %@, received from %@", self.paymentViewController, pvc);
    return;
  }

  [self.paymentViewController dismissModalViewControllerAnimated:YES];

  // Convert CardIOCreditCardInfo into dictionary for passing back to javascript
  NSMutableDictionary *response = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   info.cardNumber, @"card_number",
                                   info.redactedCardNumber, @"redacted_card_number",
                                   [CardIOCreditCardInfo displayStringForCardType:info.cardType
                                                            usingLanguageOrLocale:self.paymentViewController.languageOrLocale],
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
  
  self.paymentViewController.delegate = nil;
  self.paymentViewController = nil;
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)pvc {
  if(![pvc isEqual:self.paymentViewController]) {
    NSLog(@"card.io received unexpected callback (expected from %@, received from %@", self.paymentViewController, pvc);
    return;
  }

  [self.paymentViewController dismissModalViewControllerAnimated:YES];

  [self sendFailureTo:self.scanCallbackId];

  self.paymentViewController.delegate = nil;
  self.paymentViewController = nil;
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
  
  NSString *responseJavascript = [result toSuccessCallbackString:callbackId];
  if(responseJavascript) {
    [self writeJavascript:responseJavascript];
  }
}

- (void)sendFailureTo:(NSString *)callbackId {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  NSString *responseJavascript = [result toErrorCallbackString:callbackId];
  if(responseJavascript) {
    [self writeJavascript:responseJavascript];
  }
}

@end
