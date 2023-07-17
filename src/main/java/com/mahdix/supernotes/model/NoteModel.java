package com.mahdix.supernotes.model;

import java.util.List;

public class NoteModel {
    private long id;
    private String title;
    private String body;
    private String sharedUsers;


    public NoteModel(long id, String title, String body, String sharedUsers) {
        this.id = id;
        this.title = title;
        this.body = body;
        this.sharedUsers = sharedUsers;
    }

    public long getId() {
        return id;
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

    public String getSharedUsers() {
        return sharedUsers;
    }

    public void setSharedUsers(String sharedUsers) {
        this.sharedUsers = sharedUsers;
    }
}
