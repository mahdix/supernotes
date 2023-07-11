package com.mahdix.supernotes;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


/*
TODO:
- UI as a separate app
- Persistent DB
- Package structure
- Unit tests
*/

@SpringBootApplication
public class App 
{
    public static void main( String[] args ) {
        SpringApplication.run(App.class, args);
    }
}
