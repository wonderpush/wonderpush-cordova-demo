cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
  {
    "id": "wonderpush-cordova-sdk.WonderPush",
    "file": "plugins/wonderpush-cordova-sdk/www/WonderPush.js",
    "pluginId": "wonderpush-cordova-sdk",
    "clobbers": [
      "cordova.plugins.WonderPush"
    ]
  }
];
module.exports.metadata = 
// TOP OF METADATA
{
  "cordova-plugin-whitelist": "1.3.3",
  "wonderpush-cordova-sdk": "0.1.0"
};
// BOTTOM OF METADATA
});