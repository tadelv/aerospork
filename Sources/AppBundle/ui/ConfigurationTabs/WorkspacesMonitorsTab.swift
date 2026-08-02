import AppKit
import Common
import SwiftUI

struct WorkspacesMonitorsTab: View {
    @ObservedObject var viewModel: ConfigurationViewModel
    @State private var selection: ConfigurationViewModel.WorkspaceAssignmentRow.ID?

    var body: some View {
        VStack(spacing: 0) {
            monitors
            Divider()
            assignments
            ListActionBar(
                addHelp: "Pin a workspace to a monitor",
                removeHelp: "Remove the selected assignment",
                onAdd: { viewModel.addAssignment() },
                onRemove: selection == nil ? nil : {
                    if let id = selection { viewModel.removeAssignment(id: id) }
                    viewModel.scheduleAutoSave()
                    selection = nil
                },
                hint: "Hardware fingerprints already in your config are preserved — they just show up here under the monitor's name. A DisplayLink monitor reports no vendor or serial, so its UUID is the only thing that pins a workspace to that exact monitor. A workspace named here stays available even with no windows; a name bound to a shortcut does the same.",
            )
        }
    }

    /// Read-only, and the reason this pane exists at all: you cannot write a monitor assignment
    /// without knowing what the monitors are actually called and what their UUIDs are.
    private var monitors: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeader("Connected monitors", "display.2")

            // Same empty-state treatment as every other list in this window, rather than a section
            // header floating above nothing.
            if viewModel.liveMonitors.isEmpty {
                SettingsHint("No monitors reported yet — they appear as soon as macOS reports one, and their UUIDs are what pins a workspace to a physical panel.")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            } else {
                MonitorArrangementView(monitors: viewModel.liveMonitors)
                    .frame(height: 104)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.liveMonitors) { monitor in
                            HStack(spacing: 10) {
                                Text("\(monitor.position)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 14, alignment: .trailing)
                                Image(systemName: "display")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 6) {
                                        Text(monitor.name).fontWeight(.medium)
                                        if monitor.isMain {
                                            Badge("main", tone: .muted, help: "AeroSpork's main display — the monitor the “main” pattern matches.")
                                        }
                                    }
                                    Text(monitor.resolution)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                Spacer(minLength: 12)
                                if let uuid = monitor.uuid {
                                    Text(uuid.prefix(8) + "…")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                    CopyButton(value: uuid, help: "Copy monitor UUID\n\(uuid)")
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.045)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
        }
        .frame(maxHeight: 285)
    }

    @ViewBuilder
    private var assignments: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeader("Workspace assignments", "arrow.triangle.branch")

            if viewModel.assignments.isEmpty {
                ContentUnavailableViewCompat(
                    icon: "arrow.triangle.branch",
                    title: "No assignments",
                    message: "Workspaces land wherever they were last used. Add an assignment to pin one to a specific monitor.",
                    actionTitle: "Add assignment",
                    action: { viewModel.addAssignment() },
                )
            } else {
                let knownMonitorTokens = knownTokens
                Table(viewModel.assignments, selection: $selection) {
                    // Neither of the two data columns has anywhere for a click to land: both are
                    // filled edge to edge by a control that claims the mouseDown before the Table's
                    // own row-selection handler ever sees it. This column carries no control, so a
                    // click here reaches the Table the same way it does on WindowRulesTab's
                    // plain-Text cells, which have never had this problem. It's decorative, not a
                    // separate affordance, so VoiceOver skips it and lets the Table's native row
                    // accessibility (which already knows the row's real content) speak instead.
                    // Not `line.3.horizontal`: that glyph reads as a drag-to-reorder handle, and
                    // this row can't be reordered.
                    TableColumn("") { row in
                        Image(systemName: "circle")
                            .font(.system(size: 6))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .width(20)

                    TableColumn("Workspace") { row in
                        // Workspace names are a word; an edge-to-edge field reads as a form for
                        // prose. Capped, the slack goes to the monitor column instead.
                        SettingsField("Workspace name", prompt: "web", text: binding(row.id, \.workspace))
                            .frame(maxWidth: 180, alignment: .leading)
                    }
                    .width(min: 110, ideal: 140, max: 200)

                    TableColumn("Monitor") { row in
                        HStack(spacing: 6) {
                            // A Table column header is not a control label, so without this the
                            // picker is announced as an unnamed pop-up button.
                            Picker("Monitor for this workspace", selection: binding(row.id, \.monitor)) {
                                Text("Main").tag("main")
                                Text("Non-main").tag("secondary")
                                Divider()
                                ForEach(viewModel.liveMonitors) { m in
                                    Text("Position \(m.position) — left to right").tag(String(m.position))
                                }
                                Divider()
                                ForEach(viewModel.liveMonitors) { m in
                                    Text(m.uuid == nil ? m.name : "\(m.name) — matches by name").tag(m.name)
                                    if let uuid = m.uuid { Text("\(m.name) — exact display").tag(uuid) }
                                }
                                // Keep whatever is already in the config selectable, even if it's a
                                // regex, a sequence number, or a monitor that isn't connected now.
                                let current = row.monitor
                                if !current.isEmpty, !knownMonitorTokens.contains(current) {
                                    Divider()
                                    Text(current).tag(current)
                                }
                            }
                            .labelsHidden()
                            // Hug the selected label; a pop-up stretched across the column reads
                            // as a text field and leaves nowhere for a row click to land.
                            .fixedSize()
                            if row.isComplex {
                                Badge(
                                    "complex",
                                    help: "Written with more detail than this editor can show — use Raw TOML to change its fallback list or hardware fingerprint.",
                                )
                            }
                            // Let the picker hug its label instead of claiming the whole column;
                            // the slack doubles as somewhere for a row-selecting click to land.
                            Spacer(minLength: 0)
                        }
                    }
                }
                .tableStyle(.inset)
                // Kept alongside the handle column above, not replaced by it: this is the path for
                // a row already selected by some other means (VoiceOver rotor, a future keyboard-only
                // flow) to still be deletable without a mouse.
                .onDeleteCommand {
                    if let id = selection { viewModel.removeAssignment(id: id); selection = nil }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var knownTokens: Set<String> {
        var t: Set<String> = ["main", "secondary"]
        for m in viewModel.liveMonitors {
            t.insert(String(m.position))
            t.insert(m.name)
            if let uuid = m.uuid { t.insert(uuid) }
        }
        return t
    }

    private func binding(
        _ id: ConfigurationViewModel.WorkspaceAssignmentRow.ID,
        _ keyPath: WritableKeyPath<ConfigurationViewModel.WorkspaceAssignmentRow, String>,
    ) -> Binding<String> {
        Binding(
            get: { viewModel.assignments.first { $0.id == id }?[keyPath: keyPath] ?? "" },
            set: { newValue in
                guard let i = viewModel.assignments.firstIndex(where: { $0.id == id }) else { return }
                viewModel.assignments[i][keyPath: keyPath] = newValue
                viewModel.markAsModified()
                viewModel.scheduleAutoSave()
            },
        )
    }
}

/// A true-to-arrangement schematic. Relative origins and sizes come from AppKit, then scale into
/// the available width as one group; this makes “Position 1” and “Main” visually concrete without
/// pretending the cards are pixel-perfect display previews.
struct MonitorArrangementView: View {
    let monitors: [ConfigurationViewModel.MonitorRow]

    private var bounds: CGRect {
        monitors.reduce(CGRect.null) { $0.union($1.rect) }
    }

    var body: some View {
        GeometryReader { geometry in
            let inset: CGFloat = 12
            let safeBounds = bounds.isNull || bounds.width <= 0 || bounds.height <= 0
                ? CGRect(x: 0, y: 0, width: 1, height: 1)
                : bounds
            let scale = min(
                (geometry.size.width - inset * 2) / safeBounds.width,
                (geometry.size.height - inset * 2) / safeBounds.height,
            )
            // One axis always has slack (the aspect ratios rarely match); split it so the
            // arrangement sits centered rather than pinned to the top-left corner.
            let xOffset = (geometry.size.width - safeBounds.width * scale) / 2
            let yOffset = (geometry.size.height - safeBounds.height * scale) / 2

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.035))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.22), lineWidth: 1)

                ForEach(monitors) { monitor in
                    let width = max(1, monitor.rect.width * scale)
                    let height = max(1, monitor.rect.height * scale)
                    // A real arrangement scales some panels down to a sliver (an ultrawide above
                    // two 4Ks), and `.frame` does not clip: a full three-line label drawn into a
                    // 20pt box spills over every neighbour. Degrade the label to what fits, and
                    // clip so nothing can ever escape its panel.
                    ViewThatFits {
                        VStack(spacing: 2) {
                            positionRow(monitor)
                            nameText(monitor)
                            Text(monitor.resolution)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        VStack(spacing: 2) {
                            positionRow(monitor)
                            nameText(monitor)
                        }
                        positionRow(monitor)
                    }
                    .padding(4)
                    .frame(width: width, height: height)
                    .clipped()
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(monitor.isMain ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: monitor.isMain ? 2 : 1)
                    }
                    .position(
                        x: xOffset + (monitor.rect.midX - safeBounds.minX) * scale,
                        y: yOffset + (monitor.rect.midY - safeBounds.minY) * scale,
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Position \(monitor.position), \(monitor.name), \(monitor.resolution)\(monitor.isMain ? ", main display" : "")")
                }
            }
        }
    }

    private func positionRow(_ monitor: ConfigurationViewModel.MonitorRow) -> some View {
        HStack(spacing: 4) {
            Text("\(monitor.position)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
            if monitor.isMain { Text("main").font(.caption2).foregroundStyle(Color.accentColor) }
        }
    }

    private func nameText(_ monitor: ConfigurationViewModel.MonitorRow) -> some View {
        Text(monitor.name)
            .font(.caption2)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}
