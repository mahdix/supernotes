import {useState} from "react";


export const Login = (props: {onLoginSuccess: () => void}) => {
    const [userName, setUserName] = useState("");
    const [password, setPassword] = useState("");

    const doLogin = () => {
        const requestOptions = {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(
                {
                    user: userName,
                    password: password
                })
        };

        fetch('/login', requestOptions)
            .then(response => response.text())
            .then(data => {
                console.log("got response:", data);
                if ( data === "failure" ) {
                    alert("Login failed!")
                } else {
                    props.onLoginSuccess()
                }
            });
    }

    const doSignUp = () =>
    {
        const requestOptions = {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(
                {
                    user: userName,
                    password: password
                })
        };

        fetch('/register', requestOptions)
            .then(response => response.text())
            .then(data => {
                console.log("got response:", data);
                if ( data === "failure" ) {
                    alert("Sign-up failed!")
                } else {
                    alert("Sign-up done!")
                }
            });
    }

    return <>
        <h1>Login/Sign-Up</h1>
        User name:
        <input type={"text"} value={userName} onChange={event => setUserName(event.target.value)} />
        Password:
        <input type={"password"} value={password} onChange={event => setPassword(event.target.value)} />
        <button onClick={doLogin}>Login</button>
        <button onClick={doSignUp}>Sign Up</button>
    </>
}