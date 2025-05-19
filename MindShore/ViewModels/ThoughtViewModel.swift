import Foundation
import SwiftUI

class ThoughtViewModel: ObservableObject {
    @Published var thoughts: [Thought] = []
    @Published var currentThought: String = ""
    @Published var selectedDate: Date? = nil
    @Published var selectedThought: Thought? = nil
    
    var groupedThoughts: [Date: [Thought]] {
        Dictionary(grouping: thoughts) { thought in
            Calendar.current.startOfDay(for: thought.timestamp)
        }
    }
    
    func addThought() {
        guard !currentThought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newThought = Thought(content: currentThought)
        thoughts.insert(newThought, at: 0)
        currentThought = ""
    }
    
    func deleteThought(_ thought: Thought) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts.remove(at: index)
        }
    }
} 