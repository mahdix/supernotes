import {useEffect, useState} from "react";
import {Note} from "./Note";


export const MyNotes = (props: {}) => {
    const [currentUser, setCurrentUser] = useState<string | undefined>(undefined);
    const [notes, setNotes] = useState<any>();

    const newNote = () => {
        const requestOptions = {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(
                {
                    id: -1,
                    title: "untitled note",
                    body: "",
                    sharedUsers: ""
                })
        };

        fetch('/note', requestOptions)
            .then(response => response.text())
            .then(data => {
                if (data === "auth fail") {
                    alert("Update failed!")
                } else {
                    alert("note created!")
                    refreshNotes();
                }
            });
    }

    const logout = () => {
        fetch('/logout')
            .then(response => response.text())
            .then(data => {
                window.location.reload();
            });
    }

    const refreshNotes = () => {
        fetch('/user')
            .then(response => response.text())
            .then(data => {
                if (data !== "") {
                    setCurrentUser(data)
                }
            });

        fetch('/myNotes')
            .then(response => response.json())
            .then(data => {
                console.log("settings notes to ", data)
                setNotes(data);
            });
    }

    useEffect(() => {
        refreshNotes();
    }, [])

    return <>
        <div>
            {notes !== undefined && notes.map((note: any, idx: number) => <Note key={note.id} note={note} onChange={note1 => {
                setNotes([...notes.slice(0, idx), note1, ...notes.slice(idx + 1)])
            }
            }/>)}
        </div>
        <br />
        <button onClick={newNote}>new note</button>
        <br />
        <button onClick={logout}>logout</button>
    </>
}