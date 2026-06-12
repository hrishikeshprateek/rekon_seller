package com.reckon.reckonorders.NewDesign.NewModals;

import com.reckon.reckonorders.Base.BaseModel;

public class TestimonialModal extends BaseModel {
    String Author_name;
    String Writing_Date;
    String Description;
    String Rating;
    String Author_Organisation;


    public String getAuthor_Organisation() {
        return Author_Organisation;
    }

    public void setAuthor_Organisation(String author_Organisation) {
        Author_Organisation = author_Organisation;
    }



    public String getAuthor_name() {
        return Author_name;
    }

    public void setAuthor_name(String author_name) {
        Author_name = author_name;
    }

    public String getWriting_Date() {
        return Writing_Date;
    }

    public void setWriting_Date(String writing_Date) {
        Writing_Date = writing_Date;
    }

    public String getDescription() {
        return Description;
    }

    public void setDescription(String description) {
        Description = description;
    }

    public String getRating() {
        return Rating;
    }

    public void setRating(String rating) {
        Rating = rating;
    }



    public TestimonialModal(String author_name, String writing_Date, String description, String rating,String Author_Org) {
        Author_name = author_name;
        Writing_Date = writing_Date;
        Description = description;
        Rating = rating;
        Author_Organisation=Author_Org;
    }


}
