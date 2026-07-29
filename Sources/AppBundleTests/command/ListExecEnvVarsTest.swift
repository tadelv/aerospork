@testable import AppBundle
import Common
import XCTest

@MainActor
final class ListExecEnvVarsTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    private func listEnvVars(_ command: String) async throws -> [String] {
        let cmd = parseCommand(command).cmdOrDie
        return try await cmd.run(.defaultEnv, CmdStdin.emptyStdin).stdout.sorted()
    }

    func testParse() {
        testParseCommandSucc("list-exec-env-vars", ListExecEnvVarsCmdArgs(rawArgs: []))
        testParseCommandSucc("list-exec-env-vars --show-secrets", ListExecEnvVarsCmdArgs(rawArgs: []).copy(\.showSecrets, true))
    }

    func testSecretLookingNamesAreRedacted() async throws {
        config.execConfig.envVariables = [
            "OPENAI_API_KEY": "sk-leak",
            "SENTRY_AUTH_TOKEN": "auth-leak",
            "PORKBUN_API_SECRET": "secret-leak",
            "MYSQL_PASSWORD": "pw-leak",
            "AWS_CREDENTIAL_FILE": "cred-leak",
            "SSH_PRIVATE": "priv-leak",
            "PATH": "/usr/bin",
        ]
        assertEquals(try await listEnvVars("list-exec-env-vars"), [
            "AWS_CREDENTIAL_FILE=<redacted>",
            "MYSQL_PASSWORD=<redacted>",
            "OPENAI_API_KEY=<redacted>",
            "PATH=/usr/bin",
            "PORKBUN_API_SECRET=<redacted>",
            "SENTRY_AUTH_TOKEN=<redacted>",
            "SSH_PRIVATE=<redacted>",
        ])
    }

    func testShowSecretsOptsBackIn() async throws {
        config.execConfig.envVariables = ["OPENAI_API_KEY": "sk-leak", "PATH": "/usr/bin"]
        assertEquals(try await listEnvVars("list-exec-env-vars --show-secrets"), [
            "OPENAI_API_KEY=sk-leak",
            "PATH=/usr/bin",
        ])
    }
}
