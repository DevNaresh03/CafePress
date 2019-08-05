import { NgModule } from '@angular/core';
import { IonicPageModule } from 'ionic-angular';
import { SettingsDetailPage } from './settings-detail';

@NgModule({
  declarations: [
    SettingsDetailPage,
  ],
  imports: [
    IonicPageModule.forChild(SettingsDetailPage),
  ],
})
export class SettingsDetailPageModule {}
