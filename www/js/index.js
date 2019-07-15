/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
  // Application Constructor
  // Note that JS console messages are logged before the deviceready event is fired on iOS
  initialize: function() {
    window.onerror = function (msg, url, lineNo, columnNo, error) {
      var string = msg.toLowerCase();
      var substring = "script error";
      var message = [
        'Message: ' + msg,
        'URL: ' + url,
        'Line: ' + lineNo,
        'Column: ' + columnNo,
        'Error object: ' + JSON.stringify(error)
      ].join(' - ');
      console.error(message);
      return false;
    };

    this.bindEvents();
  },
  // Bind Event Listeners
  //
  // Bind any events that are required on startup. Common events are:
  // 'load', 'deviceready', 'offline', and 'online'.
  bindEvents: function() {
    document.addEventListener('deviceready', this.onDeviceReady, false);
      document.addEventListener('wonderpush.notificationOpen', this.onNotificationOpen, false);
      document.addEventListener('wonderpush.registeredCallback', this.onRegisteredCallback, false);
  },
  // deviceready Event Handler
  //
  // The scope of 'this' is the event. In order to call the 'receivedEvent'
  // function, we must explicitly call 'app.receivedEvent(...);'
  onDeviceReady: function() {
    app.receivedEvent('deviceready');

      WonderPush.setDelegate({
                             urlForDeepLink: function(url, cb) {
                                console.warn('[WONDERPUSH CORDOVA APP] urlForDeepLink(', url, ')');
                                cb(url);
                             },
      });
    WonderPush.isSubscribedToNotifications(function(subscribed) {
      document.getElementById('optinSwitch').checked = subscribed;
      document.getElementById('optinSwitch').disabled = false;
    });
    document.getElementById('optinSwitch').addEventListener('click', app.toggleSubscribe);
    document.getElementById('eventList').addEventListener('click', app.trackEventClick);
    document.getElementById('tags').addEventListener('click', app.refreshState);
    document.getElementById('properties').addEventListener('click', app.refreshState);
    app.refreshState();
  },

onNotificationOpen: function(event) {
    console.log('Received notificationOpen', event);
},
    
onRegisteredCallback: function(event) {
    console.log('Received registeredCallback', event);
},
    
  receivedEvent: function(id) {
    console.log('Received Event: ' + id);
  },

  refreshState: function() {
    WonderPush.getTags(function(tags) {
      document.getElementById('tags').innerHTML = tags.join('\n');
    });
    WonderPush.getProperties(function(properties) {
      document.getElementById('properties').innerHTML = JSON.stringify(properties, null, 2);
    });
  },

  toggleSubscribe: function(e) {
    if (e.target.checked) {
      WonderPush.subscribeToNotifications();
    } else {
      WonderPush.unsubscribeFromNotifications();
    }
  },

  trackEventClick: function(e) {
    var target = e.target;
    var type = target.dataset.event;
      var custom = target.dataset.custom;
      try {
          custom = JSON.parse(custom);
      } catch (ex) {
          custom = null;
      }

    if (!type && !custom) {
      return;
    } else if (!type) {
        WonderPush.putProperties(custom, app.refreshState);
    } else {
        WonderPush.trackEvent(type, custom);
    }
  },

};

app.initialize();
