package com.mahdix.supernotes;


import com.mahdix.supernotes.data.*;
import com.mahdix.supernotes.model.NoteModel;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@RestController
public class Controller {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NoteRepository noteRepository;

    @Autowired
    private SharesRepository sharesRepository;

    @GetMapping( value = "/user" )
    public String getUser(HttpSession session) {
        var currentUser = session.getAttribute("current_user");
        if ( currentUser == null ) {
            return "";
        }

        return (( User ) currentUser).getUsername();
    }

    @PostMapping( value = "/login" )
    public String login(@RequestBody Map<String, String> request, HttpSession session) {
        var user = request.get("user");
        var password = request.get("password");
        var matches = userRepository.findAllByUsernameAndPassword(user, password);
        if ( matches.size() == 1 ) {
            session.setAttribute("current_user", matches.get(0));
            return "success";
        }

        return "failure";
    }

    @PostMapping( value = "/register" )
    public String register(@RequestBody Map<String, String> request) {
        var user = request.get("user");
        var password = request.get("password");
        User u = new User(user, password);
        userRepository.save(u);
        return "success";
    }

    @PostMapping( value = "/note" )
    public String createOrUpdateNote(@RequestBody Map<String, String> request, HttpSession session) {
        Long id = Long.parseLong(request.get("id"));
        String title = request.get("title");
        String body = request.get("body");
        String sharedUsers = request.get("sharedUsers");

        var userObj = session.getAttribute("current_user");
        if ( userObj != null ) {
            var user = ( User ) userObj;
            var notes = noteRepository
                .findById(id);

            Note note;
            if ( notes.isPresent() ) {
                note = notes.get();
                note.setTitle(title);
                note.setBody(body);
                noteRepository.save(note);
            } else {
                note = new Note(title, body, user.getId());
                noteRepository.save(note);
            }

            var toShareWith = userRepository.findAllByUsernameIn(Arrays.stream(sharedUsers.split(",")).toList());
            var shares = sharesRepository.findAllByNoteId(note.getId());
            var alreadyShared = shares
                .stream()
                .map(x -> x.getUserId())
                .map(x -> userRepository.findById(x).get())
                .map(x -> x.getUsername())
                .toList();

            for ( var userNameToShareWith : toShareWith ) {
                if ( !alreadyShared.contains(userNameToShareWith.getUsername()) ) {
                    var share = new Shares(note.getId(), userNameToShareWith.getId());
                    sharesRepository.save(share);
                }
            }

            return "updated";
        }

        return "auth fail";
    }

    //TODO: ensure user is authenticated
    @PostMapping( value = "/share" )
    public String shareNote(Long noteId, String userName) {
        var user = userRepository.findFirstByUsername(userName);
        var share = new Shares(noteId, user.getId());
        sharesRepository.save(share);
        return "shared";
    }

    @GetMapping( value = "/logout" )
    public String logout(HttpSession session) {
        session.removeAttribute("current_user");
        return "";
    }

    @GetMapping( value = "/myNotes" )
    public List<NoteModel> getMyNotes(HttpSession session) {
        var userObj = session.getAttribute("current_user");

        if ( userObj == null ) {
            return Collections.emptyList();
        }

        var user = ( User ) userObj;

        var notes = noteRepository.findAllByOwnerUserId(user.getId());

        var shares = sharesRepository
            .findAllByUserId(user.getId())
            .stream().map(x -> x.getNoteId()).toList();

        var notesShared = noteRepository.findAllById(shares);

        return Stream.concat(notes.stream(), notesShared.stream()).map(note -> {
            var shared = sharesRepository.findAllByNoteId(note.getId());
            var users = userRepository
                .findAllByIdIn(shared.stream().map(Shares::getUserId).toList());
            return new NoteModel(
                note.getId(),
                note.getTitle(),
                note.getBody(),
                users.stream().map(x -> x.getUsername()).collect(Collectors.joining(","))
            );
        }).toList();
    }


    @GetMapping( value = "/users" )
    public List<String> getUsers() {
        return userRepository.findAll().stream().map(User::getUsername).toList();
    }
}
