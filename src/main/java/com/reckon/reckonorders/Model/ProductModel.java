package com.reckon.reckonorders.Model;
/*
 * Created by Manvendra Kumar Singh on 26/01/2019.
 */

import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.reckon.reckonorders.Utils.ReckonUtils;

import org.json.JSONArray;

public class ProductModel extends ViewModel {
    private String ProductRateA;
    private String ProductMfgComp;
    private MutableLiveData<Integer> ProductItemCount;
    private String ProductRefNumber;
    private String ProductStockType;
    private String ProductMrp;
    private String Productpacking;
    private String ProductCode;
    private String Productbarcode;
    private String ProductPRate;
    private String ProductStock;
    private String ProductName;
    private String Scheme;
    private String schemeAmt;
    private String imageUrl;
    private String SCName;
    private String Remark;
    private String Amt;
    private String Tax;
    private boolean IsStockExist;
    private double Rating = 0;
    private String Distributor;
    private String productCount = "0";

    public String getFQty() {
        return FQty;
    }

    public void setFQty(String FQty) {
        this.FQty = FQty;
    }

    private String FQty = "0";



    private String ProductImage;
    private JSONArray quantityList = new JSONArray();
    private int productId;
    private String isSchemeSelected;
    private String ProductRate;
    private String ProductSalt;
    private String ProductIGroup;
    private int currentStock;
    private String ShowBrand;
    private String ShowBarcode;
    private String ShowRefNo;
    private boolean ShowIGroup;
    private String ShowPack;
    private boolean ShowSalt;
    private int productIdCol;
    private String ProductDQty;
    private String invoiceQty;
    private String balanceQty;
    private int itemCount;
    private String numberOfOrder;
    private String daysAgoOrder = "";
    private String qtyOrdered = "";
    private String FCode;
    private String FLicNo;
    private boolean ShowStock = false;
    private boolean ShowScheme = false;
    private boolean ShowRate = false;
    private boolean ShowMrp = false;
    private int isStockistActive = 0;
    private String ActiveText = "";
    private String SchQty;

    private String DiscAmtCart;
    private String Disc2PerCart;
    private String Disc1PerCart;
    private String Disc1AmtCart;
    private String DFQTYCart;
    private String Disc2AmtCart;
    private String RefNumber = "";

    public String getAcCode() {
        return AcCode;
    }

    public void setAcCode(String acCode) {
        AcCode = acCode;
    }

    private String AcCode;


    public String getDescription() {
        return Description;
    }

    public void setDescription(String description) {
        Description = description;
    }

    private String Description = "";




    public String getTotalDiscCart() {
        return ReckonUtils.nonNullNotEmptyString(totalDiscCart)? ReckonUtils.roundTwoDecimals(totalDiscCart) :"0" ;
    }

    public void setTotalDiscCart(String totalDiscCart) {
        this.totalDiscCart = totalDiscCart;
    }

    private String totalDiscCart;



    public String getDiscAmtCart() {
        return ReckonUtils.nonNullNotEmptyString(DiscAmtCart)? ReckonUtils.roundTwoDecimals(DiscAmtCart) :"0";
    }

    public void setDiscAmtCart(String discAmtCart) {
        DiscAmtCart = discAmtCart;
    }

    public String getDisc2PerCart() {
        return Disc2PerCart!=null?Disc2PerCart :"";
    }

    public void setDisc2PerCart(String disc2PerCart) {
        Disc2PerCart = disc2PerCart;
    }

    public String getDisc1PerCart() {
        return Disc1PerCart!=null?Disc1PerCart:"";
    }

    public void setDisc1PerCart(String disc1PerCart) {
        Disc1PerCart = disc1PerCart;
    }

    public String getDisc1AmtCart() {
        return ReckonUtils.nonNullNotEmptyString(Disc1AmtCart)? ReckonUtils.roundTwoDecimals(Disc1AmtCart) :"0" ;
    }

    public void setDisc1AmtCart(String disc1AmtCart) {
        Disc1AmtCart = disc1AmtCart;
    }

    public String getDFQTYCart() {
        return DFQTYCart!=null?DFQTYCart:"";
    }

    public void setDFQTYCart(String DFQTYCart) {
        this.DFQTYCart = DFQTYCart;
    }

    public String getDisc2AmtCart() {
        return ReckonUtils.nonNullNotEmptyString(Disc2AmtCart)? ReckonUtils.roundTwoDecimals(Disc2AmtCart) :"0" ;
    }

    public void setDisc2AmtCart(String disc2AmtCart) {
        Disc2AmtCart = disc2AmtCart;
    }

    public String getNetAmtCart() {
        return ReckonUtils.nonNullNotEmptyString(NetAmtCart)? ReckonUtils.roundTwoDecimals(NetAmtCart) :"0";
    }

    public void setNetAmtCart(String netAmtCart) {
        NetAmtCart = netAmtCart;
    }

    public String getItemSchAmtCart() {
        return ReckonUtils.nonNullNotEmptyString(ItemSchAmtCart)? ReckonUtils.roundTwoDecimals(ItemSchAmtCart) :"0" ;
    }

    public void setItemSchAmtCart(String itemSchAmtCart) {
        ItemSchAmtCart = itemSchAmtCart;
    }

    public String getTaxAmtCart() {
        return ReckonUtils.nonNullNotEmptyString(TaxAmtCart)? ReckonUtils.roundTwoDecimals(TaxAmtCart) :"0" ;
    }

    public void setTaxAmtCart(String taxAmtCart) {
        TaxAmtCart = taxAmtCart;
    }

    public String getDoRemarkCart() {
        return DoRemarkCart!=null?DoRemarkCart:"";
    }

    public void setDoRemarkCart(String doRemarkCart) {
        DoRemarkCart = doRemarkCart;
    }

    public String getDiscPerCart() {
        return DiscPerCart!=null?DiscPerCart:"";
    }

    public void setDiscPerCart(String discPerCart) {
        DiscPerCart = discPerCart;
    }

    private String NetAmtCart;
    private String ItemSchAmtCart;
    private String TaxAmtCart;
    private String DoRemarkCart;
    private String DiscPerCart;

    public String getRefNumber() {
        return RefNumber;
    }

    public void setRefNumber(String refNumber) {
        RefNumber = refNumber;
    }



    public String getSchQty() {
        return SchQty;
    }

    public void setSchQty(String schQty) {
        SchQty = schQty;
    }

    public String getDSchQty() {
        return DSchQty;
    }

    public void setDSchQty(String DSchQty) {
        this.DSchQty = DSchQty;
    }

    private String DSchQty;

    public int getIsStockistActive() {
        return isStockistActive;
    }

    public void setIsStockistActive(int isStockistActive) {
        this.isStockistActive = isStockistActive;
    }

    public String getActiveText() {
        return ActiveText;
    }

    public void setActiveText(String activeText) {
        ActiveText = activeText;
    }


    public boolean isShowStock() {
        return ShowStock;
    }

    public void setShowStock(boolean showStock) {
        ShowStock = showStock;
    }

    public boolean isShowScheme() {
        return ShowScheme;
    }

    public void setShowScheme(boolean showScheme) {
        ShowScheme = showScheme;
    }

    public boolean isShowRate() {
        return ShowRate;
    }

    public void setShowRate(boolean showRate) {
        ShowRate = showRate;
    }

    public boolean isShowMrp() {
        return ShowMrp;
    }

    public void setShowMrp(boolean showMrp) {
        ShowMrp = showMrp;
    }


    public String getFCode() {
        return FCode;
    }

    public void setFCode(String FCode) {
        this.FCode = FCode;
    }

    public String getFLicNo() {
        return FLicNo;
    }

    public void setFLicNo(String FLicNo) {
        this.FLicNo = FLicNo;
    }


    public String getNumberOfOrder() {
        return numberOfOrder;
    }

    public void setNumberOfOrder(String numberOfOrder) {
        this.numberOfOrder = numberOfOrder;
    }

    public String getDaysAgoOrder() {
        return daysAgoOrder;
    }

    public void setDaysAgoOrder(String daysAgoOrder) {
        this.daysAgoOrder = daysAgoOrder;
    }

    public String getQtyOrdered() {
        return qtyOrdered;
    }

    public void setQtyOrdered(String qtyOrdered) {
        this.qtyOrdered = qtyOrdered;
    }


    public double getRating() {
        return Rating;
    }

    public void setRating(double rating) {
        Rating = rating;
    }


    public String getDistributor() {
        return Distributor;
    }

    public void setDistributor(String distributor) {
        Distributor = distributor;
    }


    public MutableLiveData<Integer> getProductItemCount() {
        if (ProductItemCount == null) {
            ProductItemCount = new MutableLiveData<Integer>();
        }
        return ProductItemCount;
    }

    public void setProductItemCount(MutableLiveData<Integer> productItemCount) {
        ProductItemCount = productItemCount;
    }

    //    private MutableLiveData<Integer> productCount;


    public String getProductImage() {
        return ProductImage;
    }

    public void setProductImage(String productImage) {
        ProductImage = productImage;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }


    public String getIsSchemeSelected() {
        return isSchemeSelected;
    }

    public void setIsSchemeSelected(String isSchemeSelected) {
        this.isSchemeSelected = isSchemeSelected;
    }


    public String getProductRate() {
        return ReckonUtils.nonNullNotEmptyString(ProductRate)? ReckonUtils.roundTwoDecimals(ProductRate) :"0" ;
    }

    public void setProductRate(String productRate) {
        ProductRate = productRate;
    }


    public String getProductSalt() {
        return ProductSalt;
    }

    public void setProductSalt(String productSalt) {
        ProductSalt = productSalt;
    }

    public String getProductIGroup() {
        return ProductIGroup;
    }

    public void setProductIGroup(String productIGroup) {
        ProductIGroup = productIGroup;
    }


    public String getShowBrand() {
        return ShowBrand;
    }

    public void setShowBrand(String showBrand) {
        ShowBrand = showBrand;
    }

    public String getShowBarcode() {
        return ShowBarcode;
    }

    public void setShowBarcode(String showBarcode) {
        ShowBarcode = showBarcode;
    }

    public String getShowRefNo() {
        return ShowRefNo;
    }

    public void setShowRefNo(String showRefNo) {
        ShowRefNo = showRefNo;
    }

    public boolean getShowIGroup() {
        return ShowIGroup;
    }

    public void setShowIGroup(boolean showIGroup) {
        ShowIGroup = showIGroup;
    }

    public String getShowPack() {
        return ShowPack;
    }

    public void setShowPack(String showPack) {
        ShowPack = showPack;
    }

    public boolean getShowSalt() {
        return ShowSalt;
    }

    public void setShowSalt(boolean showSalt) {
        ShowSalt = showSalt;
    }


    public int getCurrentStock() {
        return currentStock;
    }

    public void setCurrentStock(int currentStock) {
        this.currentStock = currentStock;
    }

    public String getProductDQty() {
        return ProductDQty;
    }

    public void setProductDQty(String productDQty) {
        ProductDQty = productDQty;
    }


    public String getInvoiceQty() {
        return invoiceQty;
    }

    public void setInvoiceQty(String invoiceQty) {
        this.invoiceQty = invoiceQty;
    }

    public String getBalanceQty() {
        return balanceQty;
    }

    public void setBalanceQty(String balanceQty) {
        this.balanceQty = balanceQty;
    }


    public String getProductRateA() {
        return ReckonUtils.nonNullNotEmptyString(ProductRateA)? ReckonUtils.roundTwoDecimals(ProductRateA) :"0" ;
    }

    public void setProductRateA(String productRateA) {
        ProductRateA = productRateA;
    }

    public String getProductMfgComp() {
        return ProductMfgComp;
    }

    public void setProductMfgComp(String productMfgComp) {
        ProductMfgComp = productMfgComp;
    }

    public String getProductRefNumber() {
        return ProductRefNumber;
    }

    public void setProductRefNumber(String productRefNumber) {
        ProductRefNumber = productRefNumber;
    }

    public String getProductStockType() {
        return ProductStockType;
    }

    public void setProductStockType(String productStockType) {
        ProductStockType = productStockType;
    }

    public String getProductMrp() {
        return ProductMrp;
    }

    public void setProductMrp(String productMrp) {
        ProductMrp = productMrp;
    }

    public String getProductpacking() {
        return Productpacking;
    }

    public void setProductpacking(String productpacking) {
        Productpacking = productpacking;
    }

    public String getProductCode() {
        return ProductCode;
    }

    public void setProductCode(String productCode) {
        ProductCode = productCode;
    }

    public String getProductbarcode() {
        return Productbarcode;
    }

    public void setProductbarcode(String productbarcode) {
        Productbarcode = productbarcode;
    }

    public String getProductPRate() {
        return ProductPRate;
    }

    public void setProductPRate(String productPRate) {
        ProductPRate = productPRate;
    }

    public String getProductStock() {
        return ProductStock;
    }

    public void setProductStock(String productStock) {
        ProductStock = productStock;
    }

    public String getProductName() {
        return ProductName;
    }

    public void setProductName(String productName) {
        ProductName = productName;
    }


    public String getScheme() {
        return Scheme;
    }

    public void setScheme(String scheme) {
        Scheme = scheme;
    }

    public int getItemCount() {
        return itemCount;
    }

    public void setItemCount(int itemCount) {
        this.itemCount = itemCount;
    }


//    public MutableLiveData<Integer> getPCount() {
//        if (productCount == null) {
//            productCount = new MutableLiveData<Integer>();
//            productCount.setValue(0);
//        }
//        return productCount;
//    }
//
//    public void incrementProductCount() {
//        productCount.setValue(productCount.getValue() + 1);
//    }
//
//    public void decrementProductCount() {
//        productCount.setValue(productCount.getValue() - 1);
//    }

    public String getProductCount() {
        return productCount;
    }

    public void setProductCount(String productCount) {
        this.productCount = productCount;
    }

    public int getProductIdCol() {
        return productIdCol;
    }

    public void setProductIdCol(int productIdCol) {
        this.productIdCol = productIdCol;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getSCName() {
        return SCName;
    }

    public void setSCName(String SCName) {
        this.SCName = SCName;
    }

    public String getRemark() {
        return Remark;
    }

    public void setRemark(String remark) {
        Remark = remark;
    }

    public String getAmt() {
        return ReckonUtils.nonNullNotEmptyString(Amt)? ReckonUtils.roundTwoDecimals(Amt) :"0" ;
    }

    public void setAmt(String amt) {
        Amt = amt != null && !amt.isEmpty() ? amt : "0";
    }

    public JSONArray getQuantityList() {
        return quantityList != null ? quantityList : new JSONArray();
    }

    public void setQuantityList(JSONArray quantityList) {
        this.quantityList = quantityList;
    }

    public String getSchemeAmt() {
        return ReckonUtils.nonNullNotEmptyString(schemeAmt)? ReckonUtils.roundTwoDecimals(schemeAmt) :"0" ;
    }

    public void setSchemeAmt(String schemeAmt) {
        this.schemeAmt = schemeAmt != null && !schemeAmt.isEmpty() ? schemeAmt : "0";
    }

    public String getTax() {
        return ReckonUtils.nonNullNotEmptyString( Tax)? ReckonUtils.roundTwoDecimals(Tax) :"0";
    }

    public void setTax(String tax) {
        Tax = tax;
    }

    public boolean isStockExist() {
        return IsStockExist;
    }

    public void setStockExist(boolean stockExist) {
        IsStockExist = stockExist;
    }
}
