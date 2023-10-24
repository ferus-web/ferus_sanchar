# Package

version       = "0.1.0"
author        = "xTrayambak"
description   = "Network protocol electric boogaloo"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.12"
requires "semver"

task docs, "Generate docs":
  exec """
nim doc \
--project \
--index:on \
--outdir:docs \
src/ferus_sanchar.nim
"""
