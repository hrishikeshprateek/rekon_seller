package com.reckon.reckonorders.Fragment.Home;

import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.SharedPrefUtils;
import com.reckon.reckonorders.Utils.StartActivityUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

public class ChangePasswordFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;

    @BindView(R.id.fragmentRegister_edtOldPassword)
    EditText _edtOldPassword;
    @BindView(R.id.fragmentRegister_edtPassword)
    EditText _edtPassword;
    @BindView(R.id.fragmentRegister_edtConfirmPass)
    EditText _edtConfirmPass;
    String Mobile_Number, Country_Code;

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_change_password, container, false);
        ButterKnife.bind(this, view);
        retrofitCallBackListener = this;
        setupBackButton(view);
        setupUI();
        return view;
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setupUI() {
        try {
            JSONArray jsonArray1 = new JSONArray(SharedPrefUtils.getList(getActivity(), Constant.USER_DATA_LIST));
            JSONObject jsonObject = jsonArray1.getJSONObject(0);
            Mobile_Number = jsonObject.has("LicNo") ? jsonObject.getString("LicNo") : "";
            Country_Code = jsonObject.has("CountryCode") ? jsonObject.getString("CountryCode") : "";
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @OnClick({R.id.fragmentRegister_frmChangePassword})
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.fragmentRegister_frmChangePassword:
                hitChangePasswordServices();
                break;
        }
    }

    private void hitChangePasswordServices() {
        try {
            if (_edtOldPassword.getText().toString().equalsIgnoreCase(""))
                Toast.makeText(getActivity(), getString(R.string.error_old_password_empty), Toast.LENGTH_SHORT).show();
            else if (_edtPassword.getText().toString().equalsIgnoreCase(""))
                Toast.makeText(getActivity(), getString(R.string.error_new_password_empty), Toast.LENGTH_SHORT).show();
            else if (_edtPassword.getText().length() < 6)
                Toast.makeText(getActivity(), getString(R.string.error_length_password), Toast.LENGTH_SHORT).show();
            else if (_edtConfirmPass.getText().toString().equalsIgnoreCase(""))
                Toast.makeText(getActivity(), getString(R.string.error_confirm_password_empty), Toast.LENGTH_SHORT).show();
            else if (!_edtPassword.getText().toString().equalsIgnoreCase(_edtConfirmPass.getText().toString()))
                Toast.makeText(getActivity(), getString(R.string.error_confirm_password), Toast.LENGTH_SHORT).show();
            else
                new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().postCreatePassword(requireActivity().getPackageName(),Mobile_Number, Country_Code, _edtPassword.getText().toString(), _edtOldPassword.getText().toString(), "0"), Constant.CREATE_PASSWORD, true);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    private void resetFieldAfterLogout() {
        SharedPrefUtils.removeLogout(getActivity());
        StartActivityUtils.toAccount(getActivity());
        getActivity().overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        getActivity().finish();
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        JSONObject jsonObject = new JSONObject(result);
        if (!jsonObject.getString("Status").equalsIgnoreCase("0")) {
            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();
            resetFieldAfterLogout();
        } else
            Toast.makeText(getActivity(), jsonObject.getString("Message"), Toast.LENGTH_SHORT).show();


    }
}
