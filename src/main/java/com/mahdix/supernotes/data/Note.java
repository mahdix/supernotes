package com.mahdix.supernotes.data;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Entity
public class Note {
    @Id
    private Long id;
    private String title;
    private String body;
    private Long ownerUserId;

    public Note(String title, String body, Long ownerUserId) {
        this.title = title;
        this.body = body;
        this.ownerUserId = ownerUserId;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public Long getOwnerUserId() {
        return ownerUserId;
    }

    public void setOwnerUserId(Long ownerUserId) {
        this.ownerUserId = ownerUserId;
    }
}
