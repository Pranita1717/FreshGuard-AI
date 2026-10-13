package com.freshguardai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class InventoryUpdateRequest {

    @NotBlank(message = "Action is required (INCREASE, DECREASE, SET, REMOVE_EXPIRED)")
    private String action;

    private Integer quantityChange;

    private Integer newQuantity;

    private String reason;

    public InventoryUpdateRequest() {
    }

    public InventoryUpdateRequest(String action, Integer quantityChange, Integer newQuantity, String reason) {
        this.action = action;
        this.quantityChange = quantityChange;
        this.newQuantity = newQuantity;
        this.reason = reason;
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public Integer getQuantityChange() {
        return quantityChange;
    }

    public void setQuantityChange(Integer quantityChange) {
        this.quantityChange = quantityChange;
    }

    public Integer getNewQuantity() {
        return newQuantity;
    }

    public void setNewQuantity(Integer newQuantity) {
        this.newQuantity = newQuantity;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }
}
