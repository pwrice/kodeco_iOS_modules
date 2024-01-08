//
//  TasksStoreTests.swift
//  TasksStoreTests
//
//  Created by Peter Rice on 12/29/23.
//

import XCTest

final class TasksStoreTests: XCTestCase {
  var tasksStore: TasksStore?

  let testTasks = [
    Task(title: "Task 1", isCompleted: false, notes: "", category: .home),
    Task(title: "Task 2", isCompleted: false, notes: "", category: .work),
    Task(title: "Task 3", isCompleted: true, notes: "", category: .personal),
    Task(title: "Task 4", isCompleted: true, notes: "", category: .none),
  ]
  
  override func setUpWithError() throws {
    tasksStore = TasksStore(with: testTasks)
  }
  
  override func tearDownWithError() throws {}
  
  func testDefaultTasks() throws {
    tasksStore = TasksStore()
    XCTAssertEqual(tasksStore!.tasks, tasksStore!.defaultTasks, "Task store was not initialized with defaultTasks")
  }

  func testSetTaskComplete() throws {
    tasksStore = TasksStore(with:  [
      Task(title: "Test Task", isCompleted: false, notes: "", category: .home)])
    let firstTaskId = tasksStore!.tasks.first!.id
 
    tasksStore?.setTask(with: firstTaskId, completed: true)
    
    let updatedTask = tasksStore!.tasks[0]
    XCTAssertEqual(updatedTask.isCompleted, true, "Expected updatedTask.isCompleted to be true but got \(updatedTask.isCompleted)")
  }

  func testAddTask() throws {
    let originalTaskList = tasksStore!.tasks
    let newTaskTitle = "New Task Title"
    let newTaskNotes = "New Task Notes"
    XCTAssertNil(originalTaskList.first(where: { $0.title == newTaskTitle }))
    
    tasksStore?.addTask(title: newTaskTitle, notes: newTaskNotes)
    
    let updatedTaskList = tasksStore!.tasks
    XCTAssertEqual(updatedTaskList.count, originalTaskList.count + 1, "Expected updatedTaskList to be 1 longer than originalTaskList but got \(updatedTaskList.count) and \(originalTaskList.count) respectively.")
    let newTask = updatedTaskList.first(where: { $0.title == newTaskTitle })!
    XCTAssertEqual(newTask.title, newTaskTitle)
    XCTAssertEqual(newTask.notes, newTaskNotes)
    XCTAssertNil(originalTaskList.first(where: { $0.id == newTask.id }))
  }
  
  func testCompletedTasks() throws {
    XCTAssertEqual(tasksStore!.completedTasks.count, 2, "The test fixture has two completed tasks, but found \(tasksStore!.completedTasks.count)")
    let firstCompletedTask = tasksStore!.completedTasks.first!
    XCTAssertEqual(firstCompletedTask.isCompleted, true, "The first completed task.isCompleted should be true but found \(firstCompletedTask.isCompleted)")
  }

  func testUncompletedTasks() throws {
    XCTAssertEqual(tasksStore!.uncompletedTasks.count, 2, "The test fixture has 2 uncompleted tasks, but found \(tasksStore!.uncompletedTasks.count)")
    for task in tasksStore!.uncompletedTasks {
      XCTAssertEqual(task.isCompleted, false, "Task \(task.title) isComplete should be false but is \(task.isCompleted)")
    }
  }

  func testSearchUncompletedTasksReturnsMatch() throws {
    let matchingTasks = tasksStore!.searchUncompletedTasks(searchTerm: "1")
    XCTAssertEqual(matchingTasks.count, 1, "The test fixutre should have 1 matching task but found \(matchingTasks.count)")
    XCTAssertEqual(matchingTasks.first?.title, "Task 1", "The matching title should be 'Task 1' but found \(String(describing: matchingTasks.first?.title))")
  }

  func testSearchUncompletedTasksReturnsNoMatch() throws {
    let matchingTasks = tasksStore!.searchUncompletedTasks(searchTerm: "3")
    XCTAssertEqual(matchingTasks.count, 0, "The test fixture should have 0 matching tasks but found \(matchingTasks.count)")
  }

  
  func testSearchCompletedTasksReturnsMatch() throws {
    let matchingTasks = tasksStore!.searchCompletedTasks(searchTerm: "3")
    XCTAssertEqual(matchingTasks.count, 1, "The test fixutre should have 1 matching task but found \(matchingTasks.count)")
    XCTAssertEqual(matchingTasks.first?.title, "Task 3", "The matching title should be 'Task 3' but found \(String(describing: matchingTasks.first?.title))")
  }

  func testSearchCompletedTasksReturnsNoMatch() throws {
    tasksStore = TasksStore(with: testTasks)
    
    let matchingTasks = tasksStore!.searchCompletedTasks(searchTerm: "1")
    XCTAssertEqual(matchingTasks.count, 0, "The test fixture should have 0 matching tasks but found \(matchingTasks.count)")
  }

  
  func testTaskCategories() throws {
    let categoriesNameList = tasksStore!.categories.map( \.rawValue )
    XCTAssertEqual(categoriesNameList, ["Personal", "Work", "Home", "No Category"], "The default category list should be Personal, Work, Home, No Category but found \(categoriesNameList)")
  }
  
  func testTasksByCategory() throws {
    tasksStore = TasksStore(with: testTasks)
    for category in tasksStore!.categories {
      let categoryTasks = tasksStore!.tasks(for: category)
      XCTAssert(categoryTasks.count > 0, "There should be at least 1 category for \(category.rawValue) but found \(categoryTasks.count)")      
      XCTAssertEqual(categoryTasks.first?.category, category, "The firstTask.category should be \(category.rawValue) but found \(String(describing: categoryTasks.first?.category.rawValue))")
    }
  }
}
