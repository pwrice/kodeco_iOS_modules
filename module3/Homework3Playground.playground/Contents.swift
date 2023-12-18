

//a) Create an array of Int called nums with values 0 through 20. Iterate over the Array and print the even numbers.
print("a) ---------------")
let firstArry = Array(0...20)
for num in firstArry where num % 2 == 0 {
  print(num)
}

//b) In your Playground, define the following String:
//
//let sentence = “The qUIck bRown fOx jumpEd over the lAzy doG”
//
//Iterate over sentence counting the vowels (a, e, i, o, u), ignoring the case.

print("b) ---------------")
let sentence = "The qUIck bRown fOx jumpEd over the lAzy doG"
var vowelCount = 0
let lowercasedSentence = sentence.lowercased()
let vowels = Set(["a", "e", "i", "o", "u"])
for character in lowercasedSentence where vowels.contains(String(character)) {
  vowelCount += 1
}
print(vowelCount)


//c) Create two arrays of Int with the values of 0 through 4. Use a nested for loop to print a mini multiplication table. The output, which should be multiple lines, should be in the following format:
//
//0 * 0 = 0
//
//
//The format follows the number from the first array, space, followed by the character *, space,  followed by the number from the second array, space,  followed by =, space, followed by the result of the number from the first array multiplied by the number from the second array (just like the example above). There are a couple of ways to achieve this, but String Interpolation is the easiest.

print("c) ---------------")
let arrayA = Array(1...4)
let arrayB = Array(1...4)

for numberA in arrayA {
  for numberB in arrayB {
    print("\(numberA) * \(numberB) = \(numberA * numberB)")
  }
}

//d) Write a function called average that takes an optional array of Int. If the array is not nil, calculate the average of the array's values and print:
//
//“The average of the values in the array is <average>.”
//
//
//Where <average> is the calculated average. If the array is nil, print:
//
//“The array is nil. Calculating the average is impossible.”
//
//
//Note: the average is calculated by summing the values in the array and dividing by the number of elements.
//
//
//Call this function two times. First, pass in the nums array from part A and second by passing an optional array of Int.

print("d) ---------------")

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

average(firstArry)
let optionalArray: [Int]? = nil
average(optionalArray)
average([])

//e) Create a struct called Person with the properties firstName, lastName, and age. Choose appropriate data types for the properties. Include a method on Person called details that prints the values stored in the properties in the following format:
// Name: <firstName> <lastName>, Age: <age>
//
//
//Create an instance of Person called person. Pass your first name, last name, and age for the properties. Finally, call the method details.

print("e) ---------------")

struct Person {
  let firstName: String
  let lastName: String
  let age: Int
  
  func details() {
    print("Name: \(firstName) \(lastName), Age: \(age)")
  }
}

let pete = Person(firstName: "Pete", lastName: "Rice", age: 49)
pete.details()

//f) Create a class called Student with two properties: person of type Person and grades, an array of Int. The class must have a method called calculateAverageGrade that takes no parameters and returns a Double. Include a method called details that prints the values of the properties stored in Student along with the average grade in the following format:
// Name: <firstName> <lastName>, Age: <age>, GPA: <average grade>.
//
//
//Create an instance of Student called student passing in your first name, last name, age, and an array of five numbers: 94, 99, 81, 100, 79. Next call the details method to output the details of the student.

print("f) ---------------")

class Student {
  let person: Person
  var grades: [Int]
  
  init(person: Person, grades: [Int]) {
    self.person = person
    self.grades = grades
  }
  
  func calculateAverageGrade() -> Double  {
    var sum = 0
    for el in grades {
      sum += el
    }
    return grades.count > 0 ? Double(sum) / Double(grades.count) : 0.0
  }
  
  func details() {
    print("Name: \(person.firstName) \(person.lastName), Age: \(person.age), GPA: \(calculateAverageGrade()).")
  }
}

let studentPete = Student(person: pete, grades: [94, 99, 81, 100, 79])
studentPete.details()
studentPete.grades.append(95)
studentPete.details()


// Above and beyond

// In your README file, include the two lines of print out from this code and explain why the output is what it is.

print("f) ---------------")

struct Square {
  var side: Int
  func area() -> Int {
    return side * side
  }
}


class Rectangle {
  var length: Int
  var width: Int
  init(length: Int, width: Int) {
    self.length = length
    self.width = width
  }

  func area() -> Int {
    return length * width

  }
}


var square1 = Square(side: 4)
var square2 = square1
square2.side = 5

print("Area: square1 - \(square1.area()) square2 - \(square2.area())")

var rectangle1 = Rectangle(length: 4, width: 4)
var rectangle2 = rectangle1

rectangle2.length = 5
print("Area: rectangle1 - \(rectangle1.area()) rectangle2 - \(rectangle2.area())")
