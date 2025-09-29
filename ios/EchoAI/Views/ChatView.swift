//
//  ChatView.swift
//  EchoAI
//
//  AI chat interface with voice input and message history
//

import SwiftUI
import AVFoundation

struct ChatView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var isTyping = false
    @State private var showingVoiceSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(echoService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: echoService.messages.count) { _ in
                        if let lastMessage = echoService.messages.last {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                inputArea
            }
            .navigationTitle("Chat with Echo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingVoiceSettings = true }) {
                        Image(systemName: "mic.slash")
                    }
                }
            }
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Voice Recording Indicator
            if isRecording {
                recordingIndicator
            }
            
            HStack(spacing: 12) {
                // Voice Input Button
                Button(action: toggleVoiceRecording) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(isRecording ? .red : .blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isRecording ? .red.opacity(0.2) : .blue.opacity(0.2))
                        )
                }
                .disabled(isTyping)
                
                // Text Input
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                    
                    if !messageText.isEmpty {
                        Button("Send") {
                            sendMessage()
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.blue.opacity(0.2))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Recording Indicator
    private var recordingIndicator: some View {
        HStack {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .opacity(0.8)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
            
            Text("Listening...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Tap to stop")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID(),
            text: message,
            isFromUser: true,
            timestamp: Date()
        )
        echoService.addMessage(userMessage)
        
        // Show typing indicator
        isTyping = true
        
        // Send to AI
        echoService.sendMessage(message) { response in
            DispatchQueue.main.async {
                isTyping = false
                
                let aiMessage = ChatMessage(
                    id: UUID(),
                    text: response,
                    isFromUser: false,
                    timestamp: Date()
                )
                echoService.addMessage(aiMessage)
            }
        }
    }
    
    private func toggleVoiceRecording() {
        if isRecording {
            echoService.stopVoiceRecording()
        } else {
            echoService.startVoiceRecording { transcript in
                messageText = transcript
                sendMessage()
            }
        }
        isRecording.toggle()
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isFromUser ? 
                                  LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                  LinearGradient(colors: [.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    )
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.gray)
                        .frame(width: 6, height: 6)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationOffset = -4
        }
    }
}

// MARK: - Voice Settings View
struct VoiceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var echoService: EchoService
    
    var body: some View {
        NavigationView {
            Form {
                Section("Voice Input") {
                    Toggle("Enable Voice Input", isOn: .constant(true))
                    Toggle("Wake Word Detection", isOn: .constant(true))
                    
                    VStack(alignment: .leading) {
                        Text("Microphone Sensitivity")
                        Slider(value: .constant(0.5), in: 0...1)
                    }
                }
                
                Section("Voice Output") {
                    Toggle("Enable Voice Responses", isOn: .constant(true))
                    
                    Picker("Voice Speed", selection: .constant(1.0)) {
                        Text("Slow").tag(0.5)
                        Text("Normal").tag(1.0)
                        Text("Fast").tag(1.5)
                    }
                }
                
                Section("Wake Words") {
                    Text("Current: 'Hey Echo'")
                    Button("Train Custom Wake Word") {
                        // Train custom wake word
                    }
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(EchoService())
}
