package mx.ferreyra.callnumber;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.inappbrowser.InAppBrowser;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.List;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.content.pm.PackageManager;

public class CFCallNumber extends CordovaPlugin {
    public static final int CALL_REQ_CODE = 0;
    public static final int PERMISSION_DENIED_ERROR = 20;
    public static final String CALL_PHONE = Manifest.permission.CALL_PHONE;

    private CallbackContext callbackContext;        // The callback context from which we were invoked.
    private JSONArray executeArgs;

    protected void getCallPermission(int requestCode) {
        cordova.requestPermission(this, requestCode, CALL_PHONE);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;
        this.executeArgs = args;

        if (cordova.hasPermission(CALL_PHONE)) {
            callPhone(executeArgs);
        } else {
            getCallPermission(CALL_REQ_CODE);
        }

        return true;
    }

    @SuppressLint("NewApi")
    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException {
        for (int r : grantResults) {
            if (r == PackageManager.PERMISSION_DENIED) {
                boolean showRationale = cordova.getActivity().shouldShowRequestPermissionRationale(CALL_PHONE);
                if (!showRationale) {
                    showCallPermissionDialog();
                    return;
                } else {
                    this.callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, PERMISSION_DENIED_ERROR));
                    return;
                }

            }
        }


        if (requestCode == CALL_REQ_CODE)
            callPhone(executeArgs);

    }

    private void showCallPermissionDialog() {
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
            cordova.startActivityForResult(this, intent, 1333);
        }
    }

    private void callPhone(JSONArray args) throws JSONException {
        String number = args.getString(0);
        number = number.replaceAll("#", "%23");

        if (!number.startsWith("tel:")) {
            number = String.format("tel:%s", number);
        }
        try {
            Intent intent = new Intent(isTelephonyEnabled() ? Intent.ACTION_CALL : Intent.ACTION_VIEW);
            intent.setData(Uri.parse(number));

            boolean bypassAppChooser = Boolean.parseBoolean(args.getString(1));
            if (bypassAppChooser) {
                intent.setPackage(getDialerPackage(intent));
            }
            cordova.getActivity().startActivity(intent);
            callbackContext.success();
        } catch (Exception e) {
            callbackContext.error("CouldNotCallPhoneNumber");
        }
    }

    private boolean isTelephonyEnabled() {
        TelephonyManager tm = (TelephonyManager) cordova.getActivity().getSystemService(Context.TELEPHONY_SERVICE);
        return tm != null && tm.getPhoneType() != TelephonyManager.PHONE_TYPE_NONE;
    }

    private String getDialerPackage(Intent intent) {
        PackageManager packageManager = (PackageManager) cordova.getActivity().getPackageManager();
        List activities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);

        for (int i = 0; i < activities.size(); i++) {
            if (activities.get(i).toString().toLowerCase().contains("com.android.server.telecom")) {
                return "com.android.server.telecom";
            }
            if (activities.get(i).toString().toLowerCase().contains("com.android.phone")) {
                return "com.android.phone";
            } else if (activities.get(i).toString().toLowerCase().contains("call")) {
                return activities.get(i).toString().split("[ ]")[1].split("[/]")[0];
            }
        }
        return "";
    }
}
