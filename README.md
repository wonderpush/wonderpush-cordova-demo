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
#### 4) Launch your application
```
cordova run --device
```
