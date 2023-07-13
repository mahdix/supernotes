package com.mahdix.supernotes;


import com.mahdix.supernotes.data.User;
import com.mahdix.supernotes.data.UserRepository;
import com.mahdix.supernotes.model.Note;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class Controller {
    @Autowired
    private UserRepository userRepository;

//    @PostMapping(value = "/login")
//    public String login(String user, String password) {
//    }
//
//    @PostMapping(value = "/register")
//    public String register(String user, String password) {
//    }
//
//    @PostMapping(value = "/note")
//    public String createOrUpdateNote(String title, String contents) {
//    }
//
//    @PostMapping(value = "/share")
//    public String shareNote(String title, String userName) {
//    }
//
//    @GetMapping(value = "/myNotes")
//    public List<Note> getMyNotes() {
//    }


    @GetMapping(value = "/users")
    public List<String> getUsers() {
        return userRepository.findAll().stream().map(User::getUsername).toList();
    }
}
