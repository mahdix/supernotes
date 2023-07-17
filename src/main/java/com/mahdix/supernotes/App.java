package com.mahdix.supernotes;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


/*
TODO:
- UI as a separate app
- Persistent DB
- Package structure
- Unit tests
- Spring JPA
- better auth: salt hashing, 3rd party oauth2, ...
- use websockets
- note update: send delta, not the whole note contents
- Json data structure for api request/responses
- create proper services apart from controller
- response: return error code rather than strings
- use json for comm between fe and be
- error handling (e.g. getting invalid input for list of users to share with)
- support unshare
- can not share with yourself
- ensure user is auth.ed
- optimise: e.g. batch calls to db to get user/note/share info
*/

@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
