package com.mahdix.supernotes;


import com.mahdix.supernotes.data.User;
import com.mahdix.supernotes.data.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class Controller {
    @Autowired
    private UserRepository userRepository;

//    @PostMapping(value = "/login")
//    public String login(String user, String password) {
//    }

    @GetMapping(value = "/users")
    public List<String> getUsers() {
        return userRepository.findAll().stream().map(User::getUsername).toList();
    }
}
