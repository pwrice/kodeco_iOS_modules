Kodeco module 2 homework


a) Describe the two size classes in iOS.

verticalSizeClass and horizontalSizeClass. These classes can be incorporatedd into SwiftUI views as environment variables. The values can be compact and regular. These values vary depending on the device type and orientation of the screen.

b) What is Continuous Learning, and why is it important in mobile development?

Working developers engage in continuous learning to update and expand their skillset over the course of their career. The mobile development echosystem evolves quickly, so it is important to continuously learn to understand the latest tools and technologies.

c) How can you find out what modifiers a View has?

Select it in the SwiftUI preview panel, open the details inspector, and select the attributes inspector. The modifiers will be listed there.

d) What is a breakpoint?

It is a point in code where the debugger will stop execution and show all the current values of all the current relevant variables.

e) How can you access environment values in your App?

Using the @Environment(.[keypath]) directive with the correct keypath for the environment variable you want.

f) How can you determine, in code, if the App is in Dark or Light Mode?

@Environment(\.colorScheme)

g) Why are magic numbers an issue, and how should you avoid them?

Magic numbers are configuration values sprinked line throughout code. They can be duplicative and hard to locate. Turning these numbers into static constants keeps them all in one place where they are easy to edit and duplciates are easy to spot and remove.

h) How can you view your App in Light and Dark Modes simultaneously?

Setup multiple preview views with .preferredColorScheme set to .light and .dark 

i) Below is an image of the Canvas from Xcode. The Canvas is in selectable mode. Can you explain why the red background does not cover the entire button area?

It is because a padding modifier is being appled to the view after the red background. The red-backbground modifier returns a new view which is the same size as the original view, but with a red-background. Applying a padding modifier after this returns a new view with white padding around the view with the red background.

j) Modifier padding(10) adds padding to the view's top, bottom, left, and right sides. How could a padding of 10 be added to only the left and right sides of the view? The answer for this question should be a short section of code.

Use the modifier .padding(.horizontal, 10)

k) Provide two reasons why you would want to extract views.

One - to re-use the views as subviews in multiple parent views
Two - to keep the code for views from being too long and hard to understand

l) How can you determine, in code, if the device is in Portrait or Landscape mode?

You can approximate this with the environment variables verticalSizeClass and horizontalSizeClass. If vertical is compact and horizontal is regular, then you are in Landscape. If vertical is regular and horizontal is compact, then you are in Portrait. This would work for phone style devices. 

m) What is a literal value?

A literal value is an inline expression of a value that is implicitly initialized at instantiation time. An example would be initializing an array: 

var myArray = [1, 2, 3]

Where the "[1, 2, 3]" is a literal value.

o) What are the safe areas?

Safe areas are the edges of the screen UI that might be used for the notch or other OS related UI like a grabbable scroll nub or bar.

p) This line of code was in the lesson on animation. Can you state in English what the line means?

.frame(width: wideShapes ? 200 : 100)

If the boolean variable "wideShapes" is to, apply the frame() view modifier to the view above it with a width of 200. If "wideShapes" is false, apply the frame() view modifier with a width of 100.

q) Describe the two transitions you were introduced to in this week’s lesson.

.transition(.scale) - which transitions the size of a view as its states change
.transition(.opacity) - which fades a view in and out (default)

r) In Bullseye, the Game struct is what type of object?

It performs the role of "model" in the app architecture. It is a struct.

s) What are SFSymbols?

SFSymbols are a set if icons Apple provides which you can download and incorporate into your app.

t) What is the difference between “step into” and “step over " in the debugger?”

"Step into" descends into the function on the line and moves the current debugger execution point to the start of thats function.

"Step over" just executes the function on the line and goes to the next line, updating all of the current variables.

u) Name some items you would place in the Asset Catalog (Assets.)

ColorSets, AppIcon

v) How do you change the Display Name of your app?

Select the Bullseye project in the project navigator, select the General settings tab, make sure the Bullseye target is selected, and change the Display Name setting under Identity
 