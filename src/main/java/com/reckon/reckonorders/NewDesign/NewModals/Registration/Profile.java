package com.reckon.reckonorders.NewDesign.NewModals.Registration;

import com.reckon.reckonorders.Model.ImageModel;

import java.util.ArrayList;

public class Profile {
    private String GSTNUMBER;
    private ArrayList<ImageModel> GSTIMAGEPATH;
    private ArrayList<ImageModel> DLIMAGEPATH;

    public ArrayList<ImageModel> getDL2IMAGEPATH() {
        return DL2IMAGEPATH;
    }

    public void setDL2IMAGEPATH(ArrayList<ImageModel> DL2IMAGEPATH) {
        this.DL2IMAGEPATH = DL2IMAGEPATH;
    }

    private ArrayList<ImageModel> DL2IMAGEPATH;
    private ArrayList<ImageModel> FLIMAGEPATH;
    private String DLNO2;
    private String DLNO1;
    private String STATE;
    private String MOBILENO;
    private String PINCODE;
    private String NAME;
    private int CUID;
    private String FOODLICNO;
    private String AREA;
    private String CITY;

    private String ADDRESS1;
    private String ADDRESS2;

    public String getDL1IMAGEURL() {
        return DL1IMAGEURL;
    }

    public void setDL1IMAGEURL(String DL1IMAGEURL) {
        this.DL1IMAGEURL = DL1IMAGEURL;
    }

    public String getDL2IMAGEURL() {
        return DL2IMAGEURL;
    }

    public void setDL2IMAGEURL(String DL2IMAGEURL) {
        this.DL2IMAGEURL = DL2IMAGEURL;
    }

    public String getGST1IMAGEURL() {
        return GST1IMAGEURL;
    }

    public void setGST1IMAGEURL(String GST1IMAGEURL) {
        this.GST1IMAGEURL = GST1IMAGEURL;
    }

    public String getFL1IMAGEURL() {
        return FL1IMAGEURL;
    }

    public void setFL1IMAGEURL(String FL1IMAGEURL) {
        this.FL1IMAGEURL = FL1IMAGEURL;
    }

    private String DL1IMAGEURL;
   private String DL2IMAGEURL;
   private String GST1IMAGEURL;
   private String FL1IMAGEURL;


    public void setGSTNUMBER(String gSTNUMBER) {
        this.GSTNUMBER = gSTNUMBER;
    }

    public String getGSTNUMBER() {
        return GSTNUMBER!=null?GSTNUMBER:"";
    }

    public void setGSTIMAGEPATH(ArrayList<ImageModel> GSTIMAGEPATH) {
        this.GSTIMAGEPATH = GSTIMAGEPATH;
    }

    public ArrayList<ImageModel> getGSTIMAGEPATH() {
        return GSTIMAGEPATH!=null?GSTIMAGEPATH:new ArrayList<>();
    }

    public void setDLIMAGEPATH(ArrayList<ImageModel> DLIMAGEPATH) {
        this.DLIMAGEPATH = DLIMAGEPATH;
    }

    public ArrayList<ImageModel> getDLIMAGEPATH() {
        return DLIMAGEPATH!=null?DLIMAGEPATH:new ArrayList<>();
    }

    public void setFLIMAGEPATH(ArrayList<ImageModel> FLIMAGEPATH) {
        this.FLIMAGEPATH = FLIMAGEPATH;
    }

    public ArrayList<ImageModel> getFLIMAGEPATH() {
        return FLIMAGEPATH!=null?FLIMAGEPATH:new ArrayList<>();
    }


    public void setDLNO2(String dLNO2) {
        this.DLNO2 = dLNO2;
    }

    public String getDLNO2() {
        return DLNO2;
    }


    public void setDLNO1(String dLNO1) {
        this.DLNO1 = dLNO1;
    }

    public String getDLNO1() {
        return DLNO1!=null?DLNO1:"";
    }

    public void setSTATE(String sTATE) {
        this.STATE = sTATE;
    }

    public String getSTATE() {
        return STATE!=null?STATE:"";
    }

    public void setMOBILENO(String mOBILENO) {
        this.MOBILENO = mOBILENO;
    }

    public String getMOBILENO() {
        return MOBILENO!=null?MOBILENO:"";
    }

    public void setPINCODE(String pINCODE) {
        this.PINCODE = pINCODE;
    }

    public String getPINCODE() {
        return PINCODE!=null?PINCODE:"";
    }

    public void setNAME(String nAME) {
        this.NAME = nAME;
    }

    public String getNAME() {
        return NAME!=null?NAME:"";
    }

    public void setCUID(int cUID) {
        this.CUID =cUID;
    }

    public int getCUID() {
        return CUID;
    }

    public void setFOODLICNO(String fOODLICNO) {
        this.FOODLICNO = fOODLICNO;
    }

    public String getFOODLICNO() {
        return FOODLICNO!=null?FOODLICNO:"";
    }

    public void setAREA(String aREA) {
        this.AREA = aREA;
    }

    public String getAREA() {
        return AREA;
    }

    public void setCITY(String cITY) {
        this.CITY = cITY;
    }

    public String getCITY() {
        return CITY!=null?CITY:"";
    }


    public void setADDRESS1(String aDDRESS1) {
        this.ADDRESS1 = aDDRESS1;
    }

    public String getADDRESS1() {
        return ADDRESS1;
    }

    public void setADDRESS2(String aDDRESS2) {
        this.ADDRESS2 = aDDRESS2;
    }

    public String getADDRESS2() {
        return ADDRESS2;
    }

    @Override
    public String toString() {
        return
                "Profile{" +
                        "GSTNUMBER = '" + GSTNUMBER + '\'' +
                        ",DLIMAGEPATH = '" + DLIMAGEPATH + '\'' +
                        ",FLIMAGEPATH = '" + FLIMAGEPATH + '\'' +
                        ",GSTIMAGEPATH = '" + GSTIMAGEPATH + '\'' +
                        ",DLNO2 = '" + DLNO2 + '\'' +
                        ",DLNO1 = '" + DLNO1 + '\'' +
                        ",STATE = '" + STATE + '\'' +
                        ",MOBILENO = '" + MOBILENO + '\'' +
                        ",PINCODE = '" + PINCODE + '\'' +
                        ",NAME = '" + NAME + '\'' +
                        ",CUID = '" + CUID + '\'' +
                        ",FOODLICNO = '" + FOODLICNO + '\'' +
                        ",AREA = '" + AREA + '\'' +
                        ",CITY = '" + CITY + '\'' +
                        ",ADDRESS1 = '" + ADDRESS1 + '\'' +
                        ",ADDRESS2 = '" + ADDRESS2 + '\'' +
                        "}";
    }
}