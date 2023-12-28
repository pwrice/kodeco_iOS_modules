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
  
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading) {
        InlineTaskListView(tasksStore: tasksStore)
        Spacer()
        FooterView(showingAddTaskView: $showingAddTaskView)
      }
      .navigationTitle(Text("My Tasks"))
      .navigationDestination(for: Task.self) { task in
        TaskDetailsView(tasksStore: tasksStore, task: task)
      }
      .padding()
      .fullScreenCover(isPresented: $showingAddTaskView, content: {
        AddTaskView(tasksStore: tasksStore)
      })
    }
  }
}

struct InlineTaskListView: View {
  @ObservedObject var tasksStore: TasksStore
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(tasksStore.tasks) { task in
          NavigationLink(value: task) {
            VStack {
              TaskRowView(task: task)
              Divider()
            }
          }
        }
      }
    }
  }
}

struct TaskRowView: View {
  let task: Task
  
  var body: some View {
    HStack {
      Text(task.title)
        .bold()
      Spacer()
      if task.isCompleted {
        Image(systemName: "checkmark.square")
          .foregroundColor(.green)
          .bold()
      } else {
        Image(systemName: "square")
          .foregroundColor(.red)
          .bold()
      }
    }
    .padding()
  }
}

struct FooterView: View {
  @Binding var showingAddTaskView: Bool
  
  var body: some View {
    Button(action: {
      showingAddTaskView = true
    }) {
      Label("New Task", systemImage: "plus.circle.fill")
        .bold()
    }
  }
}

struct TaskList_Previews: PreviewProvider {
  static var previews: some View {
    TaskListView()
  }
}



// TODO
// - [DONE]Make task model and store
// - add mutation logic for tasks store
//    [DONE]- mark task done
//    [DONE]- add new task
// - Make task list view
//  [DONE]- header
//  [DONE]- task lists
//  [DONE]- footer w button
// [DONE]- style text in task list view
//   [DONE]- add SF Symbols
//   [DONE]- task title
//   [DONE]- header
//   [DONE]- new task button
// [DONE]- Extract views from task list view
//  [DONE]- header
//  [DONE]- footer
//  [DONE]- task list
//  [DONE]- task row
// [DONE]- add task details veiw
// [DONE]- style task details view
// [DONE]- hookup task completed toggle
// [DONE]- hook up list navigation to details
// [DONE]- add add task screen
// [DONE]- hookup add task screen to actually add a taks
// [DONE]- make tasklist scrollable
// [DONE]- re-implement navigation view with navigation stack
// [DONE]- disable add button when there is no title
// [DONE]- swap note to multi-line text field
