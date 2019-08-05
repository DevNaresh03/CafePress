import { Component, NgZone } from '@angular/core';
import { NavController, ModalController, Platform, ActionSheetController } from 'ionic-angular';
import { InAppBrowser, InAppBrowserOptions } from "@ionic-native/in-app-browser";
import { MysettingsPage } from '../mysettings/mysettings';
import { SplashScreen } from "@ionic-native/splash-screen";
import { Network } from '@ionic-native/network';
import { BrowseProvider } from '../../providers/browse/browse';
import { AppRate } from '@ionic-native/app-rate';
import { Storage } from '@ionic/storage';



var inAppBrowserRef;
@Component({
  selector: 'page-home',
  templateUrl: 'home.html'
})
export class HomePage {
  permissionMsg: any;
  hasPermissions: boolean = false;
  isRateDialogShowed: boolean = true;
  urlLink: any;
  dignostic: any;
  noInternetMessge: string = "";
  lastSelectedTab: string = "Featured";
  lastLoadedUrl: string = "";
  options: InAppBrowserOptions = {
    usewkwebview: 'yes',
    location: 'no',//Or 'no' 
    hidden: 'no', //Or  'yes'
    zoom: 'no',//Android only ,shows browser zoom controls 
    hardwareback: 'yes',
    mediaPlaybackRequiresUserAction: 'no',
    shouldPauseOnSuspend: 'no', //Android only 
    //closebuttoncaption : 'Close', //iOS only
    disallowoverscroll: 'no', //iOS only 
    toolbar: 'yes', //iOS only 
    enableViewportScale: 'no', //iOS only 
    allowInlineMediaPlayback: 'no',//iOS only 
    //presentationstyle: 'pagesheet',//iOS only 
    fullscreen: 'yes',//Windows only    
    footer: "yes",
    closebuttoncaption: this.lastSelectedTab,
  };
  constructor(public navCtrl: NavController, public platform: Platform, private theInAppBrowser: InAppBrowser, public splashScreen: SplashScreen,
    public modalCtrl: ModalController, private network: Network, private browser: BrowseProvider, private appRate: AppRate, private storage: Storage,
    private zone: NgZone, public actionSheetCtrl: ActionSheetController) {

    this.urlLink = this.browser.baseUrl;
    this.options.closebuttoncolor = this.urlLink;
    //PRAPARE THE RATE US DIALOG
    this.platform.ready().then(() => {
      this.peprareRateUsDialog();
    });
  }

  ionViewDidEnter() {
    this.network.onConnect().subscribe(data => {
      console.log("ion view did enter Onconnect--" + data.type);
      this.hideNoInternetView();
      this.loadLastSavedUrl();
    }, error => error => {
      console.error(error)
    });
    this.network.onDisconnect().subscribe(data => {
      console.log("ion view did enter Ondisconnect--" + data.type);
      inAppBrowserRef.close();
      this.saveLastUrl(this.lastLoadedUrl, this.lastSelectedTab);
      this.showNoInternetView();
    }, error => {
      console.error(error)
    });
  }
  ionViewWillEnter() {
    var last = this.navCtrl.last();
    console.log("last pagee --- " + last.name);
    if (last.name === "MysettingsPage") {
      console.log("ion view did enter last page settings page--");
      this.loadLastSavedUrl();
    }
    else {
      console.log("ion view did enter first launch--");
      let status = this.network.type;
      console.log(" ion view will init CONNECTION STATUS :" + status);
      if (status !== "none") {
        console.log("ion view did enter first launch internet connection none--");
        this.hideNoInternetView();
        this.openBrowser(this.urlLink);
      } else {
        this.showNoInternetView();
      }
    }
    console.log("ion view will init");
  }
  ionViewDidLoad() {
    console.log("Home page ion viwe did init");
  }

  openBrowser(url: string) {
    this.splashScreen.hide();
    console.log("IAB ");
    inAppBrowserRef = this.theInAppBrowser.create(url, "_blank", this.options);

    inAppBrowserRef.on("loadstart").subscribe(e => {
      console.log("On loadstart");
      console.log("On loadstart URL:" + e.url);
      console.log("On loadstart lastClickedTab :" + e.lastClickedTab);
      if (this.browser.enableBranchSDK) {
        this.checkForFirstPurchase(e.lastClickedTab, e.url);
      }
      if (e.url == "file://gotosettings.com" || e.url == "file:///gotosettings.com" || e.url == "gotosettings.com") {
        console.log("On loadstart Settings Clicked");
        this.saveLastUrl(this.lastLoadedUrl, e.lastClickedTab);
        this.closeIAB();
      } else {
        this.lastLoadedUrl = e.url;
        this.lastSelectedTab = e.lastClickedTab;
      }
    });
    inAppBrowserRef.on("exit").subscribe(e => {
      this.platform.exitApp();
    });

    inAppBrowserRef.on("loaderror").subscribe(e => {
      console.log("loaderror" + e.url);
    });

    inAppBrowserRef.on("loadstop").subscribe(e => {
      console.log("On loadstop");
      if (this.platform.is('ios')) {
        //cafepress.Personalization.mobileAppIsManagingUploads = true;  method is used to disable click event in the browser
        inAppBrowserRef.executeScript({
          code: "var selectedImgBoxID;cafepress.Personalization.mobileAppIsManagingUploads = true;var uploadButtons = document.getElementsByClassName('uploadBox contain');for(i=0;i<uploadButtons.length;i++){(function(index){uploadButtons[i].onclick = function(){window.location.href='inapp://capture';selectedImgBoxID = uploadButtons[index].id;}})(i);}"
        })
      }
      this.lastSelectedTab = e.lastClickedTab;
      this.lastLoadedUrl = e.url;
      inAppBrowserRef.show();
    });
    inAppBrowserRef.on("customscheme").subscribe(e => {
      console.log("On settingsEvent" + e);
      this.saveLastUrl(e.lastUrl, e.tab);
      this.closeIAB();
    });

    //This is custom callback created in ios CDVWKInAppBrowser.m
    inAppBrowserRef.on("imageUpload").subscribe(e => {
      console.log("On imageUpload ------" + e.imgPath);
        inAppBrowserRef.executeScript({
          code: "cafepress.Personalization.getImageFromMobileApp(selectedImgBoxID, '" + e.imgPath + "', 'data:image/jpeg;base64," + e.imgData + "');"
        })
    });
    if (!this.isRateDialogShowed)
      this.showRateUsDialog();
  }

  showNoInternetView() {
    this.zone.run(() => {
      this.noInternetMessge = "Can't connect.. Please connect to the internet";
    });
  }
  hideNoInternetView() {
    this.zone.run(() => {
      this.noInternetMessge = "";
    });
  }
  closeIAB() {
    inAppBrowserRef.close();
    this.navCtrl.push(MysettingsPage);
  }
  navigateToSocialPages(url: string) {
    window.open(url, "_system");
    this.loadLastSavedUrl();
  }
  showRateUsDialog() {
    this.isRateDialogShowed = true;
    this.appRate.promptForRating(false);
  }
  peprareRateUsDialog() {
    this.appRate.preferences = {
      inAppReview: false,
      displayAppName: "CafePress",
      promptAgainForEachNewVersion: false,
      usesUntilPrompt: 3,
      storeAppURL: {
        ios: '1467249487',
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
  }
  saveLastUrl(lastUrl: string, lastTab: string) {
    console.log("SAVED LAST  URL: " + lastUrl);
    console.log("SAVED LAST  TAB: " + lastTab);
    this.storage.set('LastUrl', lastUrl);
    this.storage.set('LastClickedTab', lastTab);
  }
  loadLastSavedUrl() {
    this.storage.get('LastClickedTab').then((data) => {
      console.log("FETCHED LAST SAVED CLICKED TAB: " + data);
      this.options.closebuttoncaption = data
      this.opentheBrowserWithLastSavedUrl();
    }).catch((errorGet: any) => {
      this.opentheBrowserWithLastSavedUrl();
    });
  }
  opentheBrowserWithLastSavedUrl() {
    this.storage.get('LastUrl').then((val) => {
      console.log("FETCHED LAST SAVED URL: " + val);
      this.openBrowser(val);
    })
  }
  checkForFirstPurchase(tabName: string, url: string) {
    this.storage.get('FirstPurchase').then((val) => {
      console.log("FirstPurchase : " + val);
      if (val === "null") {
        this.trackBranchEvent(tabName, url);
      }
    });
  }
  trackBranchEvent(tabName: string, url: string) {
    const Branch = window["Branch"];
    var eventName = 'First Purchase'
    var metadata = { 'tabName': tabName, 'loadedUrl': url }
    Branch.userCompletedAction(eventName, metadata)
      .then(function (res) {
        this.storage.set('FirstPurchase', "yes");
      })
      .catch(function (err) {
        //alert("Error: " + JSON.stringify(err.message));
      });
  }
  saveCartTime() {
    var nowDate = Date();
    this.storage.set('addToCartTime', nowDate);
    console.log("now date:---" + nowDate);
    if (this.checkDateChange(nowDate)) {
      // true case
    };
  }
  checkDateChange(prevDate) {
    var OneDay = new Date().getTime() + (1 * 24 * 60 * 60 * 1000)
    if (OneDay > prevDate) {
      // The yourDate time is less than 1 days from now
      return true;
    }
    else if (OneDay < prevDate) {
      // The yourDate time is more than 1 days from now
      return false;
    }
  }
}