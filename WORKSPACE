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
