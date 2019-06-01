workspace(name = "com_github_tmc_rules_homebrew")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

http_file(
    name = "buildifier",
    executable = True,
    sha256 = "b29c24d32a6d14fc3221f5c94b717404b66a5ddce7a77aa1b8f734d484eb0c3d",
    urls = ["https://github.com/bazelbuild/buildtools/releases/download/0.19.2.1/buildifier"],
)

http_file(
    name = "buildifier_osx",
    executable = True,
    sha256 = "3bcc7d751519703b5a09eba7a433be468bda5290ba416c02a38dc2f2b2b864e0",
    urls = ["https://github.com/bazelbuild/buildtools/releases/download/0.19.2.1/buildifier.osx"],
)

# Start stardoc rules
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
git_repository(
    name = "io_bazel_skydoc",
    remote = "https://github.com/bazelbuild/skydoc.git",
    tag = "0.3.0",
)
load("@io_bazel_skydoc//:setup.bzl", "skydoc_repositories")
skydoc_repositories()
load("@io_bazel_rules_sass//:package.bzl", "rules_sass_dependencies")
rules_sass_dependencies()
load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories")
node_repositories()
load("@io_bazel_rules_sass//:defs.bzl", "sass_repositories")
sass_repositories()
# End stardoc rules
