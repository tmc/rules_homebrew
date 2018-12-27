load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@com_github_tmc_rules_homebrew//rules:homebrew_archive.bzl", "homebrew_archive")

def homebrew_rules_dependencies(
        brew_tag = "1.8.5",
        brew_sha256 = "b1c22277192fc1cb834f07466d19f678a628b890f6a1efc64e368b8cc7218ba6",
        homebrew_core_commit = "e963aa704fe743f54d34bff943aaed7a0175f668",
        homebrew_core_sha256 = "3f2c429cc6416ee9c45500d8f5d3e1c8e9876422a2906888e31303213c167a11"):
    homebrew_archive(
        name = "homebrew",
        brew_tag = brew_tag,
        brew_sha256 = brew_sha256,
        homebrew_core_commit = homebrew_core_commit,
        homebrew_core_sha256 = homebrew_core_sha256,
        patches = ["@com_github_tmc_rules_homebrew//patches:homebrew-download-only.patch"],
    )
