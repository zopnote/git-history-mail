import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

Future<void> main(List<String> raw) => runCommand(
  Command(
    use: "git-mail",
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
      final String newMail = info.getFlag<String>("new_mail").value;
      final String oldMail = info.getFlag<String>("old_mail").value;
      final bool allBranches = info.getFlag<bool>("all_branches").value;
      final bool includeTags = info.getFlag<bool>("include_tags").value;
      final bool force = info.getFlag<bool>("force").value;
      if (info.getFlag<bool>("help").value ||
          newMail.isEmpty && oldMail.isEmpty)
        return Response(info.formatSyntax());

      if (newMail.isEmpty)
        return Response(
          "Please specify a new mail with --new_mail.",
          Level.normal,
        );

      if (oldMail.isEmpty)
        return Response(
          "Please specify your old mail with --old_mail.",
          Level.normal,
        );

      return await runWorkflow(
        Chain(
          steps: [
            Shell(
              program: "git",
              arguments: [
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
