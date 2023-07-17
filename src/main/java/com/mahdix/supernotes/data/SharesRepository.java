package com.mahdix.supernotes.data;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SharesRepository extends JpaRepository<Shares, Long> {
    List<Shares> findAllByNoteId(long noteId);
    List<Shares> findAllByUserId(long userId);
}
