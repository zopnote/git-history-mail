import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

Future<void> main(List<String> raw) => runCommand(
  Command(
    // STEPFLOW_TODO: Add use to format syntax as usage syntax.
    // Add <argument>-usage to use syntax info.
    use: "git-mail",
    // STEPFLOW_TODO: Add short description of cmds.
    description:
        "Tool to override the old mail inside a repository branch. "
        "Useful, when your account mail has changed and you're "
        "Github history doesn't show your commit history as expected.",
    flags: [
      BoolFlag(
        name: "include_tags",
        description: "If all tags will be affected.",
        value: false,
      ),
      BoolFlag(
        name: "all_branches",
        description: "If all branches or just the current will be affected.",
        value: false,
      ),
      TextFlag(
        name: "new_mail",
        description: "The new mail the old will get replaced with.",
      ),
      TextFlag(
        name: "old_mail",
        description: "The old mail that will be replaced.",
      ),
      BoolFlag(
        name: "force",
        description: "Force the operation even if a backup already exists.",
        value: false,
      ),
    ],
    run: (info) async {
      final String newMail = info.getFlag("new_mail").value;
      final String oldMail = info.getFlag("old_mail").value;
      // STEPFLOW_TODO: Display implicit default value of bools in syntax message.
      final bool allBranches = info.getFlag("all_branches").value;
      final bool includeTags = info.getFlag("include_tags").value;
      final bool force = info.getFlag("force").value;
      // STEPFLOW_TODO: Remove the default help flag.
      final bool help = info.getFlag("help").value;

      if (help || newMail.isEmpty && oldMail.isEmpty) {
        // STEPFLOW_TODO: Add the formatSyntax padding.
        return Response(info.formatSyntax());
      }
      if (newMail.isEmpty) {
        return Response(
          "Please specify a new mail with --new_mail.",
          Level.normal,
        );
      }
      if (oldMail.isEmpty) {
        return Response(
          "Please specify your old mail with --old_mail.",
          Level.normal,
        );
      }

      return await runWorkflow(
        Chain(
          steps: [
            Shell(
              program: "git",
              arguments: [
                // STEPFLOW_TODO: Move Shell to app frame and argument constructor.
                "filter-branch",
                ..._get(force, "-f"),
                "--env-filter",
                _gitScript(oldMail, newMail),
                "--tag-name-filter",
                "cat",
                "--",
                ..._get(allBranches, "--branches", "HEAD"),
                ..._get(includeTags, "--tags"),
              ],
              onStdout: (context, chars) => print(String.fromCharCodes(chars)),
              onStderr: (context, chars) => context.send(
                Response(String.fromCharCodes(chars), Level.error),
              ),
            ),
          ],
        ),
      );
    },
  ),
  // STEPFLOW_TODO: move to named arguments in v3.
  // The arguments from cli should be transferred implicitly.
  // The option to override the implicit transferred arguments has to be given.
  raw,
);

String _gitScript(String oldMail, String newMail) =>
    """
if [ "\$GIT_COMMITTER_EMAIL" = "$oldMail" ]
then
    export GIT_COMMITTER_EMAIL="$newMail"
fi

if [ "\$GIT_AUTHOR_EMAIL" = "$oldMail" ]
then
    export GIT_AUTHOR_EMAIL="$newMail"
fi
""";

List<String> _get(bool condition, String value, [String? back]) => condition
    ? [value]
    : back == null
    ? []
    : [back];
