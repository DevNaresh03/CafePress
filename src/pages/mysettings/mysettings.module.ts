import { NgModule } from '@angular/core';
import { IonicPageModule } from 'ionic-angular';
import { MysettingsPage } from './mysettings';

@NgModule({
  declarations: [
    MysettingsPage,
  ],
  imports: [
    IonicPageModule.forChild(MysettingsPage),
  ],
})
export class MysettingsPageModule {}
