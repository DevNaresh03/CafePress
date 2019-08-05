/*
       Licensed to the Apache Software Foundation (ASF) under one
       or more contributor license agreements.  See the NOTICE file
       distributed with this work for additional information
       regarding copyright ownership.  The ASF licenses this file
       to you under the Apache License, Version 2.0 (the
       "License"); you may not use this file except in compliance
       with the License.  You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing,
       software distributed under the License is distributed on an
       "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
       KIND, either express or implied.  See the License for the
       specific language governing permissions and limitations
       under the License.
*/
package org.apache.cordova.inappbrowser;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.content.res.ColorStateList;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.SystemClock;
import android.provider.Browser;
import android.provider.MediaStore;
import android.provider.Settings;
import android.support.annotation.RequiresApi;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.WindowManager.LayoutParams;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.HttpAuthHandler;
import android.webkit.PermissionRequest;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;


import com.cafepress.mobile.android.BuildConfig;
import com.cafepress.mobile.android.R;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.Config;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaHttpAuthHandler;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginManager;
import org.apache.cordova.PluginResult;
import org.apache.cordova.camera.FileProvider;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.StringTokenizer;

import static android.content.Context.MODE_PRIVATE;
import static org.apache.cordova.device.Device.TAG;

@SuppressLint("SetJavaScriptEnabled")
public class InAppBrowser extends CordovaPlugin {


    private static final int PERMISSIONS_REQUEST_GALLERY = 102;
    private static final int PERMISSIONS_REQUEST_CAMERA = 101;

    private static final String NULL = "null";
    protected static final String LOG_TAG = "InAppBrowser";
    private static final String SELF = "_self";
    private static final String SYSTEM = "_system";
    private static final String EXIT_EVENT = "exit";
    private static final String EXIT_DIALOG_EVENT = "EXIT_DIALOG_EVENT";
    private static final String CLOSE = "closeIN";
    private static final String LOCATION = "location";
    private static final String ZOOM = "zoom";
    private static final String HIDDEN = "hidden";
    private static final String LOAD_START_EVENT = "loadstart";
    private static final String LOAD_STOP_EVENT = "loadstop";
    private static final String LOAD_ERROR_EVENT = "loaderror";
    private static final String CLEAR_ALL_CACHE = "clearcache";
    private static final String CLEAR_SESSION_CACHE = "clearsessioncache";
    private static final String HARDWARE_BACK_BUTTON = "hardwareback";
    private static final String MEDIA_PLAYBACK_REQUIRES_USER_ACTION = "mediaPlaybackRequiresUserAction";
    private static final String SHOULD_PAUSE = "shouldPauseOnSuspend";
    private static final Boolean DEFAULT_HARDWARE_BACK = true;
    private static final String USER_WIDE_VIEW_PORT = "useWideViewPort";
    private static final String TOOLBAR_COLOR = "toolbarcolor";
    private static final String CLOSE_BUTTON_CAPTION = "closebuttoncaption";
    private static final String CLOSE_BUTTON_COLOR = "closebuttoncolor";
    private static final String HIDE_NAVIGATION = "hidenavigationbuttons";
    private static final String NAVIGATION_COLOR = "navigationbuttoncolor";
    private static final String HIDE_URL = "hideurlbar";
    private static final String FOOTER = "footer";
    private static final String FOOTER_COLOR = "footercolor";

    public static final String LOAD_HOME_EVENT = "homeEvent";
    public static final String LOAD_GIFT_GUIDE_EVENT = "giftGuideEvent";
    public static final String LOAD_SETTINGS_EVENT = "settingsEvent";
    public static final String LOAD_DEALS_EVENT = "dealsEvent";
    private static final List customizableOptions = Arrays.asList(CLOSE_BUTTON_CAPTION, TOOLBAR_COLOR, NAVIGATION_COLOR, CLOSE_BUTTON_COLOR, FOOTER_COLOR);

    private InAppBrowserDialog dialog;
    private WebView inAppWebView;
    private ProgressBar mProgressBar;
    private CallbackContext callbackContext;
    private boolean showLocationBar = true;
    private boolean showZoomControls = true;
    private boolean openWindowHidden = false;
    private boolean clearAllCache = false;
    private boolean clearSessionCache = false;
    private boolean hadwareBackButton = true;
    private boolean mediaPlaybackRequiresUserGesture = false;
    private boolean shouldPauseInAppBrowser = false;
    private boolean useWideViewPort = true;
    private ValueCallback<Uri> mUploadCallback;
    private ValueCallback<Uri[]> mUploadCallbackLollipop;
    private final static int FILECHOOSER_REQUESTCODE = 1;
    private final static int FILECHOOSER_REQUESTCODE_LOLLIPOP = 2;
    private String lastClickedTab = "";
    private String lastLoadedUrl = "";
    private String baseUrl = "";
    private int toolbarColor = android.graphics.Color.LTGRAY;
    private boolean hideNavigationButtons = false;
    private String navigationButtonColor = "";
    private boolean hideUrlBar = false;
    private boolean showFooter = false;
    private String footerColor = "";
    private String[] allowedSchemes;
    private static final long MIN_CLICK_INTERVAL = 600;
    private long mLastClickTime;
    private String mCameraPhotoPath;


    /**
     * Executes the request and returns PluginResult.
     *
     * @param action          the action to execute.
     * @param args            JSONArry of arguments for the plugin.
     * @param callbackContext the callbackContext used when calling back into JavaScript.
     * @return A PluginResult object with a status and message.
     */
    public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("open")) {
            this.callbackContext = callbackContext;
            final String url = args.getString(0);
            String t = args.optString(1);
            if (t == null || t.equals("") || t.equals(NULL)) {
                t = SELF;
            }
            final String target = t;
            final HashMap<String, String> features = parseFeature(args.optString(2));

            LOG.d(LOG_TAG, "target = " + target);

            this.cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    String result = "";
                    // SELF
                    if (SELF.equals(target)) {
                        LOG.d(LOG_TAG, "in self");
                        /* This code exists for compatibility between 3.x and 4.x versions of Cordova.
                         * Previously the Config class had a static method, isUrlWhitelisted(). That
                         * responsibility has been moved to the plugins, with an aggregating method in
                         * PluginManager.
                         */
                        Boolean shouldAllowNavigation = null;
                        if (url.startsWith("javascript:")) {
                            shouldAllowNavigation = true;
                        }
                        if (shouldAllowNavigation == null) {
                            try {
                                Method iuw = Config.class.getMethod("isUrlWhiteListed", String.class);
                                shouldAllowNavigation = (Boolean) iuw.invoke(null, url);
                            } catch (NoSuchMethodException e) {
                                LOG.d(LOG_TAG, e.getLocalizedMessage());
                            } catch (IllegalAccessException e) {
                                LOG.d(LOG_TAG, e.getLocalizedMessage());
                            } catch (InvocationTargetException e) {
                                LOG.d(LOG_TAG, e.getLocalizedMessage());
                            }
                        }
                        if (shouldAllowNavigation == null) {
                            try {
                                Method gpm = webView.getClass().getMethod("getPluginManager");
                                PluginManager pm = (PluginManager) gpm.invoke(webView);
                                Method san = pm.getClass().getMethod("shouldAllowNavigation", String.class);
                                shouldAllowNavigation = (Boolean) san.invoke(pm, url);
                            } catch (NoSuchMethodException e) {
                                LOG.d(LOG_TAG, e.getLocalizedMessage());
                            } catch (IllegalAccessException e) {
                                LOG.d(LOG_TAG, e.getLocalizedMessage());
                            } catch (InvocationTargetException e) {
                                LOG.d(LOG_TAG, e.getLocalizedMessage());
                            }
                        }
                        // load in webview
                        if (Boolean.TRUE.equals(shouldAllowNavigation)) {
                            LOG.d(LOG_TAG, "loading in webview");
                            webView.loadUrl(url);
                        }
                        //Load the dialer
                        else if (url.startsWith(WebView.SCHEME_TEL)) {
                            try {
                                LOG.d(LOG_TAG, "loading in dialer");
                                Intent intent = new Intent(Intent.ACTION_DIAL);
                                intent.setData(Uri.parse(url));
                                cordova.getActivity().startActivity(intent);
                            } catch (android.content.ActivityNotFoundException e) {
                                LOG.e(LOG_TAG, "Error dialing " + url + ": " + e.toString());
                            }
                        }
                        // load in InAppBrowser
                        else {
                            LOG.d(LOG_TAG, "loading in InAppBrowser");
                            result = showWebPage(url, features);
                        }
                    }
                    // SYSTEM
                    else if (SYSTEM.equals(target)) {
                        LOG.d(LOG_TAG, "in system");
                        result = openExternal(url);
                    }
                    // BLANK - or anything else
                    else {
                        LOG.d(LOG_TAG, "in blank");
                        result = showWebPage(url, features);
                    }

                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, result);
                    pluginResult.setKeepCallback(true);
                    callbackContext.sendPluginResult(pluginResult);
                }
            });
        } else if (action.equals("close")) {
            closeDialog();
        } else if (action.equals("showDialog")) {

        } else if (action.equals("injectScriptCode")) {
            String jsWrapper = null;
            if (args.getBoolean(1)) {
                jsWrapper = String.format("(function(){prompt(JSON.stringify([eval(%%s)]), 'gap-iab://%s')})()", callbackContext.getCallbackId());
            }
            injectDeferredObject(args.getString(0), jsWrapper);
        } else if (action.equals("injectScriptFile")) {
            String jsWrapper;
            if (args.getBoolean(1)) {
                jsWrapper = String.format("(function(d) { var c = d.createElement('script'); c.src = %%s; c.onload = function() { prompt('', 'gap-iab://%s'); }; d.body.appendChild(c); })(document)", callbackContext.getCallbackId());
            } else {
                jsWrapper = "(function(d) { var c = d.createElement('script'); c.src = %s; d.body.appendChild(c); })(document)";
            }
            injectDeferredObject(args.getString(0), jsWrapper);
        } else if (action.equals("injectStyleCode")) {
            String jsWrapper;
            if (args.getBoolean(1)) {
                jsWrapper = String.format("(function(d) { var c = d.createElement('style'); c.innerHTML = %%s; d.body.appendChild(c); prompt('', 'gap-iab://%s');})(document)", callbackContext.getCallbackId());
            } else {
                jsWrapper = "(function(d) { var c = d.createElement('style'); c.innerHTML = %s; d.body.appendChild(c); })(document)";
            }
            injectDeferredObject(args.getString(0), jsWrapper);
        } else if (action.equals("injectStyleFile")) {
            String jsWrapper;
            if (args.getBoolean(1)) {
                jsWrapper = String.format("(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%s; d.head.appendChild(c); prompt('', 'gap-iab://%s');})(document)", callbackContext.getCallbackId());
            } else {
                jsWrapper = "(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %s; d.head.appendChild(c); })(document)";
            }
            injectDeferredObject(args.getString(0), jsWrapper);
        } else if (action.equals("show")) {
            this.cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (dialog != null)
                        dialog.show();
                }
            });
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
            pluginResult.setKeepCallback(true);
            this.callbackContext.sendPluginResult(pluginResult);
        } else if (action.equals("hide")) {
            this.cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    dialog.hide();
                }
            });
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
            pluginResult.setKeepCallback(true);
            this.callbackContext.sendPluginResult(pluginResult);
        } else {
            return false;
        }
        return true;
    }

    /**
     * Called when the view navigates.
     */
    @Override
    public void onReset() {
        closeDialog();
    }

    /**
     * Called when the system is about to start resuming a previous activity.
     */
    @Override
    public void onPause(boolean multitasking) {
        if (shouldPauseInAppBrowser) {
            inAppWebView.onPause();
        }
    }

    /**
     * Called when the activity will start interacting with the user.
     */
    @Override
    public void onResume(boolean multitasking) {
        if (shouldPauseInAppBrowser) {
            inAppWebView.onResume();
        }
    }

    /**
     * Called by AccelBroker when listener is to be shut down.
     * Stop listener.
     */
    public void onDestroy() {
        closeDialog();
    }

    /**
     * Inject an object (script or style) into the InAppBrowser WebView.
     * <p>
     * This is a helper method for the inject{Script|Style}{Code|File} API calls, which
     * provides a consistent method for injecting JavaScript code into the document.
     * <p>
     * If a wrapper string is supplied, then the source string will be JSON-encoded (adding
     * quotes) and wrapped using string formatting. (The wrapper string should have a single
     * '%s' marker)
     *
     * @param source    The source object (filename or script/style text) to inject into
     *                  the document.
     * @param jsWrapper A JavaScript string to wrap the source string in, so that the object
     *                  is properly injected, or null if the source string is JavaScript text
     *                  which should be executed directly.
     */
    private void injectDeferredObject(String source, String jsWrapper) {
        if (inAppWebView != null) {
            String scriptToInject;
            if (jsWrapper != null) {
                org.json.JSONArray jsonEsc = new org.json.JSONArray();
                jsonEsc.put(source);
                String jsonRepr = jsonEsc.toString();
                String jsonSourceString = jsonRepr.substring(1, jsonRepr.length() - 1);
                scriptToInject = String.format(jsWrapper, jsonSourceString);
            } else {
                scriptToInject = source;
            }
            final String finalScriptToInject = scriptToInject;
            this.cordova.getActivity().runOnUiThread(new Runnable() {
                @SuppressLint("NewApi")
                @Override
                public void run() {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
                        // This action will have the side-effect of blurring the currently focused element
                        inAppWebView.loadUrl("javascript:" + finalScriptToInject);
                    } else {
                        inAppWebView.evaluateJavascript(finalScriptToInject, null);
                    }
                }
            });
        } else {
            LOG.d(LOG_TAG, "Can't inject code into the system browser");
        }
    }

    /**
     * Put the list of features into a hash map
     *
     * @param optString
     * @return
     */
    private HashMap<String, String> parseFeature(String optString) {
        if (optString.equals(NULL)) {
            return null;
        } else {
            HashMap<String, String> map = new HashMap<String, String>();
            StringTokenizer features = new StringTokenizer(optString, ",");
            StringTokenizer option;
            while (features.hasMoreElements()) {
                option = new StringTokenizer(features.nextToken(), "=");
                if (option.hasMoreElements()) {
                    String key = option.nextToken();
                    String value = option.nextToken();
                    if (!customizableOptions.contains(key)) {
                        value = value.equals("yes") || value.equals("no") ? value : "yes";
                    }
                    map.put(key, value);
                }
            }
            return map;
        }
    }

    /**
     * Display a new browser with the specified URL.
     *
     * @param url the url to load.
     * @return "" if ok, or error message.
     */
    public String openExternal(String url) {
        try {
            Intent intent = null;
            intent = new Intent(Intent.ACTION_VIEW);
            // Omitting the MIME type for file: URLs causes "No Activity found to handle Intent".
            // Adding the MIME type to http: URLs causes them to not be handled by the downloader.
            Uri uri = Uri.parse(url);
            if ("file".equals(uri.getScheme())) {
                intent.setDataAndType(uri, webView.getResourceApi().getMimeType(uri));
            } else {
                intent.setData(uri);
            }
            intent.putExtra(Browser.EXTRA_APPLICATION_ID, cordova.getActivity().getPackageName());
            this.cordova.getActivity().startActivity(intent);
            return "";
            // not catching FileUriExposedException explicitly because buildtools<24 doesn't know about it
        } catch (java.lang.RuntimeException e) {
            LOG.d(LOG_TAG, "InAppBrowser: Error loading url " + url + ":" + e.toString());
            return e.toString();
        }
    }

    /**
     * Closes the dialog
     */
    public void closeDialog() {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final WebView childView = inAppWebView;
                // The JS protects against multiple calls, so this should happen only when
                // closeDialog() is called by other native code.
                if (childView == null) {
                    return;
                }

                childView.setWebViewClient(new WebViewClient() {
                    // NB: wait for about:blank before dismissing
                    public void onPageFinished(WebView view, String url) {
                        try {
                            if (dialog != null) {
                                dialog.dismiss();
                                dialog = null;
                            }
                        } catch (IllegalArgumentException e) {
                            e.printStackTrace();
                        }
                    }
                });
                // NB: From SDK 19: "If you call methods on WebView from any thread
                // other than your app's UI thread, it can cause unexpected results."
                // http://developer.android.com/guide/webapps/migrating.html#Threads
                childView.loadUrl("about:blank");

                try {
                    JSONObject obj = new JSONObject();
                    obj.put("type", EXIT_DIALOG_EVENT);
                    sendUpdate(obj, true);
                } catch (JSONException ex) {
                    LOG.d(LOG_TAG, "Should never happen");
                }
            }
        });

    }

    public void closeDialogFromBackButton() {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final WebView childView = inAppWebView;
                // The JS protects against multiple calls, so this should happen only when
                // closeDialog() is called by other native code.
                if (childView == null) {
                    return;
                }

                childView.setWebViewClient(new WebViewClient() {
                    // NB: wait for about:blank before dismissing
                    public void onPageFinished(WebView view, String url) {
                        try {
                            if (dialog != null) {
                                dialog.dismiss();
                                dialog = null;
                            }
                        } catch (IllegalArgumentException e) {
                            e.printStackTrace();
                        }
                    }
                });
                // NB: From SDK 19: "If you call methods on WebView from any thread
                // other than your app's UI thread, it can cause unexpected results."
                // http://developer.android.com/guide/webapps/migrating.html#Threads
                childView.loadUrl("about:blank");

                try {
                    JSONObject obj = new JSONObject();
                    obj.put("type", EXIT_EVENT);
                    sendUpdate(obj, true);
                } catch (JSONException ex) {
                    LOG.d(LOG_TAG, "Should never happen");
                }
            }
        });
    }

    /**
     * Checks to see if it is possible to go back one page in history, then does so.
     */
    public void goBack() {
        if (this.inAppWebView.canGoBack()) {
            this.inAppWebView.goBack();
        }
    }

    /**
     * Can the web browser go back?
     *
     * @return boolean
     */
    public boolean canGoBack() {
        return this.inAppWebView.canGoBack();
    }

    /**
     * Has the user set the hardware back button to go back
     *
     * @return boolean
     */
    public boolean hardwareBack() {
        return hadwareBackButton;
    }

    /**
     * Checks to see if it is possible to go forward one page in history, then does so.
     */
    private void goForward() {
        if (this.inAppWebView.canGoForward()) {
            this.inAppWebView.goForward();
        }
    }


    /**
     * Should we show the location bar?
     *
     * @return boolean
     */
    private boolean getShowLocationBar() {
        return this.showLocationBar;
    }

    private InAppBrowser getInAppBrowser() {
        return this;
    }

    /**
     * Display a new browser with the specified URL.
     *
     * @param url      the url to load.
     * @param features jsonObject
     */
    public String showWebPage(final String url, HashMap<String, String> features) {


        // Determine if we should hide the location bar.
        showLocationBar = true;
        showZoomControls = true;
        openWindowHidden = false;
        mediaPlaybackRequiresUserGesture = false;

        if (features != null) {
            String show = features.get(LOCATION);
            if (show != null) {
                showLocationBar = show.equals("yes");
            }
            if (showLocationBar) {
                String hideNavigation = features.get(HIDE_NAVIGATION);
                String hideUrl = features.get(HIDE_URL);
                if (hideNavigation != null)
                    hideNavigationButtons = hideNavigation.equals("yes");
                if (hideUrl != null) hideUrlBar = hideUrl.equals("yes");
            }
            String zoom = features.get(ZOOM);
            if (zoom != null) {
                showZoomControls = zoom.equals("yes");
            }
            String hidden = features.get(HIDDEN);
            if (hidden != null) {
                openWindowHidden = hidden.equals("yes");
            }
            String hardwareBack = features.get(HARDWARE_BACK_BUTTON);
            if (hardwareBack != null) {
                hadwareBackButton = hardwareBack.equals("yes");
            } else {
                hadwareBackButton = DEFAULT_HARDWARE_BACK;
            }
            String mediaPlayback = features.get(MEDIA_PLAYBACK_REQUIRES_USER_ACTION);
            if (mediaPlayback != null) {
                mediaPlaybackRequiresUserGesture = mediaPlayback.equals("yes");
            }
            String cache = features.get(CLEAR_ALL_CACHE);
            if (cache != null) {
                clearAllCache = cache.equals("yes");
            } else {
                cache = features.get(CLEAR_SESSION_CACHE);
                if (cache != null) {
                    clearSessionCache = cache.equals("yes");
                }
            }
            String shouldPause = features.get(SHOULD_PAUSE);
            if (shouldPause != null) {
                shouldPauseInAppBrowser = shouldPause.equals("yes");
            }
            String wideViewPort = features.get(USER_WIDE_VIEW_PORT);
            if (wideViewPort != null) {
                useWideViewPort = wideViewPort.equals("yes");
            }
            String closeButtonCaptionSet = features.get(CLOSE_BUTTON_CAPTION);
            if (closeButtonCaptionSet != null) {
                lastClickedTab = closeButtonCaptionSet;
            }
            String closeButtonColorSet = features.get(CLOSE_BUTTON_COLOR);
            if (closeButtonColorSet != null) {
                baseUrl = closeButtonColorSet;
            }
            String toolbarColorSet = features.get(TOOLBAR_COLOR);
            if (toolbarColorSet != null) {
                toolbarColor = android.graphics.Color.parseColor(toolbarColorSet);
            }
            String navigationButtonColorSet = features.get(NAVIGATION_COLOR);
            if (navigationButtonColorSet != null) {
                navigationButtonColor = navigationButtonColorSet;
            }
            String showFooterSet = features.get(FOOTER);
            if (showFooterSet != null) {
                showFooter = showFooterSet.equals("yes");
            }
            String footerColorSet = features.get(FOOTER_COLOR);
            if (footerColorSet != null) {
                footerColor = footerColorSet;
            }
        }

        final CordovaWebView thatWebView = this.webView;

        // Create dialog in new thread
        Runnable runnable = new Runnable() {
            /**
             * Convert our DIP units to Pixels
             *
             * @return int
             */
            private int dpToPixels(int dipValue) {
                int value = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                        (float) dipValue,
                        cordova.getActivity().getResources().getDisplayMetrics()
                );

                return value;
            }


            @SuppressLint("NewApi")
            public void run() {

                // CB-6702 InAppBrowser hangs when opening more than one instance
                if (dialog != null) {
                    dialog.dismiss();
                }

                // Let's create the main dialog
                dialog = new InAppBrowserDialog(cordova.getActivity(), android.R.style.Theme_NoTitleBar);

                //dialog.getWindow().getAttributes().windowAnimations = android.R.style.Animation_Dialog;
                dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                dialog.setCancelable(true);
                dialog.setInAppBroswer(getInAppBrowser());

                // Main container layout
                LinearLayout main = new LinearLayout(cordova.getActivity());
                main.setBackgroundColor(cordova.getActivity().getColor(R.color.White));
                main.setOrientation(LinearLayout.VERTICAL);


                RelativeLayout webViewLayout = new RelativeLayout(cordova.getActivity());


                // Footer
                RelativeLayout.LayoutParams footerParams = new RelativeLayout.LayoutParams(LayoutParams.MATCH_PARENT, this.dpToPixels(65));
                footerParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM, RelativeLayout.TRUE);

                int footer_id = 122;
                LinearLayout footer = new LinearLayout(cordova.getActivity());
                footer.setId(footer_id);
                footer.setBackgroundColor(Color.WHITE);
                footer.setOrientation(LinearLayout.VERTICAL);
                footer.setLayoutParams(footerParams);
                webViewLayout.addView(footer);


                // WebView
                RelativeLayout.LayoutParams webViewParams = new RelativeLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
                webViewParams.addRule(RelativeLayout.ABOVE, footer_id);

                inAppWebView = new WebView(cordova.getActivity());
                inAppWebView.setId(Integer.valueOf(6));
                inAppWebView.setLayoutParams(webViewParams);
                webViewLayout.addView(inAppWebView);



                /*ADDING WEBVIEW TO THE MAIN VIEW*/
                main.addView(webViewLayout);


                // File Chooser Implemented ChromeClient
                inAppWebView.setWebChromeClient(new InAppChromeClient(thatWebView) {

                    @Override
                    public void onPermissionRequest(PermissionRequest request) {
                        super.onPermissionRequest(request);
                    }

                    @Override
                    public void onProgressChanged(WebView view, int newProgress) {
                        super.onProgressChanged(view, newProgress);
                        updateProgress(newProgress);
                    }

                    // For Android 5.0+
                    public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback, WebChromeClient.FileChooserParams fileChooserParams) {
                        LOG.d(LOG_TAG, "File Chooser 5.0+");
                        // If callback exists, finish it.
                        mUploadCallbackLollipop = filePathCallback;
                        boolean galleyStatus = cordova.hasPermission(Manifest.permission.READ_EXTERNAL_STORAGE);
                        if (galleyStatus) {
                            showCameraAndGalleryDialog();
                        } else {
                            cordova.requestPermissions(InAppBrowser.this, PERMISSIONS_REQUEST_GALLERY,
                                    new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,
                                            Manifest.permission.WRITE_EXTERNAL_STORAGE});
                        }

                        return true;
                    }

                    // For Android 4.1+
                    public void openFileChooser(ValueCallback<Uri> uploadMsg, String acceptType, String capture) {
                        LOG.d(LOG_TAG, "File Chooser 4.1+");
                        // Call file chooser for Android 3.0+
                        openFileChooser(uploadMsg, acceptType);
                    }

                    // For Android 3.0+
                    public void openFileChooser(ValueCallback<Uri> uploadMsg, String acceptType) {
                        LOG.d(LOG_TAG, "File Chooser 3.0+");
                        mUploadCallback = uploadMsg;
                        Intent content = new Intent(Intent.ACTION_GET_CONTENT);
                        content.addCategory(Intent.CATEGORY_OPENABLE);

                        // run startActivityForResult
                        cordova.startActivityForResult(InAppBrowser.this, Intent.createChooser(content, "Select File"), FILECHOOSER_REQUESTCODE);
                    }

                });
                WebViewClient client = new InAppBrowserClient(thatWebView);
                inAppWebView.setWebViewClient(client);

                WebSettings settings = inAppWebView.getSettings();
                settings.setJavaScriptEnabled(true);
                settings.setJavaScriptCanOpenWindowsAutomatically(true);
                settings.setBuiltInZoomControls(showZoomControls);
                settings.setPluginState(android.webkit.WebSettings.PluginState.ON);
                settings.setMediaPlaybackRequiresUserGesture(mediaPlaybackRequiresUserGesture);

                /*USER AGENT*/
                String versionName = "Cpmobileappandroidv"+BuildConfig.VERSION_NAME;
                String userAgent = versionName+ " "+settings.getUserAgentString();
                settings.setUserAgentString(userAgent);


                //Toggle whether this is enabled or not!
                Bundle appSettings = cordova.getActivity().getIntent().getExtras();
                boolean enableDatabase = appSettings == null || appSettings.getBoolean("InAppBrowserStorageEnabled", true);
                if (enableDatabase) {
                    String databasePath = cordova.getActivity().getApplicationContext().getDir("inAppBrowserDB", MODE_PRIVATE).getPath();
                    settings.setDatabasePath(databasePath);
                    settings.setDatabaseEnabled(true);
                }
                settings.setDomStorageEnabled(true);

                SharedPreferences prefs = cordova.getActivity().getSharedPreferences(LOG_TAG, MODE_PRIVATE);
                boolean isFirstRun = prefs.getBoolean("firstRun", true);
                if (isFirstRun) {
                    SharedPreferences.Editor editor = prefs.edit();
                    editor.putBoolean("firstRun", false);
                    editor.apply();
                    CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
                        @Override
                        public void onReceiveValue(Boolean aBoolean) {
                            Log.d(TAG, "Cookies Removed " + aBoolean);
                        }
                    });
                }


                if (clearAllCache) {
                    CookieManager.getInstance().removeAllCookie();
                } else if (clearSessionCache) {
                    CookieManager.getInstance().removeSessionCookie();
                }

                // Enable Thirdparty Cookies on >=Android 5.0 device
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                    CookieManager.getInstance().setAcceptThirdPartyCookies(inAppWebView, true);
                }

                inAppWebView.loadUrl(url);
                inAppWebView.setId(Integer.valueOf(6));
                inAppWebView.getSettings().setLoadWithOverviewMode(true);
                inAppWebView.getSettings().setUseWideViewPort(useWideViewPort);
                inAppWebView.requestFocus();
                inAppWebView.requestFocusFromTouch();


                WindowManager.LayoutParams lp = new WindowManager.LayoutParams();
                lp.copyFrom(dialog.getWindow().getAttributes());
                lp.width = WindowManager.LayoutParams.MATCH_PARENT;
                lp.height = WindowManager.LayoutParams.MATCH_PARENT;

                dialog.setContentView(main);
                dialog.show();
                dialog.getWindow().setAttributes(lp);
                // the goal of openhidden is to load the url and not display it
                // Show() needs to be called to cause the URL to be loaded
                if (openWindowHidden) {
                    dialog.hide();
                }

                View footerHome = createBottomView1(url);
                mProgressBar = creteProgressBarView();
                footer.addView(mProgressBar);
                footer.addView(footerHome);
            }
        };
        this.cordova.getActivity().runOnUiThread(runnable);
        return "";
    }


    private void showCameraAndGalleryDialog() {
        String[] options = {"Camera", "Gallery", "Cancel"};

        AlertDialog.Builder builder = new AlertDialog.Builder(cordova.getActivity());
        builder.setCancelable(false);
        builder.setTitle("Select Option");
        builder.setItems(options, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int item) {
                switch (options[item]) {
                    case "Camera":
                        boolean cameraStatus = cordova.hasPermission(Manifest.permission.CAMERA);
                        if (cameraStatus)
                            openCamera();
                        else
                            cordova.requestPermission(InAppBrowser.this, PERMISSIONS_REQUEST_CAMERA, Manifest.permission.CAMERA);
                        break;
                    case "Gallery":
                        openGallery();
                        break;
                    case "Cancel":
                        mUploadCallbackLollipop.onReceiveValue(new Uri[]{});
                        mUploadCallbackLollipop = null;
                        break;
                }
                dialog.dismiss();
            }
        });
        builder.show();
    }

    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        if (grantResults.length > 0) {
            switch (requestCode) {
                case PERMISSIONS_REQUEST_CAMERA:
                    boolean cameraPermission = grantResults[0] == PackageManager.PERMISSION_GRANTED;
                    if (cameraPermission)
                        openCamera();
                    else {
                        mUploadCallbackLollipop.onReceiveValue(new Uri[]{});
                        mUploadCallbackLollipop = null;
                    }
                    break;
                case PERMISSIONS_REQUEST_GALLERY:
                    boolean galleryPermission = grantResults[0] == PackageManager.PERMISSION_GRANTED;
                    if (galleryPermission)
                        showCameraAndGalleryDialog();
                    else {
                        mUploadCallbackLollipop.onReceiveValue(new Uri[]{});
                        mUploadCallbackLollipop = null;
                    }
                    break;
            }

        }


    }


    private void openGallery() {
        Intent contentSelectionIntent = new Intent(Intent.ACTION_GET_CONTENT);
        contentSelectionIntent.addCategory(Intent.CATEGORY_OPENABLE);
        contentSelectionIntent.setType("image/*");
        cordova.startActivityForResult(InAppBrowser.this, contentSelectionIntent, FILECHOOSER_REQUESTCODE_LOLLIPOP);
    }

    private void openCamera() {
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(cordova.getActivity().getPackageManager()) != null) {
            try {
                // Create an image file name
                String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date());
                String imageFileName = "CP_" + timeStamp + "_";
                File storageDir = Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_PICTURES);
                File photoFile = File.createTempFile(imageFileName, ".jpg", storageDir);
                mCameraPhotoPath = "file:" + photoFile.getAbsolutePath();
                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, FileProvider.getUriForFile(cordova.getActivity(),
                        BuildConfig.APPLICATION_ID + ".provider", photoFile));
            } catch (IOException ex) {
                Log.e(TAG, "Unable to create Image File", ex);
            }
        }
        cordova.startActivityForResult(InAppBrowser.this, takePictureIntent, FILECHOOSER_REQUESTCODE_LOLLIPOP);
    }

    @SuppressLint("NewApi")
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (mUploadCallbackLollipop == null)
            return;


        Uri[] results = null;
        if (resultCode == Activity.RESULT_OK) {

            if (intent != null && intent.getDataString() != null)
                results = new Uri[]{Uri.parse(intent.getDataString())};
            else if (mCameraPhotoPath != null)
                results = new Uri[]{Uri.parse(mCameraPhotoPath)};

            if (results != null)
                mUploadCallbackLollipop.onReceiveValue(results);
            else
                mUploadCallbackLollipop.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(resultCode, intent));


            mUploadCallbackLollipop = null;
        } else {
            mUploadCallbackLollipop.onReceiveValue(new Uri[]{});
            mUploadCallbackLollipop = null;
        }
    }


    private View createBottomView1(String url) {

        AssetManager am = cordova.getActivity().getAssets();

        Typeface typeface = Typeface.createFromAsset(am, "www/assets/fonts/open-sans-regular.ttf");


        /*MAIN LAYOUT*/
        LinearLayout mainLayout = new LinearLayout(cordova.getActivity());
        LinearLayout.LayoutParams mainLp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT);
        mainLp.weight = 4;
        mainLp.gravity = Gravity.CENTER;
        mainLayout.setLayoutParams(mainLp);


        /*HOME*/
        TextView tv_home = crateTabItem(1, "Featured", R.drawable.ic_action_home, mainLayout);
        tv_home.setTypeface(typeface);
        tv_home.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                lastClickedTab = "Featured";
                changeClickedItemColor(mainLayout, 0);
                bottomViewOnClick(LOAD_HOME_EVENT);
                loadBottomViewUrl(baseUrl);
            }
        });



        /*DEALS*/
        TextView tv_cart = crateTabItem(4, "Deals", R.drawable.ic_action_deal, mainLayout);
        tv_cart.setTypeface(typeface);
        tv_cart.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                lastClickedTab = "Deals";
                changeClickedItemColor(mainLayout, 1);
                bottomViewOnClick(LOAD_DEALS_EVENT);
                loadBottomViewUrl(baseUrl + "/p/sale");
            }
        });


        /*GIFT GUIDE*/
        TextView tv_gift = crateTabItem(2, "Gift Guide", R.drawable.ic_action_gift_guide, mainLayout);
        tv_gift.setTypeface(typeface);
        tv_gift.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                lastClickedTab = "Gift Guide";
                changeClickedItemColor(mainLayout, 2);
                bottomViewOnClick(LOAD_GIFT_GUIDE_EVENT);
                loadBottomViewUrl(baseUrl + "/p/gift-center");
            }
        });

        /*SETTINGS*/
        TextView tv_settings = crateTabItem(5, "Settings", R.drawable.ic_action_settings, mainLayout);
        tv_settings.setTypeface(typeface);
        tv_settings.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                long currentClickTime = SystemClock.uptimeMillis();
                long elapsedTime = currentClickTime - mLastClickTime;
                mLastClickTime = currentClickTime;
                if (elapsedTime <= MIN_CLICK_INTERVAL)
                    return;

                try {
                    JSONObject obj = new JSONObject();
                    obj.put("type", "customscheme");
                    obj.put("tab", lastClickedTab);
                    obj.put("lastUrl", lastLoadedUrl);
                    sendUpdate(obj, true);
                } catch (JSONException ex) {
                    LOG.d(LOG_TAG, "Should never happen");
                }
            }
        });


        if (lastClickedTab != null) {
            if (lastClickedTab.equalsIgnoreCase("Featured")) {
                lastClickedTab = "Featured";
                changeClickedItemColor(mainLayout, 0);
                bottomViewOnClick(LOAD_HOME_EVENT);
                loadBottomViewUrl(url);

            } else if (lastClickedTab.equalsIgnoreCase("Deals")) {
                lastClickedTab = "Deals";
                changeClickedItemColor(mainLayout, 1);
                bottomViewOnClick(LOAD_DEALS_EVENT);
                loadBottomViewUrl(url);

            } else if (lastClickedTab.equalsIgnoreCase("Gift Guide")) {
                lastClickedTab = "Gift Guide";
                changeClickedItemColor(mainLayout, 2);
                bottomViewOnClick(LOAD_GIFT_GUIDE_EVENT);
                loadBottomViewUrl(url);
            }

        } else {
            lastClickedTab = "Featured";
            changeClickedItemColor(mainLayout, 0);
            bottomViewOnClick(LOAD_HOME_EVENT);
            loadBottomViewUrl(url);
        }


        return mainLayout;
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private ProgressBar creteProgressBarView() {

        // Create horizontal progressBar dynamically...
        ProgressBar progressBar = new ProgressBar(cordova.getActivity(), null, android.R.attr.progressBarStyleHorizontal);
        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 15);
        layoutParams.setMargins(0, 0, 0, 0);
        layoutParams.gravity = Gravity.CENTER;
        progressBar.setLayoutParams(layoutParams);
        progressBar.setProgressTintList(ColorStateList.valueOf(cordova.getActivity().getResources().getColor(R.color.colorPrimary)));
        progressBar.setVisibility(View.VISIBLE);


        return progressBar;
    }

    private void showProgressbarView() {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mProgressBar != null)
                    mProgressBar.setVisibility(View.VISIBLE);
            }
        });
    }

    private void loadOnErrorView() {
        //String summary = "<html><body><b>Site is down, Please try after some time.</b></body></html>";
        inAppWebView.setVisibility(View.INVISIBLE);
    }

    private void hideProgressbarView() {

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                final Handler handler = new Handler();
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (mProgressBar != null)
                            mProgressBar.setVisibility(View.INVISIBLE);

                        handler.removeCallbacks(null);
                    }
                }, 300);
            }
        });
    }

    private void updateProgress(int progress) {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mProgressBar != null) {
                    mProgressBar.setProgress(progress);

                    if (progress == 100)
                        hideProgressbarView();

                }
            }
        });
    }

    private void loadBottomViewUrl(String url) {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                inAppWebView.loadUrl(url);
            }
        });
    }


    private void showCallPermissonDialog() {
        new AlertDialog.Builder(cordova.getActivity())
                .setMessage("Enable Permissions from App Settings")
                .setPositiveButton("Settings", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        navigateToSettingsScreen();
                    }
                })
                .setNegativeButton("No", null)
                .show();
    }


    private void navigateToSettingsScreen() {
        try {
            String pack = cordova.getActivity().getPackageName();
            Intent myAppSettings = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + pack));
            myAppSettings.addCategory(Intent.CATEGORY_DEFAULT);
            myAppSettings.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            cordova.getActivity().startActivity(myAppSettings);
        } catch (Exception e) {
            Intent intent = new Intent();
            intent.setAction(android.provider.Settings.ACTION_SETTINGS);
            cordova.startActivityForResult(InAppBrowser.this, intent, 1333);
        }
    }


    private TextView crateTabItem(int id, String label, int drawble, LinearLayout mainLayout) {
        TextView view = new TextView(cordova.getActivity());
        view.setId(id);
        view.setCompoundDrawablesWithIntrinsicBounds(0, drawble, 0, 0);
        view.setText(label);
        view.setGravity(Gravity.CENTER);
        view.setTextSize(11f);
        view.setTextColor(Color.BLACK);
        view.setTypeface(Typeface.DEFAULT_BOLD);
        view.setPadding(0, 25, 0, 0);
        view.setLayoutParams(new LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, 1f));
        mainLayout.addView(view);
        return view;
    }


    private void bottomViewOnClick(String event) {
        try {
            JSONObject obj = new JSONObject();
            obj.put("type", event);
            sendUpdate(obj, true);
        } catch (JSONException ex) {
            LOG.d(LOG_TAG, "Should never happen");
        }
    }

    private void changeClickedItemColor(LinearLayout mainLayout, int id) {
        for (int i = 0; i < mainLayout.getChildCount(); i++) {
            View view = mainLayout.getChildAt(i);
            if (view instanceof TextView) {
                TextView textView = (TextView) view;

                if (i == id) {
                    textView.setTextColor(cordova.getActivity().getResources().getColor(R.color.colorPrimary));
                    setTextViewDrawableColor(textView, cordova.getActivity().getResources().getColor(R.color.colorPrimary));
                } else {
                    textView.setTextColor(cordova.getActivity().getResources().getColor(R.color.un_select));
                    setTextViewDrawableColor(textView, cordova.getActivity().getResources().getColor(R.color.un_select));
                }
            }
        }
    }

    private void setTextViewDrawableColor(TextView textView, int color) {
        for (Drawable drawable : textView.getCompoundDrawables()) {
            if (drawable != null)
                drawable.setColorFilter(new PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN));

        }
    }


    private void sendEvent() {

        try {
            JSONObject obj = new JSONObject();
            obj.put("type", CLOSE);
            sendUpdate(obj, true);
        } catch (JSONException ex) {
            LOG.d(LOG_TAG, "Should never happen");
        }

    }

    /**
     * Create a new plugin success result and send it back to JavaScript
     *
     * @param obj a JSONObject contain event payload information
     */
    private void sendUpdate(JSONObject obj, boolean keepCallback) {
        sendUpdate(obj, keepCallback, PluginResult.Status.OK);
    }

    /**
     * Create a new plugin result and send it back to JavaScript
     *
     * @param obj    a JSONObject contain event payload information
     * @param status the status code to return to the JavaScript environment
     */
    private void sendUpdate(JSONObject obj, boolean keepCallback, PluginResult.Status status) {
        if (callbackContext != null) {
            PluginResult result = new PluginResult(status, obj);
            result.setKeepCallback(keepCallback);
            callbackContext.sendPluginResult(result);
            if (!keepCallback) {
                callbackContext = null;
            }
        }
    }

    /**
     * Receive File Data from File Chooser
     *
     * @param requestCode the requested code from chromeclient
     * @param resultCode  the result code returned from android system
     * @param intent      the data from android file chooser
     */


    /**
     * The webview client receives notifications about appView
     */
    public class InAppBrowserClient extends WebViewClient {

        CordovaWebView webView;

        /**
         * Constructor.
         *
         * @param webView
         */
        public InAppBrowserClient(CordovaWebView webView) {
            this.webView = webView;
        }


        @Override
        public boolean shouldOverrideUrlLoading(WebView webView, String url) {
            if (url.startsWith(WebView.SCHEME_TEL)) {
                try {

                    if (isSimSupport(cordova.getActivity())) {
                        boolean phoneStatus = cordova.hasPermission(Manifest.permission.CALL_PHONE);
                        if (phoneStatus) {
                            Intent intent = new Intent(Intent.ACTION_DIAL);
                            intent.setData(Uri.parse(url));
                            cordova.getActivity().startActivity(intent);
                            return true;
                        } else {
                            showCallPermissonDialog();
                            return true;
                        }

                    } else
                        return true;
                } catch (android.content.ActivityNotFoundException e) {
                    LOG.e(LOG_TAG, "Error dialing " + url + ": " + e.toString());
                    return true;
                }
            } else if (url.startsWith("geo:") || url.startsWith(WebView.SCHEME_MAILTO) || url.startsWith("market:") || url.startsWith("intent:")) {
                try {
                    Intent intent = new Intent(Intent.ACTION_VIEW);
                    intent.setData(Uri.parse(url));
                    cordova.getActivity().startActivity(intent);
                    return true;
                } catch (android.content.ActivityNotFoundException e) {
                    LOG.e(LOG_TAG, "Error with " + url + ": " + e.toString());
                }
            }
            // If sms:5551212?body=This is the message
            else if (url.startsWith("sms:")) {
                try {
                    Intent intent = new Intent(Intent.ACTION_VIEW);

                    // Get address
                    String address;
                    int parmIndex = url.indexOf('?');
                    if (parmIndex == -1) {
                        address = url.substring(4);
                    } else {
                        address = url.substring(4, parmIndex);

                        // If body, then set sms body
                        Uri uri = Uri.parse(url);
                        String query = uri.getQuery();
                        if (query != null) {
                            if (query.startsWith("body=")) {
                                intent.putExtra("sms_body", query.substring(5));
                            }
                        }
                    }
                    intent.setData(Uri.parse("sms:" + address));
                    intent.putExtra("address", address);
                    intent.setType("vnd.android-dir/mms-sms");
                    cordova.getActivity().startActivity(intent);
                    return true;
                } catch (android.content.ActivityNotFoundException e) {
                    LOG.e(LOG_TAG, "Error sending sms " + url + ":" + e.toString());
                }
            }
            // Test for whitelisted custom scheme names like mycoolapp:// or twitteroauthresponse:// (Twitter Oauth Response)
            else if (!url.startsWith("http:") && !url.startsWith("https:") && url.matches("^[a-z]*://.*?$")) {
                if (allowedSchemes == null) {
                    String allowed = preferences.getString("AllowedSchemes", "");
                    allowedSchemes = allowed.split(",");
                }
                if (allowedSchemes != null) {
                    for (String scheme : allowedSchemes) {
                        if (url.startsWith(scheme)) {
                            try {
                                JSONObject obj = new JSONObject();
                                obj.put("type", "scheme");
                                obj.put("url", url);
                                sendUpdate(obj, true);
                                return true;
                            } catch (JSONException ex) {
                                LOG.e(LOG_TAG, "Custom Scheme URI passed in has caused a JSON error.");
                            }
                        }
                    }
                }
            }

            return false;
        }


        /*
         * onPageStarted fires the LOAD_START_EVENT
         *
         * @param view
         * @param url
         * @param favicon
         */
        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);

            showProgressbarView();

            String newloc = "";
            if (url.startsWith("http:") || url.startsWith("https:") || url.startsWith("file:")) {
                newloc = url;
            } else {
                // Assume that everything is HTTP at this point, because if we don't specify,
                // it really should be.  Complain loudly about this!!!
                LOG.e(LOG_TAG, "Possible Uncaught/Unknown URI");
                newloc = "http://" + url;
            }


            lastLoadedUrl = newloc;
            try {
                JSONObject obj = new JSONObject();
                obj.put("type", LOAD_START_EVENT);
                obj.put("url", newloc);
                obj.put("lastClickedTab", lastClickedTab);
                sendUpdate(obj, true);
            } catch (JSONException ex) {
                LOG.e(LOG_TAG, "URI passed in has caused a JSON error.");
            }
        }


        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);


            // CB-10395 InAppBrowser's WebView not storing cookies reliable to local device storage
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                CookieManager.getInstance().flush();
            } else {
                CookieSyncManager.getInstance().sync();
            }

            // https://issues.apache.org/jira/browse/CB-11248
            view.clearFocus();
            view.requestFocus();

            try {
                JSONObject obj = new JSONObject();
                obj.put("type", LOAD_STOP_EVENT);
                obj.put("url", url);
                obj.put("lastClickedTab", lastClickedTab);

                sendUpdate(obj, true);
            } catch (JSONException ex) {
                LOG.d(LOG_TAG, "Should never happen");
            }
        }

        private boolean isSimSupport(Context context) {
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
            if (tm == null)
                return false;

            int simState = tm.getSimState();
            return simState == TelephonyManager.SIM_STATE_READY;
        }


        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);

            hideProgressbarView();
            loadOnErrorView();

            try {
                JSONObject obj = new JSONObject();
                obj.put("type", LOAD_ERROR_EVENT);
                obj.put("url", failingUrl);
                obj.put("code", errorCode);
                obj.put("message", description);

                sendUpdate(obj, true, PluginResult.Status.ERROR);
            } catch (JSONException ex) {
                LOG.d(LOG_TAG, "Should never happen");
            }
        }


        /**
         * On received http auth request.
         */
        @Override
        public void onReceivedHttpAuthRequest(WebView view, HttpAuthHandler handler, String host, String realm) {

            // Check if there is some plugin which can resolve this auth challenge
            PluginManager pluginManager = null;
            try {
                Method gpm = webView.getClass().getMethod("getPluginManager");
                pluginManager = (PluginManager) gpm.invoke(webView);
            } catch (NoSuchMethodException e) {
                LOG.d(LOG_TAG, e.getLocalizedMessage());
            } catch (IllegalAccessException e) {
                LOG.d(LOG_TAG, e.getLocalizedMessage());
            } catch (InvocationTargetException e) {
                LOG.d(LOG_TAG, e.getLocalizedMessage());
            }

            if (pluginManager == null) {
                try {
                    Field pmf = webView.getClass().getField("pluginManager");
                    pluginManager = (PluginManager) pmf.get(webView);
                } catch (NoSuchFieldException e) {
                    LOG.d(LOG_TAG, e.getLocalizedMessage());
                } catch (IllegalAccessException e) {
                    LOG.d(LOG_TAG, e.getLocalizedMessage());
                }
            }

            if (pluginManager != null && pluginManager.onReceivedHttpAuthRequest(webView, new CordovaHttpAuthHandler(handler), host, realm)) {
                return;
            }

            // By default handle 401 like we'd normally do!
            super.onReceivedHttpAuthRequest(view, handler, host, realm);
        }
    }


}