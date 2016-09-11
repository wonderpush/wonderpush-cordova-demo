# wonderpush-cordova-demo
Cordova demo application for WonderPush − Notifications &amp; Analytics
(Only android at the moment)

## Getting started
Follow these steps to test this application 
#### 1) Clone this repo
```
git clone https://github.com/wonderpush/wonderpush-cordova-demo
```
Then go to the newly created folder `cd wonderpush-cordova-demo`
#### 2) Add android platform
```
cordova platform add android --save
```
#### 3) Add the wonderpush sdk
```
cordova plugin add --save wonderpush-cordova-sdk --variable CLIENT_ID='id' --variable CLIENT_SECRET='secret'
```
For development 
```
cordova plugin add --save --link path-to-wonderpush-sdk-folder --variable CLIENT_ID='id' --variable CLIENT_SECRET='secret'
```
#### 4) Configure your platforms (TODO: eliminate this step)
##### a) For android: Add gradle config to `platforms/android/build-extras.gradle`.
```
android {
  defaultConfig {
    manifestPlaceholders = [
      wonderpushDefaultActivity:  'com.wonderpush.cordova.demo.MainActivity',
      wonderpushNotificationIcon: '@drawable/icon'
    ]
  }
}
```
#### 5) Launch your application
```
cordova run --device
```
