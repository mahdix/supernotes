import * as React from "react";
import {useEffect, useState} from "react";
import {Login} from "./Login";
import {MyNotes} from "./MyNotes";


export const Application = () => {
    const [currentUser, setCurrentUser] = useState<string | undefined>(undefined);
    const [loginDone, setLoginDone] = useState(false);

    useEffect(() => {
        fetch('/user')
            .then(response => response.text())
            .then(data => {
                if ( data !== "") {
                    setCurrentUser(data)
                }
            });
    }, [])

    useEffect(() => {
        fetch('/user')
            .then(response => response.text())
            .then(data => {
                if ( data !== "") {
                    console.log("setting current user")
                    setCurrentUser(data)
                }
            });
    }, [loginDone])

    const onLoginSuccess = () => {
        setLoginDone(true);
    }

    return <>
        {currentUser === undefined && <Login onLoginSuccess={onLoginSuccess}/>}
        {currentUser !== undefined && <MyNotes />}
    </>;

}