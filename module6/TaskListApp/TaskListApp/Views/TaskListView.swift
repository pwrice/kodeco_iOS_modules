//
//  TaskListView.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import SwiftUI

struct TaskListView: View {
  @StateObject var tasksStore = TasksStore()
  @State var showingAddTaskView: Bool = false
  @State var selectedTab = 0
  @State var searchTaskName: String = ""

  var uncompletedTasks: [Task] {
    if !searchTaskName.isEmpty {
      return tasksStore.searchUncompletedTasks(searchTerm: searchTaskName)
    }
    return tasksStore.uncompletedTasks
  }
  
  var completedTasks: [Task] {
    if !searchTaskName.isEmpty {
      return tasksStore.searchCompletedTasks(searchTerm: searchTaskName)
    }
    return tasksStore.completedTasks

  }
    
  var body: some View {
    NavigationStack {
      TabView(selection: $selectedTab) {
        InlineTaskListView(tasks: uncompletedTasks, tasksStore: tasksStore)
          .tabItem {
            Image(systemName: "list.bullet.circle")
              .resizable()
            Text("Tasks")
          }
          .tag(0)
        InlineTaskListView(tasks: completedTasks, tasksStore: tasksStore)
          .tabItem {
            Image(systemName: "checkmark.circle")
              .resizable()
            Text("Completed")
          }
          .tag(1)
        InlineTaskCategoryView(tasksStore: tasksStore)
          .tabItem {
            Image(systemName: "tag.circle")
              .resizable()
            Text("Categories")
          }
          .tag(2)
      }
      .navigationTitle(Text("My Tasks"))
      .navigationBarItems(
        trailing: Button(action: {
          showingAddTaskView = true
        }, label: {
          Image(systemName: "plus.circle.fill")
            .bold()
        }))
      .navigationDestination(for: Task.self) { task in
        TaskDetailsView(tasksStore: tasksStore, task: task)
      }
      .fullScreenCover(isPresented: $showingAddTaskView, content: {
        AddTaskView(tasksStore: tasksStore)
      })
      .searchable(text: $searchTaskName, prompt: "Task Name")

    }
  }
}

struct InlineTaskListView: View {
  let tasks: [Task]
  let tasksStore: TasksStore

  var body: some View {
    List(tasks) { task in
      NavigationLink(value: task) {
        TaskRowView(task: task, tasksStore: tasksStore)
      }
    }
    .listStyle(.plain)
  }
}

struct InlineTaskCategoryView: View {
  @ObservedObject var tasksStore: TasksStore
  @State var selectedCategory: TaskCategory? = nil

  var body: some View {
    VStack {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], content: {
        ForEach(tasksStore.categories, id: \.self) { category in
          CategoryCard(tasksStore: tasksStore, category: category, selectedCategory: $selectedCategory)
        }
      })
      .padding()
      List(tasksStore.tasks(for: selectedCategory)) { task in
        NavigationLink(value: task) {
          TaskRowView(task: task, tasksStore: tasksStore)
        }
      }
      .listStyle(.plain)
    }
  }
}

struct CategoryCard: View {
  @ObservedObject var tasksStore: TasksStore
  let category: TaskCategory
  @Binding var selectedCategory: TaskCategory?
  
  var body: some View {
    Button(action: {
      if selectedCategory == category {
        selectedCategory = nil
      } else {
        selectedCategory = category
      }
    }, label: {
      VStack(spacing: 20) {
        Text(category.rawValue)
        Text(String(tasksStore.taskCount(for: category)))
      }
      .font(.title3)
      .bold()
      .foregroundColor(.white)
      .frame( minWidth: 0, maxWidth: .infinity, minHeight: 120)
      .background(.red)
      .cornerRadius(15)
    })
  }
}

struct TaskRowView: View {
  let task: Task
  let tasksStore: TasksStore
  @State var isCompleted: Bool = false

  
  var body: some View {
    HStack {
      Text(task.title)
        .bold()
      Spacer()
      Button(action: {
        withAnimation(.easeInOut(duration: 0.5)) {
          isCompleted = !isCompleted
        } completion: {
          tasksStore.setTask(with: task.id, completed: !task.isCompleted)
        }
      }, label: {
        if isCompleted {
          Image(systemName: "checkmark.square")
            .foregroundColor(.green)
            .bold()
        } else {
          Image(systemName: "square")
            .foregroundColor(.red)
            .bold()
        }
      })
      .buttonStyle(.borderless)
    }
    .padding()
    .onAppear {
      isCompleted = task.isCompleted
    }
  }
}

struct TaskList_Previews: PreviewProvider {
  static var previews: some View {
    TaskListView()
  }
}



// TODO
//[DONE]- convert LazyVStack to list
//  [DONE]- adjust style and padding
// [DONE]- move add task button to nav tool bar and get rid of text
//  [DONE]- get rid of footer view
// [DONE]- Modify TaskListView  to display only those tasks where isCompleted property is set to false.
// [DONE]- Add a TabView to the project, with two tabs.
//  [DONE]- The first tab should display the list of incomplete tasks using the SF Symbol list.bullet.circle as the image and “Tasks” as the text.
//  [DONE]- The second tab should showcase completed tasks with the SF Symbol checkmark.circle as the image and “Completed” as the text. Ensure that the TabView is presented when the user launches the app.
// [DONE]- Add the ability for the user to search Tasks, both completed and not completed.
// [DONE] Add unit tests for TaskStore
// [DONE]- Allow the user to toggle the isCompleted property of a task by tapping on the square or checkmark. Animate the transition between the square and the check mark symbols.
// ABOVE & BEYOND
// - add category enum
// - add tasks by category getter, count functions to store
// - add third tab + category view
// - add grid view
// - extract and style grid view cards
// - hookup category counts
// - hookup category card tap behavior
// - add unit tests for store

