package com.reckon.reckonorders.Fragment.Home;

import static com.reckon.reckonorders.NetworkAPI.API_Config.getApiClientByPost;

import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.content.res.AppCompatResources;
import androidx.cardview.widget.CardView;
import androidx.core.graphics.drawable.DrawableCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.reckon.reckonorders.Base.BaseFragment;
import com.reckon.reckonorders.Model.StoreDetailObjectModel;
import com.reckon.reckonorders.NetworkAPI.ConnectToRetrofit;
import com.reckon.reckonorders.NetworkAPI.RetrofitCallBackListener;
import com.reckon.reckonorders.NewDesign.NewAdapters.AreaOutletAdapter;
import com.reckon.reckonorders.NewDesign.NewMainActivity;
import com.reckon.reckonorders.NewDesign.NewModals.InvoiceModel;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;
import com.reckon.reckonorders.Utils.SharedPrefUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;

public class ReceiptDetailsFragment extends BaseFragment implements RetrofitCallBackListener {
    private RetrofitCallBackListener retrofitCallBackListener;
    private String receiptId = "", previousTitle = "";
    @BindView(R.id.receiptId)
    TextView receiptIdTv;

    @BindView(R.id.createdDateTv)
    TextView createdDateTv;
    @BindView(R.id.docDateTv)
    TextView docDateTv;
    @BindView(R.id.tvDocNumber)
    TextView tvDocNumber;
    @BindView(R.id.accountNameTv)
    TextView accountNameTv;
    @BindView(R.id.payModeTv)
    TextView payModeTv;
    @BindView(R.id.narrationTv)
    TextView narrationTv;
    @BindView(R.id.amountTv)
    TextView amountTv;
    @BindView(R.id.discAmountTv)
    TextView discAmountTv;


    @BindView(R.id.narrationLl)
    LinearLayout narrationLl;
    @BindView(R.id.disAmtRowRl)
    RelativeLayout disAmtRowRl;

    @BindView(R.id.outletRecycler)
    RecyclerView outletRecycler;

    @BindView(R.id.adjustmentLl)
    LinearLayout adjustmentLl;


    @BindView(R.id.orderDetailsLl)
    LinearLayout orderDetailsLl;

    @BindView(R.id.noRecordTV)
    TextView noRecordTV;

    @BindView(R.id.sendReminderCard)
    CardView sendReminderCard;
    @BindView(R.id.docRowRl)
    RelativeLayout docRowRl;
    @BindView(R.id.docDateRl)
    RelativeLayout docDateRl;

    private boolean isSalesMan;

    private StoreDetailObjectModel selectedPartyDataModel;
    private final Gson gson = new Gson();
    private ArrayList<InvoiceModel> billsList = new ArrayList<>();
    private boolean isShareEnabled = false;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_receipt_details, container, false);
        ButterKnife.bind(this, view);
        previousTitle = NewMainActivity.binding.appBarNewMain.pageName.getText().toString();
        retrofitCallBackListener = this;
        isSalesMan = getLicDetails() != null && getLicDetails().getRole().equalsIgnoreCase("SalesMan");
        ((NewMainActivity) getActivity()).setUpTitle(ReceiptDetailsFragment.this, getString(R.string.receipt_details));
        getBundle();
        setupUI();
        setTitle(view, getString(R.string.receipt_details).toUpperCase());
        return view;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        ((NewMainActivity) requireActivity()).setUpTitle(this, previousTitle);
    }

    private void setupUI() {
        try {
            getMyReceiptDetails(false);
            Drawable unwrappedDrawable = AppCompatResources.getDrawable(requireActivity(), R.drawable.ic_baseline_arrow_drop_down_24);
            Drawable wrappedDrawable = DrawableCompat.wrap(Objects.requireNonNull(unwrappedDrawable));
            DrawableCompat.setTint(wrappedDrawable, getSecondHeaderTextColor());
            unwrappedDrawable = AppCompatResources.getDrawable(requireActivity(), R.drawable.ic_baseline_arrow_drop_up_24);
            wrappedDrawable = DrawableCompat.wrap(Objects.requireNonNull(unwrappedDrawable));
            DrawableCompat.setTint(wrappedDrawable, getSecondHeaderTextColor());
//            deliveryCharges.setTextColor(getSecondHeaderTextColor());
            receiptIdTv.setTextColor(getSecondHeaderTextColor());
            createdDateTv.setTextColor(getSecondHeaderTextColor());
            docDateTv.setTextColor(getSecondHeaderTextColor());
            tvDocNumber.setTextColor(getSecondHeaderTextColor());
            accountNameTv.setTextColor(getSecondHeaderTextColor());
            payModeTv.setTextColor(getSecondHeaderTextColor());
            sendReminderCard.setOnClickListener(v -> {
                if(isSalesMan){
                    getMyReceiptDetails(true);
                }else{
                    Toast.makeText(requireActivity(), getResources().getString(R.string.workOnProgress), Toast.LENGTH_LONG).show();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void getBundle() {
        Bundle bundle = getArguments();
        if (bundle != null) {
            if (isSalesMan) {
                selectedPartyDataModel = gson.fromJson(getArguments().getString(Constant.PARTY), new TypeToken<StoreDetailObjectModel>() {
                }.getType());
            }
            receiptId = bundle.containsKey(Constant.ID) ? bundle.getString(Constant.ID) : "";

        }
    }

    private void getMyReceiptDetails(boolean showPDF) {
        try {
            isShareEnabled = showPDF;
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("lApkName", requireActivity().getPackageName());
            jsonObject.put("lid", receiptId);
            jsonObject.put("lLicNo", getLicDetails().getLicno());
            jsonObject.put("lSharePdf", String.valueOf(showPDF));
            jsonObject.put("device_id", SharedPrefUtils.getString(requireActivity(), Constant.DEVICE_ID));
            jsonObject.put("device_name", ReckonUtils.getDeviceName());
            jsonObject.put("cu_id", SharedPrefUtils.getString(requireActivity(), Constant.USER_ID_CU));
            jsonObject.put("v_code", SharedPrefUtils.getVersionCode(requireActivity()));
            jsonObject.put("version_name", SharedPrefUtils.getVersionName(requireActivity()));
            jsonObject.put("app_role", SharedPrefUtils.getString(requireActivity(), Constant.ROLE));
            new ConnectToRetrofit(retrofitCallBackListener, getActivity(), getApiClientByPost().GetReceiptDetails(String.valueOf(jsonObject)), Constant.RECEIPT_DETAILS, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void RetrofitCallBackListener(int code, String result, String action) throws JSONException {
        if (result != null && result.length() > 1) {
            if(isShareEnabled){
                try{
                    JSONObject jsonObject = new JSONObject(result);
                    boolean sharePDF = jsonObject.has("share_pdf") && jsonObject.getBoolean("share_pdf");
                    if (sharePDF && jsonObject.has("data")) {
                        JSONObject obj = jsonObject.getJSONObject("data");
                        String pdfLink = ReckonUtils.getJsonCheckedString(obj, "link", "");
                        String docName = ReckonUtils.getJsonCheckedString(obj, "doc_name", "receipt");
                        if (ReckonUtils.isPDFValid(pdfLink)) {
                            ReckonUtils.downloadAndSharePdf(pdfLink, requireActivity(), false, docName);
                        }else{
                            Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                        }
                    }else{
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                }catch (Exception e){
                    e.printStackTrace();
                    if (ReckonUtils.isPDFValid(result)) {
                        ReckonUtils.downloadAndSharePdf(result, requireActivity(), false, "receipt");
                    }else{
                        Toast.makeText(requireActivity(), getResources().getString(R.string.something_went_wrong), Toast.LENGTH_LONG).show();
                    }
                }
            }else{
                JSONObject jsonObject = new JSONObject(result);
                if (jsonObject.getBoolean("Status")) {
                    setMyOrderListData(jsonObject, action);
                }
            }
        }
    }

    private void setMyOrderListData(JSONObject jsonObject, String action) {
        try {
            JSONArray jsonArray1 = jsonObject.has("Receipt") ? jsonObject.getJSONArray("Receipt") : new JSONArray();
            if (jsonArray1.length() > 0) {

                JSONObject object = jsonArray1.getJSONObject(0);
                if (ReckonUtils.getJsonCheckedString(object, "id", "").isEmpty()) {
                    orderDetailsLl.setVisibility(View.GONE);
                    noRecordTV.setVisibility(View.VISIBLE);
                } else {
                    orderDetailsLl.setVisibility(View.VISIBLE);
                    noRecordTV.setVisibility(View.GONE);
                }
                receiptIdTv.setText("#00" + ReckonUtils.getJsonCheckedString(object, "id", ""));
                accountNameTv.setText(ReckonUtils.getJsonCheckedString(object, "acName", ""));
                createdDateTv.setText(ReckonUtils.getJsonCheckedString(object, "date", ""));
                docDateTv.setText(ReckonUtils.getJsonCheckedString(object, "docdt", ""));
                tvDocNumber.setText(ReckonUtils.getJsonCheckedString(object, "docno", ""));
                payModeTv.setText(ReckonUtils.getJsonCheckedString(object, "type", ""));
                String narration = ReckonUtils.getJsonCheckedString(object, "narration", "");
                if (!narration.isEmpty()) {
                    narrationTv.setText(narration);
                    narrationLl.setVisibility(View.VISIBLE);
                }
                String discAmt = ReckonUtils.getJsonCheckedString(object, "disc_amount", "");
                amountTv.setText(getLicDetails().getCurrency() + ReckonUtils.getJsonCheckedString(object, "amount", ""));
                discAmountTv.setText(getLicDetails().getCurrency() +discAmt );
                disAmtRowRl.setVisibility(ReckonUtils.nonNullNotEmptyString(discAmt)?View.VISIBLE:View.GONE);

                try {
                    JSONArray jsonArray = new JSONArray();
                    for (InvoiceModel item : billsList) {
                        JSONObject object1 = new JSONObject();
                        object1.put("bill_number", item.getEntryNo());
                        object1.put("amount", item.getAdjustmentAmount() != null ? item.getAdjustmentAmount() : item.getAmount());
                        object1.put("id", item.getKeyEntryNo());
                        jsonArray.put(object1);
                    }
                    object.put("adjustment_details", jsonArray);
                } catch (Exception e) {
                    e.printStackTrace();
                }

                if (!billsList.isEmpty()) {
                    billsList.clear();
                }
                JSONArray jsonArray = object.getJSONArray("Item");
                for (int i = 0; i < jsonArray.length(); i++) {
                    JSONObject obj = jsonArray.getJSONObject(i);
                    InvoiceModel model = new InvoiceModel();
                    model.setEntryNo(ReckonUtils.getJsonCheckedString(obj, "KeyNo", ""));
                    model.setAmount(ReckonUtils.getJsonCheckedString(obj, "amount", ""));
                    model.setId(ReckonUtils.getJsonCheckedString(obj, "id", ""));
                    model.setKeyEntryNo(ReckonUtils.getJsonCheckedString(obj, "billnumber", ""));
                    model.setDate(ReckonUtils.getJsonCheckedString(obj, "date", ""));
                    billsList.add(model);
                }
                adjustmentLl.setVisibility(billsList != null && !billsList.isEmpty() ? View.VISIBLE : View.GONE);
                outletRecycler.setAdapter(new AreaOutletAdapter(ReceiptDetailsFragment.this, billsList));
                docRowRl.setVisibility(tvDocNumber.getText().toString().trim().isEmpty() ? View.GONE : View.VISIBLE);
                docDateRl.setVisibility(docDateTv.getText().toString().trim().isEmpty() ? View.GONE : View.VISIBLE);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
