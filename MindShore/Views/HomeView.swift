import SwiftUI

fileprivate let folderDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// AI 角色資料結構
struct AICharacter: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String // 對應 Assets.xcassets 的圖片名稱
    let description: String
}

let aiCharacters = [
    AICharacter(name: "小晴", imageName: "ai1", description: "溫柔傾聽者，陪你聊聊心事。"),
    AICharacter(name: "小宇", imageName: "ai2", description: "理性分析師，幫你釐清思緒。"),
    AICharacter(name: "小樂", imageName: "ai3", description: "正能量夥伴，給你鼓勵與支持。")
]

struct HomeView: View {
    @StateObject private var viewModel = ThoughtViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showFolderSheet = false
    @State private var showSavedToast = false
    @State private var showThoughtDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 深色漸層背景
                LinearGradient(
                    colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer(minLength: 40)
                    // 標語
                    Text("想說什麼都可以，這裡安全接住你的每個情緒")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 玻璃感輸入框
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 10)
                        TextEditor(text: $viewModel.currentThought)
                            .frame(height: 120)
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(24)
                            .foregroundColor(.primary)
                            .focused($isInputFocused)
                    }
                    .padding(.horizontal)
                    
                    // 玻璃感按鈕
                    Button(action: {
                        viewModel.addThought()
                        isInputFocused = false
                        showSavedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showSavedToast = false
                        }
                    }) {
                        Text("接住我的情緒")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 8)
                    }
                    .padding(.horizontal)

                    // 水平滑動資料夾
                    if !viewModel.groupedThoughts.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(viewModel.groupedThoughts.keys).sorted(by: >), id: \.self) { date in
                                    FolderCard(date: date) {
                                        viewModel.selectedDate = date
                                        showFolderSheet = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                }
                
                // Toast 提示
                if showSavedToast {
                    VStack {
                        Spacer()
                        Text("已接住你的情緒！")
                            .font(.subheadline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .shadow(radius: 6)
                            .padding(.bottom, 60)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFolderSheet) {
                if let date = viewModel.selectedDate {
                    FolderSheetView(
                        thoughts: viewModel.groupedThoughts[date] ?? [],
                        date: date
                    )
                }
            }
            // 單一卡片內容 sheet
            .sheet(isPresented: $showThoughtDetail) {
                if let thought = viewModel.selectedThought {
                    GlassCardDetailView(thought: thought)
                }
            }
        }
        .onAppear {
            print("[DEBUG] HomeView loaded")
        }
    }
}

struct FolderCard: View {
    let date: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.8))
                Text(folderDateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 6)
        }
    }
}

struct FolderSheetView: View {
    let thoughts: [Thought]
    let date: Date
    @State private var selectedCard: Thought? = nil
    @State private var showAICharacterSheet = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text(folderDateFormatter.string(from: date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.leading)
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(thoughts) { thought in
                            GlassCard(
                                thought: thought,
                                isSelected: selectedCard?.id == thought.id,
                                onTap: {
                                    if selectedCard?.id == thought.id {
                                        selectedCard = nil
                                    } else {
                                        selectedCard = thought
                                    }
                                }
                            )
                        }
                    }
                    .padding(.bottom, selectedCard == nil ? 0 : 120)
                    .padding()
                }
            }
            if selectedCard != nil {
                FloatingActionBar(showAICharacterSheet: $showAICharacterSheet, onClose: { selectedCard = nil })
            }
        }
        .sheet(isPresented: $showAICharacterSheet) {
            AICharacterSelectionView(isPresented: $showAICharacterSheet)
        }
    }
}

struct GlassCard: View {
    let thought: Thought
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            print("[DEBUG] GlassCard tapped: \\(thought.content)")
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(thought.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(3)
                Text(thought.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: isSelected ? 16 : 8)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ?
                            AnyShapeStyle(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                            AnyShapeStyle(Color.clear),
                        lineWidth: 3
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(), value: isSelected)
        }
    }
}

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.white.opacity(0.7), Color.purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("✕ Close Chat")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                    }
                }
                Spacer()
                // 中間圓形漸層球體
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.purple.opacity(0.25), Color.blue.opacity(0.18), Color.white.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .shadow(radius: 24)
                        .blur(radius: 0.5)
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 6)
                        .frame(width: 170, height: 170)
                }
                .padding(.bottom, 32)
                Text("Speak your thoughts\nhomie")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                Spacer()
                // 可加下方輸入框或語音按鈕
            }
        }
    }
}

struct AICharacterSelectionView: View {
    @Binding var isPresented: Bool
    @State private var selected: AICharacter? = nil
    @State private var showAIChat = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Text("選擇一個AI角色")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(aiCharacters) { character in
                            VStack {
                                Image(character.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: selected?.id == character.id ? 90 : 70, height: selected?.id == character.id ? 90 : 70)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selected?.id == character.id ? Color.blue : Color.clear, lineWidth: 4)
                                    )
                                    .shadow(radius: selected?.id == character.id ? 12 : 4)
                                    .onTapGesture { selected = character }
                                Text(character.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                if let character = selected {
                    Text(character.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                Spacer()
                Button(action: {
                    // 進入AI對話
                    showAIChat = true
                }) {
                    Text("繼續")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selected == nil ? Color.gray : Color.blue)
                        .cornerRadius(20)
                        .opacity(selected == nil ? 0.5 : 1)
                }
                .disabled(selected == nil)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showAIChat, onDismiss: { isPresented = false }) {
            AIChatView()
        }
    }
}

// 修改 FloatingActionBar，點擊AI對話時彈出角色選擇
struct FloatingActionBar: View {
    @Binding var showAICharacterSheet: Bool
    var onClose: () -> Void
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 24) {
                Button(action: {
                    print("[DEBUG] AI對話按鈕被點擊！")
                    showAICharacterSheet = true
                }) {
                    ActionButton(icon: "person.text.rectangle", label: "AI對話")
                }
                Button(action: { print("[DEBUG] 轉化練習按鈕被點擊！") }) {
                    ActionButton(icon: "arrow.2.squarepath", label: "轉化練習")
                }
                Button(action: { print("[DEBUG] 引導式寫作按鈕被點擊！") }) {
                    ActionButton(icon: "pencil.and.outline", label: "引導式寫作")
                }
                Button(action: { print("[DEBUG] 燒毀掉按鈕被點擊！") }) {
                    ActionButton(icon: "flame", label: "燒毀掉")
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .shadow(radius: 12)
            .padding(.bottom, 32)
            .padding(.horizontal, 16)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: true)
        .onAppear {
            print("[DEBUG] FloatingActionBar rendered")
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white)
        }
        .padding(8)
    }
}

struct GlassCardDetailView: View {
    let thought: Thought
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text(thought.content)
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .multilineTextAlignment(.center)
            Text(thought.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        )
    }
}

#Preview {
    HomeView()
} 
