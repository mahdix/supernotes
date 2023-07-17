package com.mahdix.supernotes;


import com.mahdix.supernotes.data.*;
import com.mahdix.supernotes.model.NoteModel;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class Controller {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NoteRepository noteRepository;

    @Autowired
    private SharesRepository sharesRepository;

    @PostMapping(value = "/login")
    public String login(String user, String password, HttpSession session) {
        var matches = userRepository.findAllByUsernameAndPassword(user, password);
        if ( matches.size() == 1 ) {
            session.setAttribute("user_id", matches.get(0).getId());
            return "success";
        }

        return "failure";
    }

    @PostMapping(value = "/register")
    public String register(String user, String password) {
        User u = new User(user, password);
        userRepository.save(u);
        return "success";
    }

    @PostMapping(value = "/note")
    public String createOrUpdateNote(Long id, String title, String contents, HttpSession session) {
        var userId = session.getAttribute("user_id");
        if ( userId != null ) {
            var user = userRepository.findById((Long)userId).get();
            var notes  = noteRepository
                .findById(id);

            if ( notes.isPresent() ) {
                var note = notes.get();
                note.setBody(contents);
                noteRepository.save(note);
                return "updated";
            } else {
                var note = new Note(title, contents, user.getId());
                noteRepository.save(note);
                return "created";
            }
        }

        return "auth fail";
    }

    //TODO: ensure user is authenticated
    @PostMapping(value = "/share")
    public String shareNote(Long noteId, String userName) {
        var user = userRepository.findFirstByUsername(userName);
        var share = new Shares(noteId, user.getId());
        sharesRepository.save(share);
        return "shared";
    }

    @GetMapping(value = "/myNotes")
    public List<NoteModel> getMyNotes(HttpSession session) {
        var userId = session.getAttribute("user_id");
        assert userId != null;

        var notes = noteRepository.findAllByOwnerUserId((Long)userId);

        return notes.stream().map(note -> {
            var shared = sharesRepository.findAllByNoteId(note.getId());
            var users = userRepository
                .findAllByIdIn(shared.stream().map(Shares::getUserId).toList());
            return new NoteModel(
                note.getId(),
                note.getTitle(),
                note.getBody(),
                users.stream().map(x -> x.getUsername()).toList()
            );
        }).toList();
    }


    @GetMapping(value = "/users")
    public List<String> getUsers() {
        return userRepository.findAll().stream().map(User::getUsername).toList();
    }
}
