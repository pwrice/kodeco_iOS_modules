//
//  TaskDetailsView.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import SwiftUI

struct TaskDetailsView: View {
  var tasksStore: TasksStore
  let task: Task  
  @State private var taskCompleted: Bool = false

  var body: some View {
    VStack {
      Form {
        Section(header:
          Text("Task Title")
        )
        {
          Text(task.title)
            .bold()
        }
        Section(header: Text("Notes")) {
          Text(task.notes)
            .bold()
        }
        Section() {
          Toggle(isOn: $taskCompleted) {
            Text("Completed: ")
              .bold()
          }
          .onChange(of: taskCompleted, initial: task.isCompleted) { oldValue, newValue in
            tasksStore.setTask(with: task.id, completed: taskCompleted)
          }
        }
      }
    }    
    .onAppear {
      taskCompleted = task.isCompleted
    }
  }
}

struct TaskDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    TaskDetailsView(
      tasksStore: TasksStore(),
      task: Task(title: "Task Title", isCompleted: false, notes: "test notes")
    )
  }
}
