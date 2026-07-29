import Common
import TOMLKit

struct Mode: ConvenienceCopyable, Equatable, Sendable {
    /// Dead field: `parseMode` accepts only `binding`, so nothing ever sets this to non-nil, and
    /// nothing reads it. Deleting it means touching its four construction sites (`parseConfigV2`,
    /// `Mode.zero`, `testUtil`, `ConfigTest`) -- there is no other blocker.
    var name: String?
    var bindings: [String: HotkeyBinding]

    static let zero = Mode(name: nil, bindings: [:])
}

func parseModes(_ raw: TOMLValueConvertible, _ backtrace: TomlBacktrace, _ errors: inout [TomlParseError], _ mapping: [String: Key], requireMainMode: Bool = true) -> [String: Mode] {
    guard let rawTable = raw.table else {
        errors += [expectedActualTypeError(expected: .table, actual: raw.type, backtrace)]
        return [:]
    }
    var result: [String: Mode] = [:]
    for (key, value) in rawTable {
        result[key] = parseMode(value, backtrace + .key(key), &errors, mapping)
    }
    if requireMainMode, !result.keys.contains(mainModeId) {
        errors += [.semantic(backtrace, "Please specify '\(mainModeId)' mode")]
    }
    return result
}

func parseMode(_ raw: TOMLValueConvertible, _ backtrace: TomlBacktrace, _ errors: inout [TomlParseError], _ mapping: [String: Key]) -> Mode {
    guard let rawTable: TOMLTable = raw.table else {
        errors += [expectedActualTypeError(expected: .table, actual: raw.type, backtrace)]
        return .zero
    }

    var result: Mode = .zero
    for (key, value) in rawTable {
        let backtrace = backtrace + .key(key)
        switch key {
            case "binding":
                result.bindings = parseBindings(value, backtrace, &errors, mapping)
            default:
                errors += [unknownKeyError(backtrace)]
        }
    }
    return result
}
