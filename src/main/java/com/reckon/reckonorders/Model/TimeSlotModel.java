package com.reckon.reckonorders.Model;

/**
 * Created by Manvendra Kumar Singh on 20/01/2019.
 */

public class TimeSlotModel {
    private String date,time,color="blue";
    public TimeSlotModel(String date, String time) {
        this.date = date;
        this.time = time;
    }
    public String getDate() {
        return date != null ? date : "";
    }
    public String getTime() {
        return time != null ? time : "";
    }
    public String getColor() { return color; }

    public void setColor(String color) { this.color = color; }

}
