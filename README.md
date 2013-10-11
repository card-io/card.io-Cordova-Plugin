card.io iOS plug-in for Phone Gap
---------------------------------

This plug-in exposes card.io credit card scanning.

Note: If you would like to actually process a credit card charge, you might be interested in the [PayPal iOS SDK PhoneGap Plug-in](https://github.com/paypal/PayPal-iOS-SDK-PhoneGap).


Integration instructions
------------------------

* Add the card.io library:
    * Sign up for an account at https://www.card.io/, create an app, and take note of your `app_token`.
    * Download the [card.io iOS SDK](https://github.com/card-io/card.io-iOS-SDK).
    * Follow the instructions there to add the requisite files, frameworks, and linker flags to your Xcode project.

* Add this plug-in:
    * Add `CardIOPGPlugin.[h|m]` to your project (Plugins group).
    * Copy `CardIOPGPlugin.js` to your project's `www` folder. (If you don't have a `www` folder yet, run in the Simulator and follow the instructions in the build warnings.)
    * Add e.g. `<script type="text/javascript" src="CardIOPGPlugin.js"></script>` to your html.
    * See `CardIOPGPlugin.js` for detailed usage information.
    * Add the following to `config.xml`, for PhoneGap version 3.0+:

         ```xml
        <feature name="CardIOPGPlugin">
          <param name="ios-package" value="CardIOPGPlugin" />
        </feature>
       ```
    
      for older versions under the `plugins` tag:
       
       ```xml
       <plugin name="CardIOPGPlugin" value="CardIOPGPlugin" />
       ``` 

    * Sample `canScan` usage:

      ```javascript
      window.plugins.card_io.canScan(function(canScan) {console.log("card.io can scan: " + canScan);});
      ```

    * Sample `scan` usage:

      ```javascript
      window.plugins.card_io.scan("YOUR_APP_TOKEN", {}, function(response) {
        console.log("card number: " + response["card_number"]);
        }, function() {
          console.log("card scan cancelled");
      });
      ```

### Sample HTML + JS

```html
<h1>Scan Example</h1>
<p><button id='scanBtn'>Scan now</button></p>
<script type="text/javascript">

  function onDeviceReady() {

    var cardIOResponseFields = [
      "card_type",
      "redacted_card_number",
      "card_number",
      "expiry_month",
      "expiry_year",
      "cvv",
      "zip"
    ];

    var onCardIOComplete = function(response) {
      console.log("card.io scan complete");
      for (var i = 0, len = cardIOResponseFields.length; i < len; i++) {
        var field = cardIOResponseFields[i];
        console.log(field + ": " + response[field]);
      }
    };

    var onCardIOCancel = function() {
      console.log("card.io scan cancelled");
    };

    var onCardIOCheck = function (canScan) {
      console.log("card.io canScan? " + canScan);
      var scanBtn = document.getElementById("scanBtn");
      if (!canScan) {
        scanBtn.innerHTML = "Manual entry";
      }
      scanBtn.onclick = function (e) {
        window.plugins.card_io.scan(
          "YOUR_APP_TOKEN_HERE",
          {
            "collect_expiry": true,
            "collect_cvv": false,
            "collect_zip": false,
            "shows_first_use_alert": true,
            "disable_manual_entry_buttons": false
          },
          onCardIOComplete,
          onCardIOCancel
        );
      }
    };

    window.plugins.card_io.canScan(onCardIOCheck);
  }
</script>
```

License
-------
* This plugin is released under the MIT license: http://www.opensource.org/licenses/MIT

Notes
-----
* card.io supports iOS 5.0+.
* Having trouble getting started? Check out the [Phone Gap plugin getting started guide](http://docs.phonegap.com/en/2.7.0/guide_getting-started_ios_index.md.html#Getting%20Started%20with%20iOS).
