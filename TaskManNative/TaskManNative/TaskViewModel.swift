import Foundation
import Combine
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var currentTasks: [TaskItem] = []
    @Published var historyTasks: [TaskItem] = []
    
    // Configurable delay
    private let archiveDelay: TimeInterval = 30.0
    
    func addTask(text: String) {
        let newTask = TaskItem(text: text)
        currentTasks.append(newTask)
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = currentTasks.firstIndex(where: { $0.id == task.id }) {
            // Toggle State
            currentTasks[index].isCompleted.toggle()
            
            // If completed, schedule archive
            if currentTasks[index].isCompleted {
                scheduleArchive(for: task)
            }
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        currentTasks.remove(atOffsets: offsets)
    }
    
    private func scheduleArchive(for task: TaskItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + archiveDelay) { [weak self] in
            self?.archiveTaskIfCompleted(task)
        }
    }
    
    func clearHistory() {
        historyTasks.removeAll()
    }

    private func archiveTaskIfCompleted(_ task: TaskItem) {
        // 1. Check if task still exists in current list
        if let index = currentTasks.firstIndex(where: { $0.id == task.id }) {
            let currentTask = currentTasks[index]
            
            // 2. Check if it is STILL completed (user didn't uncheck it)
            if currentTask.isCompleted {
                // 3. Move to history
                withAnimation {
                    self.currentTasks.remove(at: index)
                    self.historyTasks.insert(currentTask, at: 0) // Add to top of history
                }
            }
        }
    }
}
