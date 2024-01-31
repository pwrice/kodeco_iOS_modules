Kodeco module 7 homework

a) The ________ __________ class allows you to interact with the file system and its contents.

FileManager


b) Apps on iOS are _________________ from each other.

Sandboxed, isolated


c) True or False:

FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] will give the document directories for all Apps the user has on their device.


False. It returns the documentes directory for the user for the current app. There is a different documents directory for each app.


d)The _______________ folder is a good place to put re-usable code when using Playgrounds.

Sources


e) What URL property allows you to view the URL’s path?

The "path" property of a URL.

________________________ allows you to add a file name to a directory.

URL(fileURLWithPath: fileNameString , relativeTo: directoryURL)


f) Name at least three Swift Data Types you have used up to this point in the bootcamp.

Int, Float, Double


g) How can you find the number of bytes a Data Type uses?

MemoryLayout<DataTyoe>.size ie MemoryLayout<Int>.size


h) Using Playgrounds, how can you tell that the Data.write operation succeeded?

put the write() operation in a try-catch block and catch the error (and print it out)


i) You can mostly treat Data objects like _______________ of bytes.

arrays


j) The write and read methods of Data require a _______________.

URL


k) What JavaScript calls an object is the same concept as a heterogenous _____________ in Swift with __________________ for keys.

dictionary, strings


l) How do you resolve the error: Use of unresolved identifier ‘Bundle’?

import foundation

m) Give an example of Snake Case.

this_is_an_example_of_snake_case

n) A struct that will be used in the reading and writing of data must conform to the __________________ Protocol

Codable

o) Show the line of code used to access the user’s document directory for the running app.

URL.documentsDirectory


?

p) Files added to the project that will be used by the app can be found in the __________ _________ when the app is running.

Main application bundle

