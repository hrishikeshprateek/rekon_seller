package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONException;
import org.json.JSONObject;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

public class AddDistFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;

    @BindView(R.id.ed_distributor_name)
    EditText edDistributorName;
    @BindView(R.id.ed_contact_number)
    EditText edDistributorMobile;
    @BindView(R.id.Add_Distributor_submit_fl)
    FrameLayout submitBtn;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_add, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        getBundle();
        setupUI();
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        try {
            submitBtn.setBackgroundColor(getResources().getColor(R.color.grey));
            submitBtn.setClickable(false);
            checkValidation(edDistributorName);
            checkValidation(edDistributorMobile);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void checkValidation(EditText editText) {
        editText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                if (edDistributorName.getText().length() > 0 && edDistributorMobile.getText().length() > 0) {
                    submitBtn.setBackgroundColor(getResources().getColor(R.color.btn_color));
                    submitBtn.setClickable(true);
                } else {
                    submitBtn.setBackgroundColor(getResources().getColor(R.color.grey));
                    submitBtn.setClickable(false);
                }
            }

            @Override
            public void afterTextChanged(Editable editable) {
            }
        });
    }


    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
        }
    }

    @OnClick({R.id.Add_Distributor_submit_fl})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.Add_Distributor_submit_fl:
                addRequestForDistributor();
                break;
        }
    }

    private void addRequestForDistributor() {
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(getActivity(), Constant.USER_ID_CU));
            jsonObject.put("firm_name", edDistributorName.getText());
            jsonObject.put("mobile", edDistributorMobile.getText());
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(),
                    getApiClientByPost().addRequestForDistributor(String.valueOf(jsonObject)),
                    Constant.SEND_REQUEST_FOR_DISTRIBUTOR, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 0) {
            JSONObject jsonObject = new JSONObject(result);
            if (jsonObject.has("status")) {
                edDistributorName.getText().clear();
                edDistributorName.setFocusable(true);
                edDistributorName.requestFocus();
                edDistributorMobile.getText().clear();
                Toast.makeText(getActivity(), jsonObject.getString("message"), Toast.LENGTH_LONG).show();
            } else
                Toast.makeText(getActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
        } else
            Toast.makeText(getActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
    }
}
