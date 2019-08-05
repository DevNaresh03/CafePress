import { Component } from '@angular/core';
import { IonicPage, NavController, NavParams } from 'ionic-angular';
import { ThemeableBrowser, ThemeableBrowserOptions, ThemeableBrowserObject } from '@ionic-native/themeable-browser/ngx';

/**
 * Generated class for the SettingsDetailPage page.
 *
 * See https://ionicframework.com/docs/components/#navigation for more info on
 * Ionic pages and navigation.
 */

var browser;

@IonicPage()
@Component({
  selector: 'page-settings-detail',
  templateUrl: 'settings-detail.html',
})

export class SettingsDetailPage {
  url: string;


  options: ThemeableBrowserOptions = {
    title: {
      color: '#003264ff',
      showPageTitle: false
    },
    backButton: {
      image: 'back',
      imagePressed: 'back_pressed',
      align: 'left',
      event: 'backPressed'
    },
    closeButton: {
      image: 'close',
      imagePressed: 'close_pressed',
      align: 'left',
      event: 'closePressed'
    },
    backButtonCanClose: true
  }

  constructor(public navCtrl: NavController, public navParams: NavParams, private themeableBrowser: ThemeableBrowser) {
    this.url = navParams.get('data');
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad SettingsDetailPage');
    this.openUrlInBrowser();
  }

  ionViewWillLeave() {
    this.closrBrowser();
  }

  openUrlInBrowser() {
    browser = this.themeableBrowser.create(this.url, '_blank', this.options);
    browser.addEventListener('backPressed', function(e) {
      this.closrBrowser();
  });
  }

  closrBrowser(){
    if (browser != null)
      browser.close();
  }

}
