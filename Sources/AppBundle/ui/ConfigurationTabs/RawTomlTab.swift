import Common
import SwiftUI

/// The escape hatch that makes "nothing is unreachable from the GUI" true. Anything the structured
/// panes can't express — per-monitor gap arrays, hardware fingerprints, custom key-code mappings —
/// is editable here, validated against the same `parseConfig` the app uses at startup.
///
/// Deliberately NOT live-applied: half-typed TOML is invalid most of the time, so this applies
/// explicitly. While this pane has unsaved edits it takes precedence over every other pane.
struct RawTomlTab: View {
  struct SectionHeader: Identifiable {
    let line: Int
    let label: String
    var id: Int { line }
  }

  @ObservedObject var viewModel: ConfigurationViewModel
  @State private var validationDiagnostic: ConfigurationWriter.ValidationDiagnostic?
  @State private var validationPending = false
  @State private var cursorLine = 1
  @State private var cursorColumn = 1
  @State private var jumpToLine: Int?
  @State private var configPath = ""
  @State private var backups: [URL] = []
  @State private var sectionHeaders: [SectionHeader] = []

  var body: some View {
    VStack(spacing: 0) {
      pathBar
      Divider()
      // Not `TextEditor`: it applies macOS text substitutions, and smart quotes turn the `'`
      // in `key = 'focus left'` into `'`, which is not valid TOML.
      CodeEditor(
        text: $viewModel.rawToml,
        jumpToLine: jumpToLine,
        errorLine: validationDiagnostic?.line
      ) { line, column in
        cursorLine = line
        cursorColumn = column
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(nsColor: .textBackgroundColor))
      actionBar
    }
    // Parsing a full config on every keystroke makes fast typing contend with the main-actor
    // SwiftUI update that produced it. `task(id:)` gives us cancellation for free: only the
    // last buffer in a burst is validated, while Apply remains disabled during the short wait.
    .task(id: viewModel.rawToml) {
      let needsValidation = viewModel.rawTomlEdited
      validationPending = needsValidation
      guard needsValidation else {
        validationDiagnostic = nil
        sectionHeaders = Self.sections(in: viewModel.rawToml)
        return
      }
      validationDiagnostic = nil
      try? await Task.sleep(for: .milliseconds(180))
      guard !Task.isCancelled else { return }
      sectionHeaders = Self.sections(in: viewModel.rawToml)
      validationDiagnostic = ConfigurationWriter.diagnostic(viewModel.rawToml)
      validationPending = false
    }
    .task {
      // Both calls touch the file system. Raw TOML publishes on every keystroke, so leaving
      // them in computed view properties turned typing into repeated directory scans.
      configPath = (findCustomConfigUrl().urlOrNil ?? defaultConfigUrl).path(percentEncoded: false)
      backups = viewModel.configBackups()
    }
  }

  private var pathBar: some View {
    HStack(spacing: 8) {
      Image(systemName: "doc.plaintext").foregroundStyle(.secondary)
      Text(configPath)
        .font(.system(.callout, design: .monospaced))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.head)
        .textSelection(.enabled)
      CopyButton(value: configPath, help: "Copy config path")
      Spacer(minLength: 12)
      Text("Ln \(cursorLine), Col \(cursorColumn)")
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize()
      Menu("Sections…") {
        ForEach(sectionHeaders) { header in
          Button {
            jump(to: header.line)
          } label: {
            Text(header.label).font(.system(.body, design: .monospaced))
          }
        }
      }
      .menuStyle(.borderlessButton)
      .fixedSize()
      .disabled(sectionHeaders.isEmpty)
      .help("Jump to a TOML section")
      // Both were permanent menu bar rows. They belong next to the text they act on.
      Button("Open in \(getTextEditorToOpenConfig().deletingPathExtension().lastPathComponent)") {
        openConfigInExternalEditor()
      }
      .buttonStyle(.borderless)
      .help("External edits are picked up automatically — the config file is watched")

      // Kept only because the watcher cannot arm on a file that does not exist yet: someone
      // who creates their first config entirely outside the app has no other way in.
      if let token: RunSessionGuard = .isServerEnabled {
        Button("Reload") {
          runDetached("rawTomlApply") {
            try await runSession(.menuBarButton, token) { _ = reloadConfig() }
            viewModel.revertChanges()
          }
        }
        .buttonStyle(.borderless)
        .help("Only needed for a config file created outside the app — every other edit is picked up on save.")
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .background(.bar)
  }

  private var actionBar: some View {
    VStack(spacing: 0) {
      Divider()
      HStack(alignment: .center, spacing: 12) {
        status
        Spacer(minLength: 12)

        // The only way back to a previous config from inside the app. Loading into the
        // editor rather than writing straight over the file means the user sees what they
        // are restoring, and Apply backs up the current file first.
        Menu("Restore…") {
          ForEach(backups, id: \.self) { url in
            Button(Self.label(for: url)) { viewModel.loadBackup(url) }
          }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(backups.isEmpty)
        .help("Load a previous version of this config into the editor")

        Button("Revert") { viewModel.revertChanges() }
          .disabled(!viewModel.rawTomlEdited)
        Button("Apply") {
          Task {
            viewModel.rawTomlApplyRequested = true
            await viewModel.saveConfiguration()
            backups = viewModel.configBackups()
          }
        }
        .keyboardShortcut("s", modifiers: .command)
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.rawTomlEdited || validationPending || validationDiagnostic != nil)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
    }
    .background(.bar)
  }

  @ViewBuilder
  private var status: some View {
    if validationPending {
      StatusLabel("Checking…", kind: .neutral)
    } else if let diagnostic = validationDiagnostic {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        StatusLabel(diagnostic.message, kind: .error)
          // Only the error branch wraps: it carries a parser message with a line number,
          // which is the one status here that is worth selecting and pasting.
          .textSelection(.enabled)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
        if let line = diagnostic.line {
          Button("Go to line \(line)") {
            jump(to: line)
          }
          .buttonStyle(.borderless)
          .fixedSize()
        }
      }
    } else if viewModel.rawTomlEdited {
      StatusLabel("Valid — press Apply (⌘S) to write it", kind: .ok)
    } else {
      StatusLabel("Matches the file on disk", kind: .neutral)
    }
  }

  /// `…toml.20260728-163000.backup` -> "28 Jul 2026 at 16:30". Falls back to the raw name rather
  /// than hiding a backup we can't parse -- an unreadable label still restores fine.
  private static let backupTimestampParser: DateFormatter = {
    let parser = DateFormatter()
    parser.locale = Locale(identifier: "en_US_POSIX")
    parser.calendar = Calendar(identifier: .gregorian)
    parser.dateFormat = "yyyyMMdd-HHmmss"
    return parser
  }()

  private static func label(for url: URL) -> String {
    let stamp = url.deletingPathExtension().pathExtension // the timestamp component
    guard let date = backupTimestampParser.date(from: stamp) else { return url.lastPathComponent }
    return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
  }

  private func jump(to line: Int) {
    // Clearing first makes repeated clicks on the same destination actionable.
    jumpToLine = nil
    Task { @MainActor in jumpToLine = line }
  }

  static func sections(in text: String) -> [SectionHeader] {
    text.split(separator: "\n", omittingEmptySubsequences: false).enumerated().compactMap { offset, rawLine in
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      guard line.first == "[" else { return nil }
      guard let end = sectionHeaderEnd(in: line) else { return nil }
      let after = line[end...].trimmingCharacters(in: .whitespaces)
      guard after.isEmpty || after.hasPrefix("#") else { return nil }
      return SectionHeader(line: offset + 1, label: String(line[..<end]))
    }
  }

  /// Finds a table header's closing bracket while respecting quoted TOML keys. A plain
  /// `range(of: "]")` loses valid headers such as `["display]rules"]`, so those sections used to
  /// be absent from the jump menu even though the parser accepted the document.
  private static func sectionHeaderEnd(in line: String) -> String.Index? {
    let arrayHeader = line.hasPrefix("[[")
    var index = line.index(line.startIndex, offsetBy: arrayHeader ? 2 : 1)
    var quote: Character?
    var escaped = false

    while index < line.endIndex {
      let character = line[index]
      if let activeQuote = quote {
        if escaped {
          escaped = false
        } else if activeQuote == "\"", character == "\\" {
          escaped = true
        } else if character == activeQuote {
          quote = nil
        }
        index = line.index(after: index)
        continue
      }
      if character == "\"" || character == "'" {
        quote = character
        index = line.index(after: index)
        continue
      }
      if character == "]" {
        let afterFirst = line.index(after: index)
        if !arrayHeader { return afterFirst }
        if afterFirst < line.endIndex, line[afterFirst] == "]" {
          return line.index(after: afterFirst)
        }
      }
      index = line.index(after: index)
    }
    return nil
  }
}
