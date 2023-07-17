import {useState} from "react";


export const Note = (props: { note: any, onChange: (note: any) => void }) => {
    const [editMode, setEditMode] = useState(false);

    const save = () => {
        const requestOptions = {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(
                {
                    id: props.note.id,
                    title: props.note.title,
                    body: props.note.body,
                    sharedUsers: props.note.sharedUsers
                })
        };

        fetch('/note', requestOptions)
            .then(response => response.text())
            .then(data => {
                console.log("got response:", data);
                if (data === "auth fail") {
                    alert("Update failed!")
                } else {
                    alert("note updated!")
                }
            });

        setEditMode(false);
    }

    return <>
        <div>Title: <input type={"text"} value={props.note.title} onChange={(e) => props.onChange({
            ...props.note,
            title: e.target.value
        })} disabled={!editMode}/></div>
        <div>Contents: <input type={"text"} value={props.note.body} onChange={(e) => props.onChange({
            ...props.note,
            body: e.target.value
        })} disabled={!editMode}/></div>
        <div>Shared with: <input type={"text"} value={props.note.sharedUsers} disabled={!editMode}
                                 onChange={(e) => props.onChange({
                                     ...props.note,
                                     sharedUsers: e.target.value
                                 })}/></div>
        {!editMode &&
            <button onClick={() => setEditMode(true)}>Edit</button>}
        {editMode &&
            <button onClick={save}>Save</button>
        }
        {editMode &&
            <button onClick={() => setEditMode(false)}>Cancel</button>
        }
    </>
}