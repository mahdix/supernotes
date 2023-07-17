# SuperNotes
A simple app to create and share text notes (Front-end + Back-end)

# Run locally

The app uses a local sqlite database. Make sure you have JDK 17 and Maven CLI installed. You will also need `yarn` to compile front-end code.

1. `git clone` the repository
2. `cd` into the repository root.
3. `cd web`
4. `yarn build`
5. `cp -R dist ../src/main/resources/` 
6. `mvn spring-boot:run`

# Using the app

- You can visit `http://localhost:8082/index.html` to see home page.
- You can login via "test1/test1" or "mahdi/123" or you can sign up as a new user.
- After login, you will see a list of your notes (and notes shared with you).
- For each note, you can edit the note by "Edit" button where you can change title or body of the note or share it by entering username of the recipient.

# Design

The app uses Spring Boot + Spring JPA to manage web application API and also database connectivity. These tools allow the developer to do more with writing less code.

The app consists of 3 layers:
- Database: A single sqlite database file hosted within the app's classpath.
- Back-end: A Java application with API endpoints to do app functionalities (e.g. login)
- Front-end: A React/Typescript app which uses Parcel for packaging.

# Scaling

In order to scale this, it needs to happen on 3 fronts:
- Database: We need to switch to a scalable DB server like MySQL probably enhanced with a caching later.
- Application: As the app is stateless (Except for session storage), we can easily replicate it across multiple app servers with a LB in front.
- Front-end: These are static resources that can be delivered to a CDN for faster client-side rendering.

In order to provide fast real-time sync across users, we can use a websocket-based solution to push any changes to clients that have subscribed to updates for one or a set of notes. On the server-side, these changes can be sent via a single outbound gateway which uses a Kafka topic to listen to any updates coming from any of the application server machines.

In order to add Kafka, we will need to do below:
1. Set up a set of Kafka brokers with enough storage provisioned according to system load and retention requirements.
2. In the application side, we should define topics like "note.update" or "note.shared".
3. API code that does the corresponding functionality should also publish an update to the related Kafka topic.
4. API should also subscribe to those Kafka topics and translate those messages into websocket push messages so clients are updated in realtime.

## When to switch to Kafka?

This really depends on the available resource and client-side requirements. We should usually deploy a monitoring solution like Prometheus and check the API throughput and response times. When these are above a certain threshold, then it is probably time to plan to switch to a Kafka model.

# Improvement (shortcuts taken)

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
