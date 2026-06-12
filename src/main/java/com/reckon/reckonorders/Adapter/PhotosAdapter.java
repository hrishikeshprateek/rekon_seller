package com.reckon.reckonorders.Adapter;
/**
 * Created by Manvendra Kumar Singh on 20/07/2019.
 */

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.reckon.reckonorders.Fragment.Home.UploadPrescriptionFragment;
import com.reckon.reckonorders.Model.ImageModel;
import com.reckon.reckonorders.NewDesign.NewFragments.UserProfileFragment;
import com.reckon.reckonorders.NewDesign.RegisterFragmentWithStep;
import com.reckon.reckonorders.Others.Constant.Constant;
import com.reckon.reckonorders.R;
import com.reckon.reckonorders.Utils.ReckonUtils;

import java.util.ArrayList;
import java.util.Objects;

public class PhotosAdapter extends RecyclerView.Adapter<PhotosAdapter.PhotosViewHolder> {
    private UploadPrescriptionFragment uploadPrescriptionFragment;
    private RegisterFragmentWithStep registerFragmentWithStep;
    private UserProfileFragment profileFragment;
    private ArrayList<String> data;
    private ArrayList<ImageModel> imageList;

    String imgInString, baseUrl, size, img;
    int uriType = 0;
    private ArrayList<Bitmap> arrayList;
    String type;
    int j, selectedPos = 0;

    public PhotosAdapter(ArrayList<ImageModel> imageUrl, Fragment fragment, String _docType, int j, int uriType) {
        this.imageList = imageUrl;
        this.type = _docType;
        this.uriType = uriType;
        this.j = j;

        if (fragment instanceof UploadPrescriptionFragment) {
            this.uploadPrescriptionFragment = (UploadPrescriptionFragment) fragment;
        } else if (fragment instanceof RegisterFragmentWithStep) {
            this.registerFragmentWithStep = (RegisterFragmentWithStep) fragment;
        }
        //   this.arrayList = arrayListData;
    }

    public PhotosAdapter(UserProfileFragment profileFragment, String baseUrl, ArrayList<ImageModel> imageUrl, String _docType, int j, int uriType) {
        this.imageList = imageUrl;
        this.uriType = uriType;
        this.profileFragment = profileFragment;
        this.type = _docType;
        this.baseUrl = baseUrl;
        this.j = j;
    }


    @NonNull
    @Override
    public PhotosViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new PhotosViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.item_photo, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull final PhotosViewHolder holder, @SuppressLint("RecyclerView") final int position) {
        try {
            int f = (j - (data != null ? data.size() : imageList.size()));
            if (position == 0) {
                if ((data != null ? data.size() : imageList.size()) >= j) {
                    holder.SelectImageLayout.setVisibility(View.GONE);
                } else {
                    holder.maxImageText.setText(f + " More" + "\n" + "(optional)");
                    holder.SelectImageLayout.setVisibility(View.VISIBLE);
                }
            } else {
                holder.SelectImageLayout.setVisibility(View.GONE);
            }
            holder.SelectImageLayout.setOnClickListener(v -> {
                selectedPos = data != null ? data.size() - 1 : imageList.size() - 1;
                if (profileFragment != null) {
                    profileFragment.showImagePicker(type);
                } else {
                    registerFragmentWithStep.showImagePicker(type);
                }
            });
            if ((data != null ? data.size() : imageList.size()) != 0) {
                if (uploadPrescriptionFragment != null) {
                    Glide.with(uploadPrescriptionFragment.requireActivity()).load(data.get(position)).apply(RequestOptions.placeholderOf(R.drawable.photo_upload)).into(holder.imgPhoto);
                } else {
                    if (imageList != null) {
                        if (!imageList.get(position).getId().isEmpty() && imageList.get(position).getId() != null) {
                            img = data != null ? data.get(position) : imageList.get(position).getImageUrl();
                            if (baseUrl == null || baseUrl.isEmpty())
                                baseUrl = Constant.IMAGE_UPLOAD_URL;
                            if(!img.contains("file:///") && !img.contains("http")){
                                img = baseUrl + img;
                            }
                        } else {
                            img = ReckonUtils.compressImage(data != null ? data.get(position) : imageList.get(position).getImageUrl(), registerFragmentWithStep != null ? registerFragmentWithStep.getActivity() : profileFragment.getActivity());
                            size = ReckonUtils.printFileSize(img);
                        }
                    } else {
                        img = ReckonUtils.compressImage(data != null ? data.get(position) : imageList.get(position).getImageUrl(), registerFragmentWithStep != null ? registerFragmentWithStep.getActivity() : profileFragment.getActivity());
                        size = ReckonUtils.printFileSize(img);
                    }
                    Glide.with(Objects.requireNonNull(registerFragmentWithStep != null ? registerFragmentWithStep.getActivity() : profileFragment.getActivity())).asBitmap().load(img).dontAnimate().into(new CustomTarget<Bitmap>() {
                        @Override
                        public void onResourceReady(@NonNull Bitmap resource, @Nullable Transition<? super Bitmap> transition) {
                            holder.imgPhoto.setImageBitmap(resource);
                            imgInString = ReckonUtils.encodedImage(resource);
                            if (uriType == 0) {
                                if (registerFragmentWithStep != null){
                                    registerFragmentWithStep.setList(imgInString, type);
                                }
                            } else if (imageList.get(position).getId().equals("")) {
                                if (profileFragment != null){
                                    profileFragment.setList(imgInString, type);
                                } else if (registerFragmentWithStep != null){
                                    registerFragmentWithStep.setList(imgInString, type);
                                }
                            }
                        }
                        @Override
                        public void onLoadCleared(@Nullable Drawable placeholder) {
                        }
                    });
                }
            }
            holder.cross_img.setOnClickListener(v ->{
                System.out.println("");
                removePrescription(position);
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public int getItemCount() {
        return data != null ? data.size() : imageList.size();
    }

    static class PhotosViewHolder extends RecyclerView.ViewHolder {
        ImageView imgPhoto, imgGroupPhoto;
        TextView cross_img, maxImageText;
        CardView SelectImageLayout;

        PhotosViewHolder(View itemView) {
            super(itemView);
            maxImageText = itemView.findViewById(R.id.maxImageText);
            SelectImageLayout = itemView.findViewById(R.id.SelectImageLayout);
            imgPhoto = itemView.findViewById(R.id.imgPhoto);
            imgGroupPhoto = itemView.findViewById(R.id.imgGroupPhoto);
            cross_img = itemView.findViewById(R.id.cross_img);
        }
    }
    private void removePrescription(int position) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(profileFragment != null ? profileFragment.getActivity() : uploadPrescriptionFragment != null ? uploadPrescriptionFragment.getActivity() : registerFragmentWithStep.getActivity());
        alertDialogBuilder.setMessage(type.equalsIgnoreCase(Constant.DL) || type.equalsIgnoreCase(Constant.DL2) ? R.string.want_to_remove_drug_lic_doc : type.equalsIgnoreCase(Constant.GST) ? R.string.want_to_remove_gst_doc : type.equalsIgnoreCase(Constant.FL) ? R.string.want_to_remove_food_lic_doc : R.string.want_to_remove_prescription);
        alertDialogBuilder.setPositiveButton("Yes", (arg0, arg1) -> {
            if (profileFragment != null) {
                profileFragment.deleteList(type, position);
            }
            if (registerFragmentWithStep != null) {
                registerFragmentWithStep.deleteList(type, position);
            }
            notifyDataSetChanged();
            if (uploadPrescriptionFragment != null && data != null && data.size() == 0) {
                uploadPrescriptionFragment.image_bg.setVisibility(View.VISIBLE);
                uploadPrescriptionFragment._rvPhoto.setVisibility(View.GONE);
            } else {
                if (imageList != null && imageList.size() == 0) {
                    if (type.equalsIgnoreCase(Constant.DL)) {
                        if (registerFragmentWithStep != null) {
                            registerFragmentWithStep.image_bg.setVisibility(View.VISIBLE);
                            registerFragmentWithStep._rvPhoto.setVisibility(View.GONE);
                        } else {
                            profileFragment.binding.dlBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                            profileFragment.binding.dlBgImage.uploadText.setText(profileFragment.getResources().getString(R.string.you_can_select_upto) + j);
                        }
                    } else if (type.equalsIgnoreCase(Constant.DL2)) {
                        if (registerFragmentWithStep != null) {
                            registerFragmentWithStep.imageBG2.setVisibility(View.VISIBLE);
                            registerFragmentWithStep._rvPhotoDL2.setVisibility(View.GONE);
                        } else {
                            profileFragment.binding.dl2BgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                            profileFragment.binding.dl2BgImage.uploadText.setText(profileFragment.getResources().getString(R.string.you_can_select_upto) + j);
                        }
                    } else if (type.equalsIgnoreCase(Constant.GST)) {
                        if (registerFragmentWithStep != null) {
                            registerFragmentWithStep.image_bg_GSTN.setVisibility(View.VISIBLE);
                            registerFragmentWithStep._rvPhoto_GSTN.setVisibility(View.GONE);
                        } else {
                            profileFragment.binding.gstBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                            profileFragment.binding.gstBgImage.uploadText.setText(profileFragment.getResources().getString(R.string.you_can_select_upto) + j);
                        }
                    } else {
                        if (registerFragmentWithStep != null) {
                            registerFragmentWithStep.image_bg_FL.setVisibility(View.VISIBLE);
                            registerFragmentWithStep._rvPhoto_FL.setVisibility(View.GONE);
                        } else {
                            profileFragment.binding.flBgImage.bgUploadLayout.setVisibility(View.VISIBLE);
                            profileFragment.binding.flBgImage.uploadText.setText(profileFragment.getResources().getString(R.string.you_can_select_upto) + j);
                        }
                    }
                }
            }
        });
        alertDialogBuilder.setNegativeButton("No", (dialog, which) -> {
        });
        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
        if (profileFragment != null) {
            alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(profileFragment.getActivity().getResources().getColor(R.color.black));
            alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(profileFragment.getActivity().getResources().getColor(R.color.black));
        } else if (uploadPrescriptionFragment != null) {
            alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(uploadPrescriptionFragment.getActivity().getResources().getColor(R.color.black));
            alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(uploadPrescriptionFragment.getActivity().getResources().getColor(R.color.black));
        } else {
            alertDialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(registerFragmentWithStep.getActivity().getResources().getColor(R.color.black));
            alertDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(registerFragmentWithStep.getActivity().getResources().getColor(R.color.black));

        }

    }

}
