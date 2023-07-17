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
*/

@SpringBootApplication
public class App 
{
    public static void main( String[] args ) {
        SpringApplication.run(App.class, args);
    }


}
