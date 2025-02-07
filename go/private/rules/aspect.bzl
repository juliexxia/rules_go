# Copyright 2014 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load(
    "@bazel_skylib//lib:sets.bzl",
    "sets",
)
load(
    "@io_bazel_rules_go//go/private:context.bzl",
    "go_context",
)
load(
    "@io_bazel_rules_go//go/private:common.bzl",
    "split_srcs",
)
load(
    "@io_bazel_rules_go//go/private:mode.bzl",
    "LINKMODES",
    "LINKMODE_NORMAL",
    "mode_string",
)
load(
    "@io_bazel_rules_go//go/private:providers.bzl",
    "GoArchive",
    "GoArchiveData",
    "GoAspectProviders",
    "GoLibrary",
    "GoSource",
)
load(
    "@io_bazel_rules_go//go/platform:list.bzl",
    "GOARCH",
    "GOOS",
)

# if mode is different aka if os and arch
def _go_archive_aspect_impl(target, ctx):
    go = go_context(ctx, ctx.rule.attr)

    source = target[GoSource] if GoSource in target else None
    archive = target[GoArchive] if GoArchive in target else None
    if source and source.mode == go.mode:
        # The base layer already built the right mode for us
        return []
    if not GoLibrary in target:
        # Not a rule we can do anything with
        return []

    # We have a library and we need to compile it in a new mode
    # #### GoLibrary is basically just name of library (step 1)
    library = target[GoLibrary]

    # do that with go from go_context, attrs of go_library, library from current target, something from current target
    # redo step 2
    source = go.library_to_source(go, ctx.rule.attr, library, ctx.coverage_instrumented())
    
    # redo step 3
    if archive:
        archive = go.archive(go, source = source)
    
    # any rule that cares check these first. 
    return [GoAspectProviders(
        source = source,
        archive = archive,
    )]

go_archive_aspect = aspect(
    _go_archive_aspect_impl,
    attr_aspects = [
        "deps",
        "embed", # how to take sources from multiple libraries -> combined into one library
        "compiler", # don't worry about
        "compilers", # don't worry about
        "_stdlib",
        "_coverdata",
    ],
    attrs = {
        "pure": attr.string(values = [
            "on",
            "off",
            "auto",
        ]),
        "static": attr.string(values = [
            "on",
            "off",
            "auto",
        ]),
        "msan": attr.string(values = [
            "on",
            "off",
            "auto",
        ]),
        "race": attr.string(values = [
            "on",
            "off",
            "auto",
        ]),
        "goos": attr.string(
            values = GOOS.keys() + ["auto"],
            default = "auto",
        ),
        "goarch": attr.string(
            values = GOARCH.keys() + ["auto"],
            default = "auto",
        ),
        "linkmode": attr.string(values = LINKMODES, default = LINKMODE_NORMAL),
    },
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)
