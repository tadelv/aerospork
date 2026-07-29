import AppKit
import Common

struct WorkspaceBackAndForthCommand: Command {
    let args: WorkspaceBackAndForthCmdArgs

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        // `prev?.focusWorkspace() != nil` tested that a previous workspace *existed* and threw away
        // whether focusing it worked, so the command reported success for a focus that failed and
        // failed with no message at all when there was nothing to go back to.
        guard let prevFocusedWorkspace else {
            return io.err("No previous workspace to go back to -- switch workspaces at least once first")
        }
        return prevFocusedWorkspace.focusWorkspace()
    }
}
