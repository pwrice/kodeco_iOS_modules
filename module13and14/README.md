Capstone Project


App Title (working title): LoopCanvas 
App Summary: Like freeform but for sample loops

App Desciption: 

Drag the colored blocks from the library to the canvas and drop them next to each other to connect them. Each colored block represents a 1 bar sample loop of a particular instrument (drums, guitars, piano etc..). When a block is dragged on to the canvas its sample plays in a loop. Blocks connected together play their samples sequentially left-to-right. Blocks connected vertically play their samples at the same time. Independent groups of blocks play independently.


MVP Features:
- Construct a simple song by dragging out sample blocks and link them together.
- Users can load different sample loop libraries pre-made with samples that make a reasonable sounding song
- Users can load their own samples from the local filesystem (iCloud files?)
- Users can search for sounds from a free online sample library API such as https://labs.freesound.org/about/ and download them locally into their project
- Infinitely scrollable / zoomable canvas (like freeform)
- users can save (and open) their projects to local JSON file in documents directory
- the blocks have playful animation when their sample is playing
- the blocks animate into place when connected
- individual blocks can be selected and deleted (or muted) with popup contextual menu


  Block Group Operations
    - groups of blocks can be moved, cloned, muted, or deleted 
    - need some sort of contextual block group handle


V2 Feautures
- AI Generated Samples: Users can use [Gemini/ChatGPT etc..] to generate custom sound effects and import them directly into the app
- Automix - Automatically mashup / re-mix existing sample blocks in an interesting (and unpredictable way) to create new variations.
- export and share your song with others (post JSON)


V3 Features
- Realtime co-play: connect with friends over facetime using shareplay to simultaneously


V4 Features (far future...)
- AU3 audio host to incorporate other realtime instrument input
- 3D app vision pro implementation!


MVP Screens:

- Choose Project Screen
  - choose an existing project to load or create a new project
  - delete a project

- Canvas Play Screen
  - construct your song by dragging blocks around, connecting them together, and have fun playing samples
  
- Library Drawer
  - expand the sample library drawer at the bottom to see more samples, re-arrange which ones are accessable in the 1 row library bar

- Library Switcher
  - choose amongst existing sample libraries 
  - clone, add / delete / edit sample libraries

- Library Editor
  - add / remove samples (load from filesystem)

- Help Screen / Overlay
  - explain basic mechanics on canvas screen

- Spash Screen and App Icon
  - better than what we have now
  - better app title



Implementation Notes:
Will use AudioKit to drive all of the sample playback


Capstone Requirements:

- The app has a splash screen suitable for the app. 
- It can be either a static or animated splash screen.
- All features in the app should be completed. 
- Any unfinished feature should be commented out.
- The app has at least one screen with a list using a view of your choice (List, grid, ScrollView .. etc). 
- Each item in the list should contain (as a minimum) a name, a sub-title/description, and an image of the item - the text should be styled appropriately. 
- Pressing on items in this list should lead to detail pages - this should show the same data in the list with some further details such as a longer description, bigger picture, price, and a Buy/Order button. 
- Include enough items to ensure that the user has to scroll the list to see all the items in it. 
- This should appear in a tab view with at least two tabs.
- The app has one or more network call(s) to download/upload data that relates to the core tasks of the app. Using strictly Apple’s URLSession.
- The app handles all typical errors related to network calls.
- Including at least: No network connection, server error.
- The app uses at least one way to save data: userdefaults, keychain, or local database. Please list your method in the Readme.
- The app communicates to the user whenever data is missing or empty, the reason for that condition, and a step to take in order to move forward. In other words, no blank screens. The user should never “feel” lost.  For example, whenever there are no items, such as when the data cannot be loaded, explain it).
- All included screens work successfully without crashes or UI issues. 
- App works for both landscape and portrait orientations.
- App works for both light and dark modes.
- No obvious UI issues.
- The code should be organized and easily readable.
- Project source files are organized in folders such as Views, Models, Networking etc.
- View components are abstracted into separate Views and source files.
- The model includes at least one ObservableObject with at least one Published value that at least one view subscribes to.
- The project utilizes SwiftLint with Kodeco’s configuration file. Follow instructions in the Kodeco Swift style guide. 
- Project builds without Warnings or Errors. (TODO warnings should be moved to a different branch.)
- The code has both UI and unit testing with a minimum of 50% code coverage.
- All test cases pass
- The app includes:
- A custom app icon.
- An onboarding screen.
- A custom display name.
- At least one SwifUI animation.
- Styled text properties. SwiftUI modifiers are sufficient.