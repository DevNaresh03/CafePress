import { Component } from '@angular/core';
import { IonicPage, NavController, NavParams, Platform } from 'ionic-angular';
import { CallNumber } from '@ionic-native/call-number';
import { BrowseProvider } from '../../providers/browse/browse';
import { Sim } from '@ionic-native/sim';

/**
 * Generated class for the MysettingsPage page.
 *
 * See https://ionicframework.com/docs/components/#navigation for more info on
 * Ionic pages and navigation.
 */

@IonicPage()
@Component({
  selector: 'page-mysettings',
  templateUrl: 'mysettings.html',
})
export class MysettingsPage {
  urlLink: any;
  public app_version: string = "";
  simPresent: boolean = false;


  constructor(public navCtrl: NavController, public platform: Platform, public navParams: NavParams, private callNumber: CallNumber,
    public sim: Sim, private browser: BrowseProvider) {
    this.urlLink = this.browser.baseUrl;
    this.app_version = this.browser.app_version;
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad MysettingsPage');
  }

  ionViewWillEnter() {
    //window.close();
  }

  goSet() {
    this.navCtrl.push('HomePage');
  }


  openOtherLinks() {
    if (this.platform.is('ios'))
      window.open("itms-apps://itunes.apple.com/app/1467249487", "_system");
    else
      window.open("https://play.google.com/store/apps/details?id=com.cafepress.mobile.android", "_system");
  }

  launchDialer(n: string) {
    this.sim.getSimInfo().then(info => {
      console.log('NETWORK INFO: ' + info.networkType);
      console.log('Sim info: ', JSON.stringify(info));

      if (this.platform.is('ios') && info.carrierName != "") {
        this.placeACallWithDialer(n);
      } 
      else if (this.platform.is('android') && info.networkType != 0) {
        this.placeACallWithDialer(n);
      }
    });
  }

  placeACallWithDialer(n: string) {
    this.callNumber.callNumber(n, true)
      .then(() => console.log('Launched dialer!'))
      .catch(() => console.log('Error launching dialer'));
  }

  mailto(email: string) {
    window.open(`mailto:${email}`, '_system');
  }
}