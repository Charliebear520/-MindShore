import SwiftUI

fileprivate let folderDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.selectedDate = nil
                        showFolderSheet = true
                    }) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            // 資料夾 sheet
            .sheet(isPresented: $showFolderSheet) {
                if let date = viewModel.selectedDate {
                    FolderSheetView(
                        thoughts: viewModel.groupedThoughts[date] ?? [],
                        date: date
                    )
                } else {
                    // 全部記錄列表
                    AllFolderListView(viewModel: viewModel, onCardTap: { thought in
                        viewModel.selectedThought = thought
                        showThoughtDetail = true
                    })
                }
            }
            // 單一卡片內容 sheet
            .sheet(isPresented: $showThoughtDetail) {
                if let thought = viewModel.selectedThought {
                    GlassCardDetailView(thought: thought)
                }
            }
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
                    .padding(.bottom, selectedCard == nil ? 0 : 120) // 給懸浮Bar空間
                    .padding()
                }
            }
            // 懸浮Bar
            if let selected = selectedCard {
                FloatingActionBar(onClose: { selectedCard = nil })
            }
        }
    }
}

struct GlassCard: View {
    let thought: Thought
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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

struct FloatingActionBar: View {
    var onClose: () -> Void
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 24) {
                ActionButton(icon: "person.text.rectangle", label: "AI對話")
                ActionButton(icon: "arrow.2.squarepath", label: "轉化練習")
                ActionButton(icon: "pencil.and.outline", label: "引導式寫作")
                ActionButton(icon: "flame", label: "燒毀掉")
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
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    var body: some View {
        Button(action: {
            // 點擊事件
        }) {
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

struct AllFolderListView: View {
    @ObservedObject var viewModel: ThoughtViewModel
    let onCardTap: (Thought) -> Void
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.groupedThoughts.keys).sorted(by: >), id: \.self) { date in
                    Section(header: Text(folderDateFormatter.string(from: date)).foregroundColor(.primary)) {
                        ForEach(viewModel.groupedThoughts[date] ?? []) { thought in
                            Button(action: { onCardTap(thought) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(thought.content)
                                        .font(.body)
                                        .lineLimit(2)
                                    Text(thought.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                if let t = viewModel.groupedThoughts[date]?[index] {
                                    viewModel.deleteThought(t)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的情緒")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }
}

#Preview {
    HomeView()
} 
