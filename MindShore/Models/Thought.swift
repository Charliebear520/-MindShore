import Foundation

struct Thought: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    var emotion: Emotion?
    var tags: [String]
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), emotion: Emotion? = nil, tags: [String] = []) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.emotion = emotion
        self.tags = tags
    }
}

enum Emotion: String, Codable, CaseIterable {
    case happy = "開心"
    case sad = "難過"
    case angry = "生氣"
    case anxious = "焦慮"
    case calm = "平靜"
    case excited = "興奮"
    case neutral = "中性"
} 