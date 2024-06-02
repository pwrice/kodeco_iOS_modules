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


