webpackJsonp([2],{

/***/ 111:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return MysettingsPage; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__angular_core__ = __webpack_require__(0);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1_ionic_angular__ = __webpack_require__(34);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_2__ionic_native_call_number__ = __webpack_require__(155);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_3__providers_browse_browse__ = __webpack_require__(47);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_4__ionic_native_sim__ = __webpack_require__(157);
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};





/**
 * Generated class for the MysettingsPage page.
 *
 * See https://ionicframework.com/docs/components/#navigation for more info on
 * Ionic pages and navigation.
 */
var MysettingsPage = /** @class */ (function () {
    function MysettingsPage(navCtrl, platform, navParams, callNumber, sim, browser) {
        var _this = this;
        this.navCtrl = navCtrl;
        this.platform = platform;
        this.navParams = navParams;
        this.callNumber = callNumber;
        this.sim = sim;
        this.browser = browser;
        this.app_version = "";
        this.simPresent = false;
        this.sim.getSimInfo().then(function (info) {
            console.log('Sim info: ', JSON.stringify(info));
            if (info.carrierName != "") {
                _this.simPresent = true;
            }
        }).catch(function (err) {
            console.log('Unable to get sim info: ', err);
        });
        this.urlLink = this.browser.baseUrl;
        this.app_version = this.browser.app_version;
    }
    MysettingsPage.prototype.ionViewDidLoad = function () {
        console.log('ionViewDidLoad MysettingsPage');
    };
    MysettingsPage.prototype.ionViewWillEnter = function () {
        //window.close();
    };
    MysettingsPage.prototype.goSet = function () {
        this.navCtrl.push('HomePage');
    };
    MysettingsPage.prototype.openOtherLinks = function () {
        if (this.platform.is('ios'))
            window.open("itms-apps://itunes.apple.com/app/1024941703", "_system");
        else
            window.open("https://play.google.com/store/apps/details?id=com.cafepress.mobile.android", "_system");
    };
    MysettingsPage.prototype.launchDialer = function (n) {
        if (this.simPresent) {
            this.callNumber.callNumber(n, true)
                .then(function () { return console.log('Launched dialer!'); })
                .catch(function () { return console.log('Error launching dialer'); });
        }
        else {
            console.log('Call not supported');
        }
    };
    MysettingsPage.prototype.mailto = function (email) {
        window.open("mailto:" + email, '_system');
    };
    MysettingsPage = __decorate([
        Object(__WEBPACK_IMPORTED_MODULE_0__angular_core__["m" /* Component */])({
            selector: 'page-mysettings',template:/*ion-inline-start:"/Users/NareshBojja/Documets/CafePress_Main/cafepress-mobile-app/src/pages/mysettings/mysettings.html"*/'<!--\n  Generated template for the SettingsPage page.\n\n  See http://ionicframework.com/docs/components/#navigation for more info on\n  Ionic pages and navigation.\n-->\n<ion-header>\n  <ion-navbar>\n    <ion-title color="title">Settings </ion-title>\n  </ion-navbar>\n</ion-header>\n\n\n\n<ion-content scroll="true" padding="false">\n\n\n  <!-- <ion-label class="settings_label">About Us</ion-label> -->\n\n  <!-- ABOUT LABEL -->\n  <!-- <ion-item class="ion_item_main_style">\n    <ion-label class="settings_item" (click)="openOutSideWebBrowser(\'/cp/info/about\')">About CafePress</ion-label>\n  </ion-item> -->\n\n  <!-- TERMS AND CONDITIONS  -->\n  <!-- <ion-item class="ion_item_main_style">\n    <ion-label class="settings_item" (click)="openOutSideWebBrowser(\'/p/terms-conditions#privacystatement\')"> Terms &\n      Conditions </ion-label>\n  </ion-item> -->\n\n  <!-- HELP CENTER  -->\n  <!-- <ion-item class="ion_item_main_style"> \n    <ion-label class="settings_item" (click)="openOutSideWebBrowser(\'/p/help-buying\')">Help Center </ion-label>\n  </ion-item> -->\n\n  <!-- RATE US ON THE APP  -->\n  <ion-item class="ion_item_main_style">\n    <ion-label class="settings_item" (click)="openOtherLinks()">Rate Us</ion-label>\n  </ion-item>\n\n\n\n\n  <!-- <ion-label class="settings_label">Legal</ion-label> -->\n\n  <!-- REPORT ALLEGNED LABEL -->\n  <!-- <ion-item class="ion_item_main_style">\n    <ion-label class="settings_item" (click)="openOutSideWebBrowser(\'/p/terms-conditions#infringement\')">\n      Report Alleged Infringements</ion-label>\n  </ion-item> -->\n\n\n  <ion-item no-lines class="ion_item_bottom_style">\n\n    <!-- SEND EMAIL  -->\n    <!-- <div class="div_setting_call">\n          <span class="setting_call">Send us an</span>\n          <span class="setting_call_number" (click)="openOutSideWebBrowser(\'/p/help-contact-us\')">Email</span>\n        </div> -->\n\n    <!-- CALL US AT (877) 809-1659-->\n    <div class="div_setting_call">\n      <span class="setting_call">Call us at</span>\n      <span class="setting_call_number" (click)="launchDialer(\'(877) 809-1659\')">(877) 809-1659</span>\n    </div>\n\n    <!-- Outside the US call (877) 809-1659-->\n    <div class="div_setting_call">\n      <span class="setting_call">Outside the US call</span>\n      <span class="setting_call_number" (click)="launchDialer(\'(919) 323-4480\')">(919) 323-4480</span>\n    </div>\n  </ion-item>\n\n  <ion-label class="version-label">Version-{{app_version}}</ion-label>\n\n</ion-content>'/*ion-inline-end:"/Users/NareshBojja/Documets/CafePress_Main/cafepress-mobile-app/src/pages/mysettings/mysettings.html"*/,
        }),
        __metadata("design:paramtypes", [__WEBPACK_IMPORTED_MODULE_1_ionic_angular__["i" /* NavController */], __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["k" /* Platform */], __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["j" /* NavParams */], __WEBPACK_IMPORTED_MODULE_2__ionic_native_call_number__["a" /* CallNumber */],
            __WEBPACK_IMPORTED_MODULE_4__ionic_native_sim__["a" /* Sim */], __WEBPACK_IMPORTED_MODULE_3__providers_browse_browse__["a" /* BrowseProvider */]])
    ], MysettingsPage);
    return MysettingsPage;
}());

//# sourceMappingURL=mysettings.js.map

/***/ }),

/***/ 114:
/***/ (function(module, exports) {

function webpackEmptyAsyncContext(req) {
	// Here Promise.resolve().then() is used instead of new Promise() to prevent
	// uncatched exception popping up in devtools
	return Promise.resolve().then(function() {
		throw new Error("Cannot find module '" + req + "'.");
	});
}
webpackEmptyAsyncContext.keys = function() { return []; };
webpackEmptyAsyncContext.resolve = webpackEmptyAsyncContext;
module.exports = webpackEmptyAsyncContext;
webpackEmptyAsyncContext.id = 114;

/***/ }),

/***/ 154:
/***/ (function(module, exports, __webpack_require__) {

var map = {
	"../pages/mysettings/mysettings.module": [
		278,
		1
	],
	"../pages/settings-detail/settings-detail.module": [
		279,
		0
	]
};
function webpackAsyncContext(req) {
	var ids = map[req];
	if(!ids)
		return Promise.reject(new Error("Cannot find module '" + req + "'."));
	return __webpack_require__.e(ids[1]).then(function() {
		return __webpack_require__(ids[0]);
	});
};
webpackAsyncContext.keys = function webpackAsyncContextKeys() {
	return Object.keys(map);
};
webpackAsyncContext.id = 154;
module.exports = webpackAsyncContext;

/***/ }),

/***/ 198:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return HomePage; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__angular_core__ = __webpack_require__(0);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1_ionic_angular__ = __webpack_require__(34);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_2__ionic_native_in_app_browser__ = __webpack_require__(199);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_3__mysettings_mysettings__ = __webpack_require__(111);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_4__ionic_native_splash_screen__ = __webpack_require__(102);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_5__ionic_native_network__ = __webpack_require__(200);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_6__providers_browse_browse__ = __webpack_require__(47);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_7__ionic_native_app_rate__ = __webpack_require__(201);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_8__ionic_storage__ = __webpack_require__(202);
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};









var inAppBrowserRef;
var HomePage = /** @class */ (function () {
    function HomePage(navCtrl, platform, theInAppBrowser, splashScreen, modalCtrl, network, browser, appRate, storage, zone, actionSheetCtrl) {
        var _this = this;
        this.navCtrl = navCtrl;
        this.platform = platform;
        this.theInAppBrowser = theInAppBrowser;
        this.splashScreen = splashScreen;
        this.modalCtrl = modalCtrl;
        this.network = network;
        this.browser = browser;
        this.appRate = appRate;
        this.storage = storage;
        this.zone = zone;
        this.actionSheetCtrl = actionSheetCtrl;
        this.hasPermissions = false;
        this.isRateDialogShowed = true;
        this.noInternetMessge = "";
        this.lastSelectedTab = "Featured";
        this.lastLoadedUrl = "";
        this.options = {
            usewkwebview: 'yes',
            location: 'no',
            hidden: 'no',
            zoom: 'no',
            hardwareback: 'yes',
            mediaPlaybackRequiresUserAction: 'no',
            shouldPauseOnSuspend: 'no',
            //closebuttoncaption : 'Close', //iOS only
            disallowoverscroll: 'no',
            toolbar: 'yes',
            enableViewportScale: 'no',
            allowInlineMediaPlayback: 'no',
            //presentationstyle: 'pagesheet',//iOS only 
            fullscreen: 'yes',
            footer: "yes",
            closebuttoncaption: this.lastSelectedTab,
        };
        this.urlLink = this.browser.baseUrl;
        this.options.closebuttoncolor = this.urlLink;
        //PRAPARE THE RATE US DIALOG
        this.platform.ready().then(function () {
            _this.peprareRateUsDialog();
        });
    }
    HomePage.prototype.ionViewDidEnter = function () {
        var _this = this;
        this.network.onConnect().subscribe(function (data) {
            console.log("ion view did enter Onconnect--" + data.type);
            _this.hideNoInternetView();
            _this.loadLastSavedUrl();
        }, function (error) { return function (error) {
            console.error(error);
        }; });
        this.network.onDisconnect().subscribe(function (data) {
            console.log("ion view did enter Ondisconnect--" + data.type);
            inAppBrowserRef.close();
            _this.saveLastUrl(_this.lastLoadedUrl, _this.lastSelectedTab);
            _this.showNoInternetView();
        }, function (error) {
            console.error(error);
        });
    };
    HomePage.prototype.ionViewWillEnter = function () {
        var last = this.navCtrl.last();
        console.log("last pagee --- " + last.name);
        if (last.name === "MysettingsPage") {
            console.log("ion view did enter last page settings page--");
            this.loadLastSavedUrl();
        }
        else {
            console.log("ion view did enter first launch--");
            var status_1 = this.network.type;
            console.log(" ion view will init CONNECTION STATUS :" + status_1);
            if (status_1 !== "none") {
                console.log("ion view did enter first launch internet connection none--");
                this.hideNoInternetView();
                this.openBrowser(this.urlLink);
            }
            else {
                this.showNoInternetView();
            }
        }
        console.log("ion view will init");
    };
    HomePage.prototype.ionViewDidLoad = function () {
        console.log("Home page ion viwe did init");
    };
    HomePage.prototype.openBrowser = function (url) {
        var _this = this;
        this.splashScreen.hide();
        console.log("IAB ");
        inAppBrowserRef = this.theInAppBrowser.create(url, "_blank", this.options);
        inAppBrowserRef.on("loadstart").subscribe(function (e) {
            console.log("On loadstart");
            console.log("On loadstart URL:" + e.url);
            console.log("On loadstart lastClickedTab :" + e.lastClickedTab);
            if (_this.browser.enableBranchSDK) {
                _this.checkForFirstPurchase(e.lastClickedTab, e.url);
            }
            if (e.url == "file://gotosettings.com" || e.url == "file:///gotosettings.com" || e.url == "gotosettings.com") {
                console.log("On loadstart Settings Clicked");
                _this.saveLastUrl(_this.lastLoadedUrl, e.lastClickedTab);
                _this.closeIAB();
            }
            else {
                _this.lastLoadedUrl = e.url;
                _this.lastSelectedTab = e.lastClickedTab;
            }
        });
        inAppBrowserRef.on("exit").subscribe(function (e) {
            _this.platform.exitApp();
        });
        inAppBrowserRef.on("loaderror").subscribe(function (e) {
            console.log("loaderror" + e.url);
        });
        inAppBrowserRef.on("loadstop").subscribe(function (e) {
            console.log("On loadstop");
            if (_this.platform.is('ios')) {
                //cafepress.Personalization.mobileAppIsManagingUploads = true;  method is used to disable click event in the browser
                inAppBrowserRef.executeScript({
                    code: "var selectedImgBoxID;cafepress.Personalization.mobileAppIsManagingUploads = true;var uploadButtons = document.getElementsByClassName('uploadBox contain');for(i=0;i<uploadButtons.length;i++){(function(index){uploadButtons[i].onclick = function(){window.location.href='inapp://capture';selectedImgBoxID = uploadButtons[index].id;}})(i);}"
                });
            }
            _this.lastSelectedTab = e.lastClickedTab;
            _this.lastLoadedUrl = e.url;
            inAppBrowserRef.show();
        });
        inAppBrowserRef.on("customscheme").subscribe(function (e) {
            console.log("On settingsEvent" + e);
            _this.saveLastUrl(e.lastUrl, e.tab);
            _this.closeIAB();
        });
        //This is custom callback created in ios CDVWKInAppBrowser.m
        inAppBrowserRef.on("imageUpload").subscribe(function (e) {
            console.log("On imageUpload ------" + e.imgPath);
            inAppBrowserRef.executeScript({
                code: "cafepress.Personalization.getImageFromMobileApp(selectedImgBoxID, '" + e.imgPath + "', 'data:image/jpeg;base64," + e.imgData + "');"
            });
        });
        if (!this.isRateDialogShowed)
            this.showRateUsDialog();
    };
    HomePage.prototype.showNoInternetView = function () {
        var _this = this;
        this.zone.run(function () {
            _this.noInternetMessge = "Can't connect.. Please connect to the internet";
        });
    };
    HomePage.prototype.hideNoInternetView = function () {
        var _this = this;
        this.zone.run(function () {
            _this.noInternetMessge = "";
        });
    };
    HomePage.prototype.closeIAB = function () {
        inAppBrowserRef.close();
        this.navCtrl.push(__WEBPACK_IMPORTED_MODULE_3__mysettings_mysettings__["a" /* MysettingsPage */]);
    };
    HomePage.prototype.navigateToSocialPages = function (url) {
        window.open(url, "_system");
        this.loadLastSavedUrl();
    };
    HomePage.prototype.showRateUsDialog = function () {
        this.isRateDialogShowed = true;
        this.appRate.promptForRating(false);
    };
    HomePage.prototype.peprareRateUsDialog = function () {
        this.appRate.preferences = {
            inAppReview: false,
            displayAppName: "CafePress",
            promptAgainForEachNewVersion: false,
            usesUntilPrompt: 3,
            storeAppURL: {
                ios: 'AN2U6TVXSW',
                android: 'market://details?id=com.cafepress.mobile.android',
            },
            customLocale: {
                title: "Would you mind rating %@?",
                message: "It won’t take more than a minute and helps to promote our app. Thanks for your support!",
                cancelButtonLabel: "No, Thanks",
                laterButtonLabel: "Remind Me Later",
                rateButtonLabel: "Rate It Now",
                yesButtonLabel: "Yes!",
                noButtonLabel: "Not really",
                appRatePromptTitle: 'Do you like using %@',
                feedbackPromptTitle: 'If you enjoy using %@, would you mind taking a moment to rate it? Thanks so much!',
            },
            callbacks: {
                onRateDialogShow: function (callback) {
                    console.log('rate dialog shown!');
                },
                onButtonClicked: function (buttonIndex) {
                    console.log("onButtonClicked -> " + buttonIndex);
                }
            }
        };
    };
    HomePage.prototype.saveLastUrl = function (lastUrl, lastTab) {
        console.log("SAVED LAST  URL: " + lastUrl);
        console.log("SAVED LAST  TAB: " + lastTab);
        this.storage.set('LastUrl', lastUrl);
        this.storage.set('LastClickedTab', lastTab);
    };
    HomePage.prototype.loadLastSavedUrl = function () {
        var _this = this;
        this.storage.get('LastClickedTab').then(function (data) {
            console.log("FETCHED LAST SAVED CLICKED TAB: " + data);
            _this.options.closebuttoncaption = data;
            _this.opentheBrowserWithLastSavedUrl();
        }).catch(function (errorGet) {
            _this.opentheBrowserWithLastSavedUrl();
        });
    };
    HomePage.prototype.opentheBrowserWithLastSavedUrl = function () {
        var _this = this;
        this.storage.get('LastUrl').then(function (val) {
            console.log("FETCHED LAST SAVED URL: " + val);
            _this.openBrowser(val);
        });
    };
    HomePage.prototype.checkForFirstPurchase = function (tabName, url) {
        var _this = this;
        this.storage.get('FirstPurchase').then(function (val) {
            console.log("FirstPurchase : " + val);
            if (val === "null") {
                _this.trackBranchEvent(tabName, url);
            }
        });
    };
    HomePage.prototype.trackBranchEvent = function (tabName, url) {
        var Branch = window["Branch"];
        var eventName = 'First Purchase';
        var metadata = { 'tabName': tabName, 'loadedUrl': url };
        Branch.userCompletedAction(eventName, metadata)
            .then(function (res) {
            this.storage.set('FirstPurchase', "yes");
        })
            .catch(function (err) {
            //alert("Error: " + JSON.stringify(err.message));
        });
    };
    HomePage.prototype.saveCartTime = function () {
        var nowDate = Date();
        this.storage.set('addToCartTime', nowDate);
        console.log("now date:---" + nowDate);
        if (this.checkDateChange(nowDate)) {
            // true case
        }
        ;
    };
    HomePage.prototype.checkDateChange = function (prevDate) {
        var OneDay = new Date().getTime() + (1 * 24 * 60 * 60 * 1000);
        if (OneDay > prevDate) {
            // The yourDate time is less than 1 days from now
            return true;
        }
        else if (OneDay < prevDate) {
            // The yourDate time is more than 1 days from now
            return false;
        }
    };
    HomePage = __decorate([
        Object(__WEBPACK_IMPORTED_MODULE_0__angular_core__["m" /* Component */])({
            selector: 'page-home',template:/*ion-inline-start:"/Users/NareshBojja/Documets/CafePress_Main/cafepress-mobile-app/src/pages/home/home.html"*/'\n\n<ion-content style="background-color: #fff;" >\n\n  <ion-item  no-lines text-center style="color:#0077b8;text-align: top;padding: 20px"> \n    <!-- <ion-label >Can\'t connect.. Please connect to the internet </ion-label> -->\n    <!-- <h3 style="padding: 20px;color: #0077b8;">Can\'t connect.. Please connect to the internet</h3> -->\n\n    <h3 style="padding: 20px;color: #0077b8;"> {{noInternetMessge}}</h3> \n\n   \n  </ion-item>\n\n    <!-- <div class="imgdiv" *ngIf="loadImage"></div> -->\n    <!-- <div style="margin-top:60%;" text-center>\n  <div class="or-label" >\n    <h3 style="padding: 20px;color: #0077b8;">Can\'t connect.. Please connect to the internet</h3>\n  </div>\n  <! <button ion-button round style=" width: 45%;" (click)="retry();">Retry</button> -->\n  \n  </ion-content>\n  \n  \n  '/*ion-inline-end:"/Users/NareshBojja/Documets/CafePress_Main/cafepress-mobile-app/src/pages/home/home.html"*/
        }),
        __metadata("design:paramtypes", [__WEBPACK_IMPORTED_MODULE_1_ionic_angular__["i" /* NavController */], __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["k" /* Platform */], __WEBPACK_IMPORTED_MODULE_2__ionic_native_in_app_browser__["a" /* InAppBrowser */], __WEBPACK_IMPORTED_MODULE_4__ionic_native_splash_screen__["a" /* SplashScreen */],
            __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["h" /* ModalController */], __WEBPACK_IMPORTED_MODULE_5__ionic_native_network__["a" /* Network */], __WEBPACK_IMPORTED_MODULE_6__providers_browse_browse__["a" /* BrowseProvider */], __WEBPACK_IMPORTED_MODULE_7__ionic_native_app_rate__["a" /* AppRate */], __WEBPACK_IMPORTED_MODULE_8__ionic_storage__["b" /* Storage */],
            __WEBPACK_IMPORTED_MODULE_0__angular_core__["M" /* NgZone */], __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["a" /* ActionSheetController */]])
    ], HomePage);
    return HomePage;
}());

//# sourceMappingURL=home.js.map

/***/ }),

/***/ 229:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
Object.defineProperty(__webpack_exports__, "__esModule", { value: true });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__angular_platform_browser_dynamic__ = __webpack_require__(230);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1__app_module__ = __webpack_require__(234);


Object(__WEBPACK_IMPORTED_MODULE_0__angular_platform_browser_dynamic__["a" /* platformBrowserDynamic */])().bootstrapModule(__WEBPACK_IMPORTED_MODULE_1__app_module__["a" /* AppModule */]);
//# sourceMappingURL=main.js.map

/***/ }),

/***/ 234:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return AppModule; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__angular_platform_browser__ = __webpack_require__(31);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1__angular_core__ = __webpack_require__(0);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_2_ionic_angular__ = __webpack_require__(34);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_3__ionic_native_splash_screen__ = __webpack_require__(102);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_4__ionic_native_status_bar__ = __webpack_require__(197);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_5__app_component__ = __webpack_require__(276);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_6__pages_home_home__ = __webpack_require__(198);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_7__ionic_native_in_app_browser__ = __webpack_require__(199);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_8__pages_mysettings_mysettings__ = __webpack_require__(111);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_9__providers_browse_browse__ = __webpack_require__(47);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_10__ionic_native_call_number__ = __webpack_require__(155);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_11__ionic_native_network__ = __webpack_require__(200);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_12__ionic_native_app_rate__ = __webpack_require__(201);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_13__ionic_storage__ = __webpack_require__(202);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_14__ionic_native_sim__ = __webpack_require__(157);
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};















var AppModule = /** @class */ (function () {
    function AppModule() {
    }
    AppModule = __decorate([
        Object(__WEBPACK_IMPORTED_MODULE_1__angular_core__["I" /* NgModule */])({
            declarations: [
                __WEBPACK_IMPORTED_MODULE_5__app_component__["a" /* MyApp */],
                __WEBPACK_IMPORTED_MODULE_6__pages_home_home__["a" /* HomePage */], __WEBPACK_IMPORTED_MODULE_8__pages_mysettings_mysettings__["a" /* MysettingsPage */],
            ],
            imports: [
                __WEBPACK_IMPORTED_MODULE_0__angular_platform_browser__["a" /* BrowserModule */],
                __WEBPACK_IMPORTED_MODULE_2_ionic_angular__["f" /* IonicModule */].forRoot(__WEBPACK_IMPORTED_MODULE_5__app_component__["a" /* MyApp */], {}, {
                    links: [
                        { loadChildren: '../pages/mysettings/mysettings.module#MysettingsPageModule', name: 'MysettingsPage', segment: 'mysettings', priority: 'low', defaultHistory: [] },
                        { loadChildren: '../pages/settings-detail/settings-detail.module#SettingsDetailPageModule', name: 'SettingsDetailPage', segment: 'settings-detail', priority: 'low', defaultHistory: [] }
                    ]
                }), __WEBPACK_IMPORTED_MODULE_13__ionic_storage__["a" /* IonicStorageModule */].forRoot()
            ],
            bootstrap: [__WEBPACK_IMPORTED_MODULE_2_ionic_angular__["d" /* IonicApp */]],
            entryComponents: [
                __WEBPACK_IMPORTED_MODULE_5__app_component__["a" /* MyApp */],
                __WEBPACK_IMPORTED_MODULE_6__pages_home_home__["a" /* HomePage */], __WEBPACK_IMPORTED_MODULE_8__pages_mysettings_mysettings__["a" /* MysettingsPage */]
            ],
            providers: [
                __WEBPACK_IMPORTED_MODULE_4__ionic_native_status_bar__["a" /* StatusBar */],
                __WEBPACK_IMPORTED_MODULE_3__ionic_native_splash_screen__["a" /* SplashScreen */], __WEBPACK_IMPORTED_MODULE_7__ionic_native_in_app_browser__["a" /* InAppBrowser */], __WEBPACK_IMPORTED_MODULE_10__ionic_native_call_number__["a" /* CallNumber */], __WEBPACK_IMPORTED_MODULE_11__ionic_native_network__["a" /* Network */],
                { provide: __WEBPACK_IMPORTED_MODULE_1__angular_core__["u" /* ErrorHandler */], useClass: __WEBPACK_IMPORTED_MODULE_2_ionic_angular__["e" /* IonicErrorHandler */] }, __WEBPACK_IMPORTED_MODULE_14__ionic_native_sim__["a" /* Sim */],
                __WEBPACK_IMPORTED_MODULE_9__providers_browse_browse__["a" /* BrowseProvider */], __WEBPACK_IMPORTED_MODULE_12__ionic_native_app_rate__["a" /* AppRate */]
            ]
        })
    ], AppModule);
    return AppModule;
}());

//# sourceMappingURL=app.module.js.map

/***/ }),

/***/ 276:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return MyApp; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__angular_core__ = __webpack_require__(0);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_1_ionic_angular__ = __webpack_require__(34);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_2__ionic_native_status_bar__ = __webpack_require__(197);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_3__ionic_native_splash_screen__ = __webpack_require__(102);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_4__pages_home_home__ = __webpack_require__(198);
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_5__providers_browse_browse__ = __webpack_require__(47);
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};







var MyApp = /** @class */ (function () {
    function MyApp(platform, statusBar, splashScreen, app, browser, AlrtCtrl) {
        var _this = this;
        this.app = app;
        this.browser = browser;
        this.AlrtCtrl = AlrtCtrl;
        this.isDeviceOnLine = false;
        platform.ready().then(function () {
            _this.rootPage = __WEBPACK_IMPORTED_MODULE_4__pages_home_home__["a" /* HomePage */];
            statusBar.backgroundColorByHexString('#6c738b');
            branchInit();
        });
        platform.resume.subscribe(function () {
            branchInit();
        });
        //BRANCH SDK INITILIZATION
        var branchInit = function () {
            console.log("BRANCH SDK STATUS:" + _this.browser.enableBranchSDK);
            if (_this.browser.enableBranchSDK) {
                // only on devices
                if (!platform.is("cordova")) {
                    return;
                }
                var Branch = window["Branch"];
                Branch.setDebug(true);
                Branch.initSession().then(function (data) {
                    console.log("inner branch init");
                    console.log("+clicked_branch_link: " + data["+clicked_branch_link"]);
                    if (data["+clicked_branch_link"]) {
                        console.log("Open app with a Branch deep link: " + JSON.stringify(data));
                        console.log("deep link—" + data.$canonical_url);
                    }
                    else if (data["+non_branch_link"]) {
                        console.log("Open app with a non Branch deep link: " + JSON.stringify(data));
                    }
                    else {
                        console.log("Open app organically");
                        // Clicking on app icon or push notification
                    }
                });
            }
        };
    }
    ;
    MyApp = __decorate([
        Object(__WEBPACK_IMPORTED_MODULE_0__angular_core__["m" /* Component */])({template:/*ion-inline-start:"/Users/NareshBojja/Documets/CafePress_Main/cafepress-mobile-app/src/app/app.html"*/'<ion-nav [root]="rootPage"></ion-nav>\n'/*ion-inline-end:"/Users/NareshBojja/Documets/CafePress_Main/cafepress-mobile-app/src/app/app.html"*/
        }),
        __metadata("design:paramtypes", [__WEBPACK_IMPORTED_MODULE_1_ionic_angular__["k" /* Platform */], __WEBPACK_IMPORTED_MODULE_2__ionic_native_status_bar__["a" /* StatusBar */], __WEBPACK_IMPORTED_MODULE_3__ionic_native_splash_screen__["a" /* SplashScreen */],
            __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["c" /* App */], __WEBPACK_IMPORTED_MODULE_5__providers_browse_browse__["a" /* BrowseProvider */], __WEBPACK_IMPORTED_MODULE_1_ionic_angular__["b" /* AlertController */]])
    ], MyApp);
    return MyApp;
}());

//# sourceMappingURL=app.component.js.map

/***/ }),

/***/ 47:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "a", function() { return BrowseProvider; });
/* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__angular_core__ = __webpack_require__(0);
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};

/*
  Generated class for the BrowseProvider provider.

  See https://angular.io/guide/dependency-injection for more info on providers
  and Angular DI.
*/
var BrowseProvider = /** @class */ (function () {
    function BrowseProvider() {
        //baseUrl = "https://qa-mobile.cafepress.com";
        //baseUrl = "https://cafepress.com";
        this.baseUrl = "https://mobile.cafepress.com";
        this.app_version = "1.0.22";
        this.enableBranchSDK = false;
    }
    BrowseProvider = __decorate([
        Object(__WEBPACK_IMPORTED_MODULE_0__angular_core__["A" /* Injectable */])()
    ], BrowseProvider);
    return BrowseProvider;
}());

//# sourceMappingURL=browse.js.map

/***/ })

},[229]);
//# sourceMappingURL=main.js.map