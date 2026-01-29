import SwiftUI

struct TerminalView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var gateway = GatewayService.shared
    @State private var commandInput = ""
    @State private var serverAddress = "ws://localhost:18789"
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection status bar
                connectionStatusBar

                // Log output area
                logOutputArea

                // Command input area
                commandInputArea
            }
            .background(Color.black)
            .navigationTitle("Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Copy all logs
                        Button {
                            copyAllLogs()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(TodoTheme.textSecondary)
                        }

                        // Clear logs
                        Button {
                            gateway.clearLogs()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(TodoTheme.textSecondary)
                        }

                        // Settings
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(TodoTheme.textSecondary)
                        }
                    }
                }
            }
            .toolbarBackground(TodoTheme.backgroundPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            TerminalSettingsSheet(
                serverAddress: $serverAddress,
                onConnect: {
                    Task {
                        await connectToServer()
                    }
                },
                onDisconnect: {
                    gateway.disconnect()
                }
            )
        }
    }

    // MARK: - Connection Status Bar

    private var connectionStatusBar: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(gateway.connectionState.displayName)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(TodoTheme.textSecondary)

            Spacer()

            // Quick connect/disconnect
            if gateway.connectionState == .disconnected {
                Button("Connect") {
                    Task { await connectToServer() }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TodoTheme.accentPurple)
            } else if gateway.connectionState == .connected {
                Text(serverAddress)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(TodoTheme.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(TodoTheme.backgroundSecondary)
    }

    private var statusColor: Color {
        switch gateway.connectionState {
        case .disconnected: .gray
        case .connecting: .orange
        case .connected: .green
        case .error: .red
        }
    }

    // MARK: - Log Output Area

    private var logOutputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(gateway.logs) { log in
                        LogEntryRow(log: log)
                            .id(log.id)
                    }

                    // Processing indicator
                    if gateway.isProcessingCommand {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                                .tint(TodoTheme.accentPurple)

                            Text("Processing...")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(TodoTheme.textTertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }

                    // Anchor for auto-scroll
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(12)
            }
            .onChange(of: gateway.logs.count) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Command Input Area

    private var commandInputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                // Prompt
                Text(">")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(TodoTheme.accentPurple)

                // Input field
                TextField("Enter command...", text: $commandInput)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(TodoTheme.accentPurple)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendCommand()
                    }
                    .disabled(gateway.connectionState != .connected)

                // Send / Abort button
                if gateway.isProcessingCommand {
                    Button {
                        Task { await gateway.abortCommand() }
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.red)
                    }
                } else {
                    Button {
                        sendCommand()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                commandInput.isEmpty || gateway.connectionState != .connected
                                    ? Color.white.opacity(0.3)
                                    : TodoTheme.accentPurple
                            )
                    }
                    .disabled(commandInput.isEmpty || gateway.connectionState != .connected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(TodoTheme.backgroundSecondary)
        }
    }

    // MARK: - Actions

    private func connectToServer() async {
        guard let url = URL(string: serverAddress) else {
            gateway.addLog(.error, "Invalid server address")
            return
        }
        await gateway.connect(to: url)
    }

    private func sendCommand() {
        let command = commandInput.trimmingCharacters(in: .whitespaces)
        guard !command.isEmpty else { return }

        commandInput = ""
        Task {
            await gateway.sendCommand(command)
        }
    }

    private func copyAllLogs() {
        let allText = gateway.logs.map { log in
            let timestamp = log.timestamp.formatted(date: .omitted, time: .standard)
            let source = log.source.map { "[\($0)] " } ?? ""
            return "\(timestamp) \(log.level.rawValue) \(source)\(log.message)"
        }.joined(separator: "\n")

        UIPasteboard.general.string = allText
        gateway.addLog(.success, "Copied \(gateway.logs.count) log entries to clipboard")
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let log: LogEntry
    @State private var showCopied = false

    private var levelColor: Color {
        Color(hex: log.level.color)
    }

    private var formattedLog: String {
        let timestamp = log.timestamp.formatted(date: .omitted, time: .standard)
        let source = log.source.map { "[\($0)] " } ?? ""
        return "\(timestamp) \(log.level.rawValue) \(source)\(log.message)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(log.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(TodoTheme.textTertiary)

            // Level badge
            Text(log.level.rawValue)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(levelColor)
                .frame(width: 44)

            // Source (if any)
            if let source = log.source {
                Text("[\(source)]")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(TodoTheme.accentPurple.opacity(0.8))
            }

            // Message
            Text(log.message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(messageColor)
                .textSelection(.enabled)

            Spacer(minLength: 0)

            // Copy indicator
            if showCopied {
                Text("Copied!")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = log.message
                withAnimation { showCopied = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run {
                        withAnimation { showCopied = false }
                    }
                }
            } label: {
                Label("Copy Message", systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = formattedLog
                withAnimation { showCopied = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await MainActor.run {
                        withAnimation { showCopied = false }
                    }
                }
            } label: {
                Label("Copy Full Line", systemImage: "doc.on.doc.fill")
            }
        }
    }

    private var messageColor: Color {
        switch log.source {
        case "user": TodoTheme.accentPink
        case "assistant": .white
        default: Color(hex: log.level.color)
        }
    }
}

// MARK: - Terminal Settings Sheet

struct TerminalSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var serverAddress: String
    var onConnect: () -> Void
    var onDisconnect: () -> Void

    @State private var gateway = GatewayService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Gateway Server") {
                    TextField("Server Address", text: $serverAddress)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(gateway.connectionState.displayName)
                            .foregroundStyle(statusColor)
                    }
                }

                Section {
                    if gateway.connectionState == .connected {
                        Button("Disconnect", role: .destructive) {
                            onDisconnect()
                        }
                    } else {
                        Button("Connect") {
                            onConnect()
                            dismiss()
                        }
                    }
                }

                Section("Presets") {
                    Button("Local (localhost:18789)") {
                        serverAddress = "ws://localhost:18789"
                    }
                    Button("LAN Discovery") {
                        // TODO: Implement Bonjour discovery
                        serverAddress = "ws://gateway.local:18789"
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private var statusColor: Color {
        switch gateway.connectionState {
        case .disconnected: .gray
        case .connecting: .orange
        case .connected: .green
        case .error: .red
        }
    }
}

// MARK: - Preview

#Preview {
    TerminalView()
        .environment(AppModel())
}
