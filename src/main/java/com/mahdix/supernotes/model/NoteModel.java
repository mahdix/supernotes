package com.mahdix.supernotes.model;

import java.util.List;

public class NoteModel {
    private long id;
    private String title;
    private String body;
    private List<String> sharedUsers;


    public NoteModel(long id, String title, String body, List<String> sharedUsers) {
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

    public List<String> getSharedUsers() {
        return sharedUsers;
    }

    public void setSharedUsers(List<String> sharedUsers) {
        this.sharedUsers = sharedUsers;
    }
}
