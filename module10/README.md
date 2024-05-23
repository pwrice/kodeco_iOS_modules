a) True or False: The function URLSession.dataTask(with:completionHandler:) is synchronous.

False - while the function does not take advantage of swifts new async/await syntax, it does perform work on a background thread and notify the caller through a closure passed in with the completion handler.


b) The sleep function is synchronous and it blocks its ___________.

Thread.


c) True or False: The new data(from:) async method from URLSession returns both data and a URL response object.

True

d)The code within a task closure runs sequentially, but the task itself runs on a __________ thread.

Background

e) True or False: In the new concurrency model, you usually don't need to capture self or other variables in async functions.

True

f) When defining an asynchronous function that can throw errors, the _________ keyword always comes before the throws keyword.

async

g) True or False: If you wrap code within a Task, it will always run on the main thread.

False

h) In SwiftUI, to resolve the issue of calling an asynchronous method in a nonconcurrent context, one can replace onAppear with ____________.


the .task() view modifier

i) True or Flase: In SwiftUI, view modifiers like onAppear inherently run code asynchronously.

True


j) The ____________ keyword indicates a function contains a suspension point.

async


k) True or False: You can design your own custom asynchronous sequences in Swift.

True

l) Computed properties can be marked with both ___________ and throws.

async

m) The AsyncSequence protocol requires defining the element type and providing an ______________.  

AsyncIterator

n) Task cancellation in Swift is ______________ in nature.

Cooperative ? Hierarchical ? 

o) True or False: To detect if a task has been canceled, you can refer to the isCanceled attribute of the task.

True

p) By using async let, variables are initialized ______________.

in parallel

q) An async let constant acts like a ___________ that either a value or an error will become available.

promise

