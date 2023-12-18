Kodeco module 3 homework

a) 0…5 and 0..<5 are two types of ____________. How are they different?

They are two types of Ranges. The first range is a closed range and covers the values 1 to 5 including 5. The second range is a half-open range and covers the values 1 to 4 (one less than the second number 5).

b) Describe type inference in Swift and give an example.

Type inference in swift is the process by which the compiler figures out the type of a var or constant by context instead of an explicit type signature.

let x = 5 

The compiler will infer that x is an Int w/out that type needing to be explicitly defined.

c) List three advantages of Playgrounds.

Playgrounds are fast to setup and try out small pieces of code.
Playgrounds allow you to inspect return values easily by evaluating each line.
Playgrounds can speed up the run-eval-debug loop by immediately evalating code after it is typed (and not waiting for deploy to a simulator).

d) When does the execution of a while loop end?

When the condition at the beginning of the while-loop evaluates to false.

e) True or False: Tuples in Swift can contain values of different data types.

True!

f) List three data types you have used in Swift.

Array, Tuple, Dictionary

g) To execute alternative code when the condition of an if statement is not met, you can use what clause?

the 'else' clause

h) What is the third element of the array nums defined below?  

let nums = [5, 0, 44, 20, 1].

nums[2]

44

i) An ____________ is a unit of code that resolves to a single value.

expression ?


j) Define two ways to unwrap optionals in Swift.

if let unwrappedVar = optionalVar {

}

let unwrappedVar = optionalVar ?? defaultValue

k) True or False: The condition in an if statement must be true or false.

True

l) Arrays in Swift are ____________ indexed.

Zero

m) An unordered collection of unique values of the same type is a _____________.

Set
