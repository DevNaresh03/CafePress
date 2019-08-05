import { Component } from '@angular/core';
import { Platform, AlertController } from 'ionic-angular';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';
import { HomePage } from '../pages/home/home';
import { App } from 'ionic-angular';
import { BrowseProvider } from '../providers/browse/browse';



@Component({
  templateUrl: 'app.html'
})
export class MyApp {
  rootPage: any;
  isDeviceOnLine: boolean = false;
  
  constructor(platform: Platform, statusBar: StatusBar, splashScreen: SplashScreen,
    public app: App, private browser: BrowseProvider,public AlrtCtrl: AlertController) {
    platform.ready().then(() => {
      this.rootPage = HomePage;
      if (platform.is('ios')) {
        statusBar.styleDefault();
      }
      else{
      statusBar.backgroundColorByHexString('#6c738b');
      }
      branchInit();
    });

    platform.resume.subscribe(() => {
      branchInit();
    });

    //BRANCH SDK INITILIZATION
    const branchInit = () => {
      console.log("BRANCH SDK STATUS:" + this.browser.enableBranchSDK);
      if (this.browser.enableBranchSDK) {
        // only on devices
        if (!platform.is("cordova")) {
          return;
        }
        const Branch = window["Branch"];
        Branch.setDebug(true);
        Branch.initSession().then(data => {
          console.log("inner branch init")
          console.log("+clicked_branch_link: " + data["+clicked_branch_link"])
          if (data["+clicked_branch_link"]) {
            console.log("Open app with a Branch deep link: " + JSON.stringify(data));
            console.log("deep link—" + data.$canonical_url);
          }
          else if (data["+non_branch_link"]) {
            console.log("Open app with a non Branch deep link: " + JSON.stringify(data));
          } else {
            console.log("Open app organically");
            // Clicking on app icon or push notification
          }
        });
      }
    }
  };
}