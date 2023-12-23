//
//  TaskListAppApp.swift
//  TaskListApp
//
//  Created by Peter Rice on 12/22/23.
//

import SwiftUI

@main
struct TaskListAppApp: App {
  @StateObject var tasksStore = TasksStore()
    var body: some Scene {
        WindowGroup {
          TaskListView(tasksStore: tasksStore)
        }
    }
}
