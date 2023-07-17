package com.mahdix.supernotes.data;

import jakarta.persistence.Id;

public class Shares {
    @Id
    private Long id;

    private Long noteId;
    private Long userId;

    public Shares(Long noteId, Long userId) {
        this.id = id;
        this.noteId = noteId;
        this.userId = userId;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getNoteId() {
        return noteId;
    }

    public void setNoteId(Long noteId) {
        this.noteId = noteId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }
}
