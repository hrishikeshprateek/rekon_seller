package com.reckon.reckonorders.NewDesign.NewModals;

import com.reckon.reckonorders.Base.BaseModel;

public class MenuModal extends BaseModel {
    public MenuModal(String menuId, int menuImage, String menuName) {
        this.menuId = menuId;
        this.menuImage = menuImage;
        this.menuName = menuName;
    }

    String menuId;

    public String getMenuId() {
        return menuId;
    }

    public void setMenuId(String menuId) {
        this.menuId = menuId;
    }

    public int getMenuImage() {
        return menuImage;
    }

    public void setMenuImage(int menuImage) {
        this.menuImage = menuImage;
    }

    public String getMenuName() {
        return menuName;
    }

    public void setMenuName(String menuName) {
        this.menuName = menuName;
    }

    int menuImage;
    String menuName;
}
