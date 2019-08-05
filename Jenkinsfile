pipeline {
   agent any
      environment {
         PATH='/usr/local/bin:/usr/bin:/bin'
      }
   stages {
      stage('NPM Setup') {
      steps {
         sh 'npm install'
      }
   }

   stage('Android Build and export APK') {
   steps {
      //sh 'npm rebuild node-sass'
      sh 'ionic cordova platform rm android'
       sh 'ionic cordova platform add android'
      sh 'ionic cordova build --release android'
   }
  }
// stage('iOS Build and export IPA') {
//       steps {            
//       sh 'ionic cordova build ios --developmentTeam="AN2U6TVXSW" --provisioningProfile="4134a6f1-c23d-4afd-aa7f-cbff6c690099" --codeSignIdentity="iPhone Developer"' 
//       sh 'xcodebuild  -project platforms/ios/MyApp.xcodeproj -scheme MyApp archive -archivePath platforms/ios/MyApp.xcarchive'
//       sh 'xcodebuild -exportArchive  -archivePath platforms/ios/MyApp.xcarchive -exportPath  platforms/ios/archive -exportOptionsPlist platforms/ios/exportOptions.plist' 
//    }      
//    }
//  }
}
