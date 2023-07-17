# supernotes
A simple app to create and share text notes (Front-end + Back-end)

# Run locally

The app uses a local sqlite database. Make sure you have JDK 17 and Maven CLI installed.

1. `git clone` the repository
2. `cd` into the repository root.
3. `mvn spring-boot:run`

# Using the app

- You can visit `http://localhost:8082/index.html` to see home page.
- You can login via "test1/test1" or "mahdi/123" or you can sign up as a new user.
- After login, you will see a list of your notes (and notes shared with you).
- For each note, you can edit the note by "Edit" button where you can change title or body of the note or share it by entering username of the recipient.

# Improvement

There are a ton of places for improvement both on front-end side and back-end side. Some examples:
- Make UI as a separate app rather than a module embedded within back-end app.
- Persistent DB: To make app more scalable, switch to a scalable DB server like MySQL.
- Package structure: As the use case is very limited at the moment, the packages are not structured ideally. They should be separated as "MVC" pattern with services being placed in their own package.
- Unit tests: No unit tests exist. They should be added.
- Better auth: Passwords are stored planintext. Usually they should be hashed with salt. We can even use 3rd party tools for auth (like Login via Google).
- use websockets to provide real-time updates: Right now, if a shared not gets edited, the other users has to refresh the page to see changes.
- note update: send delta, not the whole note contents: Everytime you click on "Save", it sends the entire note data to the server. We can make this faster by only sending updates.
- Json data structure for api request/responses: Right now, the API end points on the backend side use a Map to serialize/deserialize the request/response. These should switch to proper JSON-compatible data types.
- create proper services apart from Controller: Right now, the back-end handles API calls from within the Controller class. Normally this logic should be placed in a service class.
- Response: return error code rather than strings (e.g. "failed")
- Error handling (e.g. getting invalid input for list of users to share with): Many edge cases are not handled (e.g. request to share a note from an un-authenticated user). These should be handled with proper errors returned.
- Better share/unshare experience: Right now, you need to remove a username from the list of users to unshare a note. This is not user friendly. We should show a list. ofusers to select/unselect to share/unshare. anote.
- can not share with yourself: This is allowed but should be checked to not happen and handled if happens.
- Optimise: Many of DB calls can be optimised (e.g. batch calls to db to get user/note/share info)
