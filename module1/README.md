# kodeco_iOS_module1
Kodeco module 1 homework

##Part One Questions:

a) What does the command ‘git status’ output?

The status of the files and directories in the git project, including which ones are new, which ones have changed, and/or which ones have been renamed/removed. It also indicates which of the above changes are staged to be commited w/ the commit command.


b) In SwiftUI, anything that gets drawn on the screen is a ____View___________.


c) print(“Hello world”) is an example of a _____function_________ call.

viewModel.getData() is an example of a ______method______ call.


d) Name some Views you have seen so far in SwiftUI.

Text(), Image(), VStack(), HStack(), Slider()

e) How do you create a new local repository using git? (Feel free to answer with how you use git, i.e. terminal or another app)

With terminal, in the directory you want to make into a git repo:
:> git init

f) How do you preview your app in multiple orientations?

Select orientation variants in the tool bar in the lower left of the the preview window.

g) An app is made up of ____instances____ of classes and structs that contain ____data____  and ____methods____.

h) Name two components of a SwiftUI Button.

the text to display in the button, and an action to perform when the button is pressed.

i) In git, what is the difference between a local repository and a remote repository?

A local repo is on your local dev machine, while the remote repo is stored on a remote machine in the cloud (in this case github). They need to be manually sync'd with git push and pull.

j) Give an example of camel case.

thisIsACamelCasePropertyName

k) What is a branch in git, and how do you create one? (Feel free to answer with how you use git, i.e. terminal or another app)

A branch is a chain of change-sets to the local files in the repo. The branch name is the label that points to a particular change in the chain. Branches allow you to track sequential changes to files in your project in independent channels that can be checked out to switch between them.

:> git checkout -b "new-branch-name"

l) What are some common mistakes that can lead to errors while programming?

typos, off-by-one errors, UI being out of sync with data

m) VStack, HStack, and ZStack are ______stack______ views used for ______layout______.

n) How do you list the branches on your local repository? (Feel free to answer with how you use git, i.e. terminal or another app)

:> git branch -a

o) What happens when @State variable changes in SwiftUI?

The system rerenders the views that depend on data that are bound to the @State var.

p) What is the Single Responsibility Principle?

An architecture principle to organize your code by having separate class, structs, or modules focus on doing only one thing, which makes them easier to compose, refactor, replace, and test.

q) What will the print statement below produce?

var name = “Ozma”

print(“Hello, \(name)!”)

Hello, Ozma

r) What commands can you use in git to download data from a remote repository? What commands can you use in git to send data to a remote repository? (Feel free to answer with how you use git, i.e. terminal or another app)

download data from a remote repository:  git clone, git fetch, git pull
send data to a remote repository: git push

s) Why is a programming To-Do list important, and what is a minimum viable product?

The To-Do list lets explicitly enumerate the requirements for your project and the implementaion steps necessary to support those requirements. It also allows you to priortize those requirements and steps. A MVP is the minimum set of functionality necessary to demnonstrate the core behavior and value of your product (with out all of the bells and whistles).

t) What is a simple way of describing Binding in SwiftUI?

A binding is a way of connecting a @State property to a UI widget (like a slider) so that it changes when the UI widget's value changes. Similarly, changing the @State property in code will change the UI widget's value.

u) What command do you use in git to move changes from one branch to another? (Feel free to answer with how you use git, i.e. terminal or another app)

git merge

v) What is the type of the variable defined below?

var a = 87

Int

w) What is the difference between var and let?

Variables defined with let are constants and cannot have their values re-assigned. Variables defined with let can have their values re-assigned.


## Part 3 Questions


As with the short answer questions earlier, try answering these questions from memory before looking for the answer. Some of the fill-in-the-blank questions have a letter before the second blank. This is the first letter of the expected word.


In ContentView, lines 1 and 2 show the definition of ____state________ P____property__________.

In ContentView, line 3 shows the definition of a      ____variable________  P____property__________.


In ContentView, line 4 shows the definition of a     _____view_______ P_____property__________.


In ContentView, line 5 shows an   _____instance____________ of Game calling the ______method_________ points.


In ContentView, line 6 is the definition of the M____method______  doSomethingWithCounter().


In Game, lines a, b, and c show the definition of   _______data________ _____properties______________.


In Game, line d is the definition of the   _____method__________ points(sliderValue: Int).


Lines 3, a, b, and c are the   ________data_________ P_____properties__________ and lines 6 and d are the   _____methods__________ of the structs.



 struct ContentView: View {

1    @State private var sliderValue: Int = 50
2    @State private var game: Game = Game()
3    private var counter = 0
4    var body: some View {
5        Text("The score is: \(game.points(sliderValue: sliderValue))")
     }
6    func doSomethingWithCounter() {
         // to be determined
     }
 }


 struct Game {
a    var target: Int = 37
b    var score: Int = 0
c    var round: Int = 1
d    func points(sliderValue: Int) -> Int {
        return 999
     }
 }