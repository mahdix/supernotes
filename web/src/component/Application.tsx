import * as React from "react";
import {useEffect, useState} from "react";


export const Application = () => {
    const [data, setData] = useState();

    useEffect(() => {
        fetch('/users')
            .then(response => response.json())
            .then(data => setData(data));
    }, [])

    return <div> main app: {data}</div>
}