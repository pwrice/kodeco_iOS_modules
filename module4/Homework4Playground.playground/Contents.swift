import Cocoa

//a) In the assignment for Module 3, part D asked you to write a function that would compute the average of an array of Int. Using that function and the array created in part A, create two overloaded functions of the function average.

print("a) ---------------")

let firstArry = Array(0...20)

func average(_ array: [Int]?) {
  if let array = array {
    var sum = 0
    for el in array {
      sum += el
    }
    let average = array.count > 0 ? Double(sum) / Double(array.count) : 0.0
    print("The average of the values in the array is \(average).")
  } else {
    print("The array is nil. Calculating the average is impossible.")
  }
}


// take non-optiolnal argument + new arg label
func average(forNonOptional array: [Int]) {
  print("calling average() overload nonOptional parameter")
  average(array)
}

// average with default parameter
func average(array: [Int]? = firstArry) {
  print("calling average() overload with default parameter")
  average(array)
}

average(forNonOptional: firstArry)
average()


//b) Create an enum called Animal that has at least five animals. Next, make a function called theSoundMadeBy that has a parameter of type Animal. This function should output the sound that the animal makes. For example, if the Animal pass is a cow, the function should output, “A cow goes moooo.” Hint: Do not use if statements to complete this section.

print("b) ---------------")

//Call the function twice, sending a different Animal each time.

enum Animal {
  case dog
  case cat
  case fish
  case bird
}

func theSoundMadeBy(animal: Animal) {
  switch animal {
  case .dog:
    print("A dog goes woof")
  case .cat:
    print("A cat goes meow")
  case .fish:
    print("A fish goes bloop")
  case .bird:
    print("A bird goes tweet")
  }
}

theSoundMadeBy(animal: .dog)
theSoundMadeBy(animal: .cat)
theSoundMadeBy(animal: .fish)
theSoundMadeBy(animal: .bird)



//c) This question will have you creating multiple functions that will require you to use closures and collections. First, you will do some setup.

print("c) ---------------")

//Create an array of Int called nums with the values of 0 to 100.

let nums = Array(0...100)

//Create an array of Int? called numsWithNil with the following values:
//79, nil, 80, nil, 90, nil, 100, 72

let numsWithNil: [Int?] = [79, nil, 80, nil, 90, nil, 100, 72]

//Create an array of Int called numsBy2 with values starting at 2 through 100, by 2.

var numsBy2: [Int] = Array(1...50).map { $0 * 2 }
print(numsBy2)
numsBy2 = Array(stride(from:2, through: 100, by: 2)) //function (or stride(from:through:by:))
print(numsBy2)

//Create an array of Int called numsBy4 with values starting at 2 through 100, by 4.

// Is this what is meant?
var numsBy4: [Int] = Array(1...25).map { $0 * 4 - 2 }
print(numsBy4)

// Or perhaps this?
numsBy4 = Array(1...25).map { $0 * 4 }
print(numsBy4)

// Or perhaps this?
numsBy4 = Array(stride(from:2, through: 100, by:4))
print(numsBy4)


//You can set the values of the arrays above using whatever method you find the easiest. In previous modules, you were introduced to ranges and sequences in Swift. Leveraging those in the Array initializer will allow you to create the requested arrays in a single line. Don’t let the last two break your stride.

//- Create a function called evenNumbersArray that takes a parameter of [Int] (array of Int) and returns [Int]. The array of Int returned should contain all the even numbers in the array passed. Call the function passing the nums array and print the output.

func evenNumbersArray(_ array: [Int]) -> [Int] {
  array.filter({ $0 % 2 == 0})
}

let evenNums = evenNumbersArray(nums)
print("evenNums \(evenNums)")

//- Create a function called sumOfArray that takes a parameter of [Int?] and returns an Int. The function should return the sum of the array values passed that are not nil. Call the function passing the numsWithNil array, and print out the results.

func sumOfArray(_ array: [Int?]) -> Int {
  array.compactMap({ $0 }).reduce(0, { $0 + $1 })
}
let nonNilSum = sumOfArray(numsWithNil)
print("nonNilSum \(nonNilSum)")

//- Create a function called commonElementsSet that takes two parameters of [Int] and returns a Set<Int> (set of Int.) The function will return a Set<Int> of the values in both arrays.

func commonElementsSet(_ array1: [Int], _ array2: [Int]) -> Set<Int> {
  return Set(array2).intersection(array1)
}

//Call the function commonElementsSet passing the arrays numsBy2, numsBy4, and print out the results.

let commonBy2AndBy4 = commonElementsSet(numsBy2, numsBy4).sorted()
print("commonBy2AndBy4 \(commonBy2AndBy4)")

//d) Create a struct called Square that has a stored property called sideLength and a computed property called area. Create an instance of Square and print out the area.

print("d) ---------------")

struct Square {
  let sideLength:  Double
  var area: Double {
    sideLength * sideLength
  }
}

let sq = Square(sideLength: 4)
print("sq.area \(sq.area)")

//Part 3 - Above and Beyond

//Create a protocol called Shape with a calculateArea() -> Double method. Create two structs called Circle and Rectangle that conform to the protocol Shape. Both Circle and Rectangle should have appropriate stored properties for calculating the area.

protocol Shape {
  func calculateArea() -> Double
}

struct Circle: Shape {
  let radius: Double
  
  func calculateArea() -> Double {
    Double.pi * radius * radius
  }
}

struct Rectangle: Shape {
  let width: Double
  let height: Double

  func calculateArea() -> Double {
    width * height
  }
}

//Create instances of Circle and Rectangle and print out the area for each.

let circle = Circle(radius: 3)
print("circle area: \(circle.calculateArea())")

let rect = Rectangle(width: 3, height: 4)
print("rect area: \(rect.calculateArea())")

//Next, extend the protocol Shape to add a new method called calculateVolume() -> Double.


// Interesting - it seems you can extend a protocol w/out defining a default implementation. I guess that makes sense?
extension Shape {
  func calculateVolume() -> Double {
    return 0.0
  }
}

//Finally, create a struct called Sphere that conforms to Shape. Sphere should have appropriate stored properties for calculating area and volume.

struct Sphere: Shape {
  let radius: Double
  
  func calculateArea() -> Double {
    4.0 * Double.pi * radius * radius
  }

  func calculateVolume() -> Double {
    4.0 / 3.0 * Double.pi * radius * radius * radius
  }
}

//Create an instance of Sphere and print out the area and volume.

let sphere = Sphere(radius: 3)
print("sphere area \(sphere.calculateArea()) and volume \(sphere.calculateVolume())")
