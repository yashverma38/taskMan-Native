import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let toggleAction: () -> Void
    
    var body: some View {
        HStack {
            // Checkmark Circle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    toggleAction()
                }
                HapticManager.shared.impact(style: .medium)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(task.isCompleted ? .blue : .gray.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Text
            Text(task.text)
                .font(.body) // Dynamic Type
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    TaskRowView(task: TaskItem(text: "Buy groceries"), toggleAction: {})
}
