//
//  AddTaskView.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import SwiftUI

struct AddTaskView: View {
  var tasksStore: TasksStore
  @State var taskTitle: String = ""
  @State var taskNotes: String = ""
  @Binding var showingAddTaskView: Bool
  
  var body: some View {
    NavigationView {
      VStack {
        Form {
          Section(header: Text("Task Title"))
          {
            TextField("Title", text: $taskTitle)
          }
          Section(header: Text("Notes")) {
            TextField("Notes", text: $taskNotes, axis: .vertical)
              .lineLimit(5...)
          }
        }
      }
      .navigationBarTitle(Text("Add New Task"), displayMode: .inline)
      .navigationBarItems(
        leading: Button(action: {
          showingAddTaskView = false
        }, label: {
          Text("Cancel")
        }),
        trailing: Button(action: {
          tasksStore.addTask(title: taskTitle, notes: taskNotes)
          showingAddTaskView = false
        }, label: {
          Text("Add")
        })
        .disabled(taskTitle.isEmpty)
      )
    }
  }
}

struct AddTaskView_Previews: PreviewProvider {
  static var previews: some View {
    AddTaskView(tasksStore: TasksStore(), showingAddTaskView: .constant(true))
  }
}

