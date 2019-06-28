cordova.define('cordova/plugin_list', function(require, exports, module) {
  module.exports = [
    {
      "id": "wonderpush-cordova-sdk.WonderPush",
      "file": "plugins/wonderpush-cordova-sdk/www/WonderPush.js",
      "pluginId": "wonderpush-cordova-sdk",
      "clobbers": [
        "cordova.plugins.WonderPush",
        "WonderPush"
      ]
    }
  ];
  module.exports.metadata = {
    "cordova-plugin-whitelist": "1.3.3",
    "wonderpush-cordova-sdk": "2.0.0"
  };
});