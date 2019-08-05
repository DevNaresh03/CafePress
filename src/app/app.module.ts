import { BrowserModule } from '@angular/platform-browser';
import { ErrorHandler, NgModule } from '@angular/core';
import { IonicApp, IonicErrorHandler, IonicModule } from 'ionic-angular';
import { SplashScreen } from '@ionic-native/splash-screen';
import { StatusBar } from '@ionic-native/status-bar';

import { MyApp } from './app.component';
import { HomePage } from '../pages/home/home';
import { InAppBrowser } from '@ionic-native/in-app-browser';
import { MysettingsPage } from '../pages/mysettings/mysettings';
import { BrowseProvider } from '../providers/browse/browse';
import { CallNumber } from '@ionic-native/call-number';
import { Network } from '@ionic-native/network';
import { AppRate } from '@ionic-native/app-rate';
import { IonicStorageModule } from '@ionic/storage';
import { Sim } from '@ionic-native/sim';

@NgModule({
  declarations: [
    MyApp,
    HomePage,MysettingsPage,
  ],
  imports: [
    BrowserModule,
    IonicModule.forRoot(MyApp),IonicStorageModule.forRoot()
  ],
  bootstrap: [IonicApp],
  entryComponents: [
    MyApp,
    HomePage,MysettingsPage
  ],
  providers: [
    StatusBar,
    SplashScreen, InAppBrowser, CallNumber, Network,
    { provide: ErrorHandler, useClass: IonicErrorHandler },Sim,
    BrowseProvider, AppRate
  ]
})
export class AppModule {}
