package com.reckon.reckonorders.NewDesign;


import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.IntentSenderRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProvider;
import androidx.navigation.NavController;
import androidx.navigation.NavDestination;
import androidx.navigation.Navigation;
import androidx.navigation.fragment.NavHostFragment;
import androidx.navigation.ui.AppBarConfiguration;
import androidx.navigation.ui.NavigationUI;

import com.google.android.gms.tasks.Task;
import com.google.android.material.navigation.NavigationView;
import com.google.android.material.snackbar.Snackbar;
import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.appupdate.AppUpdateOptions;
import com.google.android.play.core.install.InstallStateUpdatedListener;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.InstallStatus;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.reckon.reckonorders.Base.BaseActivity;
import com.reckon.reckonorders.Fragment.Home.CartFragment;
import com.reckon.reckonorders.Fragment.Home.DistributorDetailsScreen;
import com.reckon.reckonorders.Fragment.Home.HomeFragment;
import com.reckon.reckonorders.Fragment.Home.NewOrderFragment;
import com.reckon.reckonorders.Fragment.Home.PartyListingFragment;
import com.reckon.reckonorders.Fragment.Home.RecentOrderedProductsFragment;
import com.reckon.reckonorders.Model.ProductModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewFragments.AccountDetailsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.AccountStatementFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.AddBillsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.MyBillsFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.OutstandingBillWiseFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.OutstandingFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.ReceiptFragment;
import com.reckon.reckonorders.NewDesign.NewFragments.SaleVoucherFragment;
import com.reckon.reckonorders.NewDesign.ViewModel.MyViewModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.databinding.ActivityNewMainBinding;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;


public class NewMainActivity extends BaseActivity implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;

    private AppBarConfiguration mAppBarConfiguration;
    public static ActivityNewMainBinding binding;
    private TextView accountName, accountEmail;
    LinearLayout menuBgLL;
    private Bundle bundle;
    DrawerLayout drawer;
    NavController navController;
    private boolean isSalesMan;
    private boolean isAppInstallAvailable = false;
    private final int APP_UPDATE_REQUEST_CODE = 1230;
    private int updateRetryCount = 0;
    private int MAX_RETRY_COUNT = 2;
    private AppUpdateManager appUpdateManager;
    private InstallStateUpdatedListener installStateUpdatedListener;
    private ActivityResultLauncher<IntentSenderRequest> activityResultLauncher;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if(!SharedPrefUtils.getEnableScreenshot(this)){
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
        }
        binding = ActivityNewMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        setPackageManagerInfo();
        setUpUi();
        setStatusBarColor();
        checkForAppInstallAvailable();

    }

    private void checkForAppInstallAvailable() {
        activityResultLauncher = registerForActivityResult(new ActivityResultContracts.StartIntentSenderForResult(),
                result -> {
                    if (result.getResultCode() == RESULT_OK) {
                        updateRetryCount = 0;
                        //      log("Update flow failed! Result code: " + result.getResultCode());  // If the update is canceled or fails,  // you can request to start the update again.
                    } else {
                        // Update flow failed or was canceled
                        handleUpdateCancellation();
                    }
                });
        appUpdateManager = AppUpdateManagerFactory.create(this);
        if (isGooglePlayServicesAvailable(this)) {
            checkForUpdate();
            installStateUpdatedListener = state -> {
                Log.d("inAppUpdates", String.valueOf(state.installStatus()));
                if (state.installStatus() == InstallStatus.DOWNLOADING) {
                    long bytesDownloaded = state.bytesDownloaded();
                    long totalBytesToDownload = state.totalBytesToDownload();
                    Log.d("inAppUpdates", "bytesDownloaded " + bytesDownloaded + " / " + totalBytesToDownload);
                    // Update UI to show download progress.
                } else if (state.installStatus() == InstallStatus.DOWNLOADED) {
                    isAppInstallAvailable = true;
                    popupSnackbarForCompleteUpdate();
                    Log.d("inAppUpdates", "Update is downloaded and ready to install ");

                    // Notify the user and request installation.
                } else if (state.installStatus() == InstallStatus.INSTALLING) {
//                    isAppInstallAvailable = false;
                    Log.d("inAppUpdates", "Update is being installed");

                    // Update UI to show installation progress.
                } else if (state.installStatus() == InstallStatus.INSTALLED) {
//                    isAppInstallAvailable = false;
                    Log.d("inAppUpdates", "Update is installed");
                    if (appUpdateManager != null) {
                        appUpdateManager.unregisterListener(installStateUpdatedListener);
                    }
                    // Notify the user and perform any necessary actions.
                } else if (state.installStatus() == InstallStatus.FAILED) {
                    isAppInstallAvailable = false;
                    Log.d("inAppUpdates", "Update failed to install");
                    if (appUpdateManager != null) {
                        appUpdateManager.unregisterListener(installStateUpdatedListener);
                    }
                    // Notify the user and handle the error.
                }
            };
            System.out.println("==='===isAppUpdateAvailable'");

        } else {
            isAppInstallAvailable = false;
        }
    }

    private void checkForUpdate() {
        Task<AppUpdateInfo> appUpdateInfoTask = appUpdateManager.getAppUpdateInfo();
        appUpdateInfoTask.addOnSuccessListener(appUpdateInfo -> {
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE && SharedPrefUtils.getVersionCode(this) < appUpdateInfo.availableVersionCode()) {
                startUpdateFlow(appUpdateInfo);
            }
        });
    }

    private void startUpdateFlow(AppUpdateInfo appUpdateInfo) {
        try {
            appUpdateManager.registerListener(installStateUpdatedListener);
            appUpdateManager.startUpdateFlowForResult(appUpdateInfo, activityResultLauncher, AppUpdateOptions.newBuilder(SharedPrefUtils.getShowFlexibleUpdate(this) ? AppUpdateType.FLEXIBLE : AppUpdateType.IMMEDIATE)/*.setAllowAssetPackDeletion(true)*/.build());
        } catch (Exception e) {
            Log.d("inAppUpdates", "IntentSender.SendIntentException" + e);
        }
    }

    private void handleUpdateCancellation() {
        if (updateRetryCount < MAX_RETRY_COUNT) {
            updateRetryCount++;
            checkForUpdate();
        } else {
            this.finishAffinity();
            // Disable app functionality or show a persistent message
            // until the update is installed
        }
    }

    public void setHeader(String title, Boolean visibleState) {
        binding.appBarNewMain.pageName.setText(title);
        if (!visibleState)
            binding.appBarNewMain.tvWelcome.setVisibility(View.GONE);
    }

    // Displays the snackbar notification and call to action.
    private void popupSnackbarForCompleteUpdate() {
        Snackbar snackbar = Snackbar.make(findViewById(R.id.drawer_layout), "An update has just been downloaded.", Snackbar.LENGTH_INDEFINITE);
        snackbar.setAction("RESTART", view -> appUpdateManager.completeUpdate());
        snackbar.setActionTextColor(getResources().getColor(R.color.white));
        snackbar.show();
    }

    public void setStatusBarColor() {
        Window window = getWindow();
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        window.setStatusBarColor(getStatusBarColorOfApp());
        if (isLightIcon())
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
    }

    private void setUpUi() {
        retrofitCallBackListener = this;
        if (getPackageName().equalsIgnoreCase("com.reckon.unagretailers") || getPackageName().equalsIgnoreCase("com.reckon.unagsalesman")) {
            setHeaderColor("#3D5F7C", "#3D5F7C", false, "#ffffff", "#1E5FA6", "#3D5F7C");
        } else if (getPackageName().equalsIgnoreCase("com.reckon.sarvahithaayurvedalaya")) {
            setHeaderColor("#85a03c", "#85a03c", false, "#ffffff", "#1f6643", "#85a03c");
        } else if (getPackageName().equalsIgnoreCase("com.reckon.reckonretailers")) {
            setHeaderColor("#EA7B7E", "#EA7B7E", false, "#ffffff", "#EA7B7E", "#EA7B7E");
        }else if (getPackageName().equalsIgnoreCase("com.reckon.amareorder") || getPackageName().equalsIgnoreCase("com.reckon.amareretail")) {
            setHeaderColor("#0097b2", "#0097b2", false, "#ffffff", "#1E5FA6", "#0097b2");
        } else {
            setHeaderColor("#13A2DF", "#13A2DF", false, "#ffffff", "#1E5FA6", "#13A2DF");
        }
        binding.appBarNewMain.pageName.setTextColor(Color.parseColor("#ffffff"));
        binding.appBarNewMain.tvWelcome.setTextColor(Color.parseColor("#ffffff"));
        binding.appBarNewMain.imgCart.setColorFilter(Color.parseColor("#ffffff"));
        setUpViewModelObserver();
        setSupportActionBar(binding.appBarNewMain.toolbar1);

        isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        binding.appBarNewMain.appBar.setBackgroundColor(getStatusBarColorOfApp());
//        binding.appBarNewMain.toolbar1.setNavigationOnClickListener(new View.OnClickListener() {
//            @RequiresApi(api = Build.VERSION_CODES.Q)
//            @Override
//            public void onClick(View view) {
//                // Navigate somewhere
//               long id= view.getUniqueDrawingId();
//                Toast.makeText(NewMainActivity.this,String.valueOf(id), Toast.LENGTH_SHORT).show();
//            }
//        });
        drawer = binding.drawerLayout;
        NavigationView navigationView = binding.navView;
        // Passing each menu ID as a set of Ids because each
        // menu should be considered as top level destinations.
        boolean isSalesMan = getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        mAppBarConfiguration = new AppBarConfiguration.Builder(R.id.nav_home, R.id.nav_feedback, R.id.nav_profile, R.id.nav_my_bills, R.id.nav_order_history, R.id.nav_gallery, R.id.nav_slideshow, R.id.nav_cart, R.id.nav_notification, R.id.nav_settings, R.id.nav_Order_Entry, R.id.nav_receipt_book).setOpenableLayout(drawer).build();
        navController = Navigation.findNavController(this, R.id.nav_host_fragment_content_new_main);
        NavigationUI.setupActionBarWithNavController(this, navController, mAppBarConfiguration);
        NavigationUI.setupWithNavController(navigationView, navController);
        if (isSalesMan) {
            navigationView.getMenu().findItem(R.id.nav_profile).setVisible(false);
        } else {
            navigationView.getMenu().findItem(R.id.nav_receipt_book).setVisible(false);
        }
        binding.appBarNewMain.imgCart.setOnClickListener(v -> Navigation.findNavController(NewMainActivity.this, R.id.nav_host_fragment_content_new_main).navigate(R.id.nav_cart));
        accountName = navigationView.getHeaderView(0).findViewById(R.id.Account_Name);
        accountEmail = navigationView.getHeaderView(0).findViewById(R.id.Account_Email);
        ImageView imageView = navigationView.getHeaderView(0).findViewById(R.id.imageView);
        imageView.setImageResource(ReckonUtils.getAppIcon(this));

//        accountName.setTextColor(Color.parseColor(DrawerTextColor));
//        accountEmail.setTextColor(Color.parseColor(DrawerTextColor));
//        menuBgLL.setBackgroundColor(Color.parseColor(StatusBarColor));
        menuBgLL = navigationView.getHeaderView(0).findViewById(R.id.menu_top_bg);
        if (getUserProfile(NewMainActivity.this) != null) {
            accountName.setText(getUserProfile(NewMainActivity.this).getNAME());
            accountName.setTypeface(null, Typeface.BOLD);
            accountEmail.setText("+" + getUserProfile(NewMainActivity.this).getMOBILENO());
            accountEmail.setTypeface(null, Typeface.BOLD);
        } else
            ReckonUtils.logout(NewMainActivity.this);

        Fragment currentFragment = getSupportFragmentManager().findFragmentById(R.id.nav_host_fragment_content_new_main);
        if (isSalesMan && getSelectedStoreDetailsFromPicker() != null) {
            binding.appBarNewMain.tvWelcome.setVisibility(View.VISIBLE);
            binding.appBarNewMain.iconContainer.setVisibility(isSalesMan && (currentFragment instanceof HomeFragment || currentFragment instanceof NavHostFragment) ? View.GONE : View.GONE);
            binding.appBarNewMain.iconText.setText(getSelectedStoreDetailsFromPicker().getFirstChar());
            String arrOfStr[] = getSelectedStoreDetailsFromPicker().getName().split(" ");
            binding.appBarNewMain.tvWelcome.setText(arrOfStr.length > 1 ? (arrOfStr[0] + " " + arrOfStr[1]) : arrOfStr[0]);
        } else {
            binding.appBarNewMain.tvWelcome.setVisibility(View.GONE);
        }

        navigationView.getMenu().findItem(R.id.nav_logout).setOnMenuItemClickListener(menuItem -> {
            logoutApi();
            return true;
        });
        String versionName = getString(R.string.version) + " - " + SharedPrefUtils.getVersionName(this) + "(" + SharedPrefUtils.getVersionCode(this) + ")";
        binding.versionNameTv.setText(versionName);

        navigationView.getMenu().findItem(R.id.nav_Order_Entry).setOnMenuItemClickListener(item -> {
            //   orderEntryClickHandling(navController,Constant.NEW_ORDER, bundle);
            if (getLicDetails().getRole().equalsIgnoreCase("SalesMan")) {
//                ArrayList<StoreDetailObjectModel> storeListData = getStoreListData();
                navigateToPartyFragmentListing(Constant.NEW_ORDER);
     /*           if (storeListData.size() == 1) {
                    navigateToPartyFragmentListing(Constant.NEW_ORDER);
                } else if (storeListData.size() > 1) {
                    navigateToPartyFragmentListing(Constant.FIRM);
                }*/
            } else {
                if (getLicDetails().getRetailerType().equalsIgnoreCase(Constant.MULTI)) {
                    Bundle bundle = new Bundle();
                    bundle.putString(Constant.FROM, Constant.NEW_ORDER);
                    navController.navigate(R.id.nav_common_listing, bundle);
                } else
                    navController.navigate(R.id.nav_Order_Entry);
            }
            drawer.close();
            return true;
        });
        navigationView.getMenu().findItem(R.id.nav_outstanding).setOnMenuItemClickListener(item -> {
            Bundle bundle = new Bundle();
            orderEntryClickHandling(navigationView.getRootView(), Constant.OUTSTANDING, bundle, navController);
            drawer.close();
            return true;
        });
    /*    navigationView.getMenu().findItem(R.id.nav_receipt_book).setOnMenuItemClickListener(item -> {
            Bundle bundle = new Bundle();
            orderEntryClickHandling(navController, Constant.OUTSTANDING, bundle);
            drawer.close();
            return true;
        });*/
        navigationView.getMenu().findItem(R.id.nav_notification).setOnMenuItemClickListener(item -> {
            Toast.makeText(NewMainActivity.this, getString(R.string.workOnProgress), Toast.LENGTH_SHORT).show();
            return false;
        });
        navigationView.getMenu().findItem(R.id.nav_settings).setOnMenuItemClickListener(item -> {
            Toast.makeText(NewMainActivity.this, getString(R.string.workOnProgress), Toast.LENGTH_SHORT).show();
            return false;
        });
        navigationView.getMenu().findItem(R.id.nav_feedback).setOnMenuItemClickListener(item -> {
            Toast.makeText(NewMainActivity.this, getString(R.string.workOnProgress), Toast.LENGTH_SHORT).show();
            return false;
        });
        navigationView.getMenu().findItem(R.id.nav_my_bills).setOnMenuItemClickListener(item -> {
            Navigation.findNavController(NewMainActivity.this, R.id.nav_host_fragment_content_new_main).navigate(R.id.nav_my_bills);
            drawer.close();
            return true;
        });
        setUpColorTheme();
    }

    private void logoutApi() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", getPackageName());
            jsonObject.put("device_id", SharedPrefUtils.getString(this, Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(this, Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(this));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(this));
            jsonObject.put("app_role", SharedPrefUtils.getString(this, Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, this, getApiClientByPost().LogOff(String.valueOf(jsonObject)), Constant.LOGOUT, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    private void setUpColorTheme() {
        accountName.setTextColor(getHeaderTextColor());
        accountEmail.setTextColor(getHeaderTextColor());
        menuBgLL.setBackgroundColor(getStatusBarColorOfApp());
    }

    private void navigateToPartyFragmentListing(String page) {
        Bundle bundle = new Bundle();
        bundle.putString(Constant.FROM, page);
        navController.navigate(R.id.navPartyLisingFragment, bundle);
    }

    private void setUpViewModelObserver() {
        MyViewModel myViewModel = new ViewModelProvider(this).get(MyViewModel.class);
        // Create the observer which updates the UI.
        final Observer<ArrayList<ProductModel>> productObserver = productModels -> {
        };
        // Observe the LiveData, passing in this activity as the LifecycleOwner and the observer.
        myViewModel.getProducts().observe(this, productObserver);
    }


    @Override
    public boolean onSupportNavigateUp() {
        navController = Navigation.findNavController(this, R.id.nav_host_fragment_content_new_main);
        NavDestination currentDestination = navController.getCurrentDestination();
        if (currentDestination.getId() == R.id.nav_order_confirmation) {
            navController.navigate(R.id.nav_to_home, bundle);
            return true;
        }
//        else if (currentDestination.getId() == R.id.nav_ProductDetailsFragment) {
//            NewOrderFragment fragment = new NewOrderFragment();
//            if(!Constant.bundle.isEmpty())
//            {
//                if(Constant.bundle.getString(Constant.SCREEN_NAME).equals(Constant.PRODUCT_DETAILS))
//                {
//                    Constant.bundle.putString(Constant.SCREEN_NAME, Constant.PRODUCT);
//                }
//            }
//            fragment.setBundleOfProduct(bundle);
//            onBackPressed();
//            return true;
//        }
        else {
            return super.onSupportNavigateUp() || NavigationUI.navigateUp(navController, mAppBarConfiguration);
        }
    }

    public void setUpTitle(Fragment fragment, String Title) {
        if (fragment instanceof HomeFragment || Title.equalsIgnoreCase(Constant.HOME)) {
            binding.appBarNewMain.pageName.setText(Title);
            binding.appBarNewMain.iconContainer.setVisibility(isSalesMan ? View.GONE : View.GONE);
            binding.appBarNewMain.tvWelcome.setVisibility(isSalesMan ? View.VISIBLE : View.GONE);
            return;
        }
        if (fragment instanceof NewOrderFragment) {
            binding.appBarNewMain.pageName.setText(Title);
            binding.appBarNewMain.imgCart.setVisibility(View.VISIBLE);
//            binding.appBarNewMain.iconContainer.setVisibility(isSalesMan ? View.VISIBLE : View.GONE);
            binding.appBarNewMain.tvWelcome.setVisibility(isSalesMan ? View.VISIBLE : View.GONE);
        } else if (fragment instanceof CartFragment || fragment instanceof AddBillsFragment || fragment instanceof ReceiptFragment || fragment instanceof AccountDetailsFragment || fragment instanceof PartyListingFragment ||
                fragment instanceof OutstandingBillWiseFragment || fragment instanceof OutstandingFragment || fragment instanceof AccountFilterScreen || fragment instanceof ProductFilterScreen ||
                fragment instanceof AccountStatementFragment || fragment instanceof SaleVoucherFragment || fragment instanceof DistributorDetailsScreen || fragment instanceof MyBillsFragment) {
            binding.appBarNewMain.pageName.setText(Title);
            binding.appBarNewMain.iconContainer.setVisibility(View.GONE);
            binding.appBarNewMain.tvWelcome.setVisibility(View.GONE);
            binding.appBarNewMain.imgCart.setVisibility(View.INVISIBLE);
        } else {
            binding.appBarNewMain.iconContainer.setVisibility(View.GONE);
            binding.appBarNewMain.pageName.setText(Title);
            if (isSalesMan) {
                binding.appBarNewMain.tvWelcome.setVisibility(View.VISIBLE);
                binding.appBarNewMain.imgCart.setVisibility(View.VISIBLE);
            } else if (fragment instanceof RecentOrderedProductsFragment) {
                binding.appBarNewMain.tvWelcome.setVisibility(View.GONE);
                binding.appBarNewMain.imgCart.setVisibility(View.VISIBLE);
            }
        }
    }

    @Override
    protected void onDestroy() {
        if (appUpdateManager != null) {
            appUpdateManager.unregisterListener(installStateUpdatedListener);
        }
        super.onDestroy();
    }

    @Override
    protected void onResume() {
        super.onResume();
        appUpdateManager.getAppUpdateInfo().addOnSuccessListener(appUpdateInfo -> {
            // If the update is downloaded but not installed,
            // notify the user to complete the update.
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
                // If an in-app update is already running, resume the update.
                appUpdateManager.startUpdateFlowForResult(appUpdateInfo, activityResultLauncher, AppUpdateOptions.newBuilder(SharedPrefUtils.getShowFlexibleUpdate(this) ? AppUpdateType.FLEXIBLE : AppUpdateType.IMMEDIATE).build());
            }
            if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                popupSnackbarForCompleteUpdate();
            }

        });
    }

    private void setPackageManagerInfo() {
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            String versionName = pInfo.versionName;
            int versionCode = pInfo.versionCode;
            SharedPrefUtils.setVersionCode(this, (int) getLongVersionCode(pInfo));
            SharedPrefUtils.setVersionName(this, versionName);
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    private long getLongVersionCode(PackageInfo pInfo) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return pInfo.getLongVersionCode();
        } else {
            return pInfo.versionCode;
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            ReckonUtils.logout(NewMainActivity.this);
            Toast.makeText(this, getResources().getString(R.string.logout), Toast.LENGTH_LONG).show();
        }else{
            ReckonUtils.logout(NewMainActivity.this);
        }
    }
}

