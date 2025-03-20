default:
  @just --choose

static-analysis:
  slither . --config-file slither.config.json