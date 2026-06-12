package com.reckon.reckonorders.NewDesign.NewModals;

public class InvoiceModel {
    String invoiceType;
    String Id;
    String DueDate;
    String OverDue;
    String invoiceDate;
    String invoiceValue;
    String invoiceNumber;


    public String getTranType() {
        return TranType;
    }

    public void setTranType(String tranType) {
        TranType = tranType;
    }

    public String getOppBal() {
        return OppBal;
    }

    public void setOppBal(String oppBal) {
        OppBal = oppBal;
    }

    public String getTranFirm() {
        return TranFirm;
    }

    public void setTranFirm(String tranFirm) {
        TranFirm = tranFirm;
    }

    public String getEntryNo() {
        return EntryNo;
    }

    public void setEntryNo(String entryNo) {
        EntryNo = entryNo;
    }

    public String getDrAmt() {
        return DrAmt;
    }

    public void setDrAmt(String drAmt) {
        DrAmt = drAmt;
    }

    public String getTranNumber() {
        return TranNumber;
    }

    public void setTranNumber(String tranNumber) {
        TranNumber = tranNumber;
    }

    public String getTranId() {
        return TranId;
    }

    public void setTranId(String tranId) {
        TranId = tranId;
    }

    public String getCrAmt() {
        return CrAmt;
    }

    public void setCrAmt(String crAmt) {
        CrAmt = crAmt;
    }

    public String getDate() {
        return Date;
    }

    public void setDate(String date) {
        Date = date;
    }

    public String getRunningAmt() {
        return RunningAmt;
    }

    public void setRunningAmt(String runningAmt) {
        RunningAmt = runningAmt;
    }

    String TranType;
     String OppBal;
     String TranFirm;
     String EntryNo;
     String DrAmt;
     String TranNumber;
     String TranId;
     String CrAmt;
     String Date;
     String RunningAmt;
     String amount;

    public String getAdjustmentAmount() {
        return adjustmentAmount;
    }

    public void setAdjustmentAmount(String adjustmentAmount) {
        this.adjustmentAmount = adjustmentAmount;
    }

    String adjustmentAmount;

    public String getAmount() {
        return amount;
    }

    public void setAmount(String amount) {
        this.amount = amount;
    }


    public String getKeyEntryNo() {
        return KeyEntryNo;
    }

    public void setKeyEntryNo(String keyEntryNo) {
        KeyEntryNo = keyEntryNo;
    }

    String KeyEntryNo;

    public String getIsEntryRecord() {
        return isEntryRecord;
    }

    public void setIsEntryRecord(String isEntryRecord) {
        this.isEntryRecord = isEntryRecord;
    }

    String isEntryRecord;

    public String getAmountColor() {
        return amountColor!=null?amountColor:"#000000";
    }

    public void setAmountColor(String amountColor) {
        this.amountColor = amountColor;
    }

    String amountColor;



    public String getKeyEntrySrNo() {
        return KeyEntrySrNo;
    }

    public void setKeyEntrySrNo(String keyEntrySrNo) {
        KeyEntrySrNo = keyEntrySrNo;
    }

    String KeyEntrySrNo;


    public String getInvoiceDate() {
        return invoiceDate;
    }

    public void setInvoiceDate(String invoiceDate) {
        this.invoiceDate = invoiceDate;
    }

    public String getInvoiceValue() {
        return invoiceValue;
    }

    public void setInvoiceValue(String invoiceValue) {
        this.invoiceValue = invoiceValue;
    }

    public String getInvoiceNumber() {
        return invoiceNumber;
    }

    public void setInvoiceNumber(String invoiceNumber) {
        this.invoiceNumber = invoiceNumber;
    }





    public String getId() {
        return Id;
    }

    public void setId(String id) {
        Id = id;
    }

    public String getDueDate() {
        return DueDate;
    }

    public void setDueDate(String dueDate) {
        DueDate = dueDate;
    }

    public String getOverDue() {
        return OverDue;
    }

    public void setOverDue(String overDue) {
        OverDue = overDue;
    }

    public String getInvoiceType() {
        return invoiceType;
    }

    public void setInvoiceType(String invoiceType) {
        this.invoiceType = invoiceType;
    }


}
