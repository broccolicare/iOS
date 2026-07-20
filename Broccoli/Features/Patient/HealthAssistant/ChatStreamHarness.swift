//
//  ChatStreamHarness.swift
//  Broccoli
//
//  P1-10 — temporary end-to-end harness for the Health Assistant stream.
//
//  🛑 DELETE BEFORE MERGE. This exists only to prove one turn streams end-to-end
//  against staging before any UI exists. Once Phase 3 wires ChatViewModel, this
//  file has no reason to survive.
//
//  ⚠️ Staging may be backed by production data — use SYNTHETIC DATA ONLY
//  (questions doc Q4).
//

#if DEBUG

import Combine
import SwiftUI

@MainActor
final class ChatStreamHarnessModel: ObservableObject {
    @Published var log: String = ""
    @Published var isRunning = false
    @Published var conversationId: Int?

    private let service = ChatService(sseClient: SSEClient())

    func send(_ message: String) {
        guard !isRunning else { return }
        isRunning = true
        append("▶️ POST /chatbot/turn  message=\"\(message)\"  conversation_id=\(conversationId.map(String.init) ?? "omitted")")

        Task {
            var tokenCount = 0
            var text = ""

            do {
                for try await event in service.streamTurn(message: message, conversationId: conversationId) {
                    switch event {
                    case .token(let chunk):
                        tokenCount += 1
                        text += chunk
                        append("token[\(tokenCount)]: \(chunk.debugDescription)")

                    case .toolResult(let tool, let data):
                        let json = String(data: data, encoding: .utf8) ?? "<undecodable>"
                        append("tool_result: \(tool) → \(json)")

                    case .done(let done):
                        conversationId = done.conversationId
                        append("""
                        done: status=\(done.status.rawValue) \
                        conversation_id=\(done.conversationId) \
                        conversation_status=\(done.conversationStatus?.rawValue ?? "null") \
                        error_code=\(done.errorCode?.rawValue ?? "null")
                        """)
                    }
                }
                append("✅ stream closed — \(tokenCount) token event(s)")
                append("full text: \(text)")
            } catch {
                append("❌ \(error.localizedDescription)")
            }

            isRunning = false
        }
    }

    private func append(_ line: String) {
        print("[ChatHarness] \(line)")
        log += line + "\n\n"
    }
}

struct ChatStreamHarnessView: View {
    @StateObject private var model = ChatStreamHarnessModel()
    @State private var message = "hello"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chat stream harness (P1-10)")
                .font(.headline)

            Text("conversation_id: \(model.conversationId.map(String.init) ?? "none yet")")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("message", text: $message)
                    .textFieldStyle(.roundedBorder)
                Button("Send") { model.send(message) }
                    .disabled(model.isRunning || message.isEmpty)
            }

            if model.isRunning {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("waiting — the socket stays silent until the whole turn completes")
                        .font(.caption)
                }
            }

            ScrollView {
                Text(model.log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
}

#Preview {
    ChatStreamHarnessView()
}

#endif
