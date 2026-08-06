/// Closest matches to `input` from `candidates`, best first, for "did you mean…?" hints.
///
/// A bare `Unrecognized subcommand 'workspaces'` is a dead end: it says what is wrong and nothing
/// about what to do, and the user's next move is to go read `--help` and scan 36 entries for a typo.
///
/// Deliberately conservative. It suggests only near misses -- a prefix match, or an edit distance
/// under a third of the word's length -- and returns at most three. A long list of bad guesses is
/// noise, and confidently proposing an unrelated command is worse than proposing nothing.
public func didYouMean(_ input: String, from candidates: [String], limit: Int = 3) -> [String] {
  let lower = input.lowercased()
  let threshold = max(1, lower.count / 3)
  return candidates
    .map { (name: $0, distance: editDistance(lower, $0.lowercased())) }
    .filter { $0.distance <= threshold || $0.name.hasPrefix(lower) || lower.hasPrefix($0.name) }
    .sorted { ($0.distance, $0.name) < ($1.distance, $1.name) }
    .prefix(limit)
    .map(\.name)
}

/// Levenshtein distance, two-row variant: O(a*b) time but only O(b) space, and the inputs here are
/// command names, so the constant factors do not matter.
func editDistance(_ a: String, _ b: String) -> Int {
  let a = Array(a), b = Array(b)
  if a.isEmpty { return b.count }
  if b.isEmpty { return a.count }
  var prev = Array(0...b.count)
  var curr = [Int](repeating: 0, count: b.count + 1)
  for i in 1...a.count {
    curr[0] = i
    for j in 1...b.count {
      let substitution = prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)
      curr[j] = min(prev[j] + 1, curr[j - 1] + 1, substitution)
    }
    swap(&prev, &curr)
  }
  return prev[b.count]
}

/// Renders a hint as a trailing sentence, or "" when there is nothing worth suggesting.
public func didYouMeanSuffix(_ input: String, from candidates: [String]) -> String {
  let matches = didYouMean(input, from: candidates)
  guard !matches.isEmpty else { return "" }
  return matches.count == 1
    ? ". Did you mean '\(matches[0])'?"
    : ". Did you mean one of: \(matches.map { "'\($0)'" }.joined(separator: ", "))?"
}
