# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `from_observation` class methods to local and global stat classes
- `==` operator for `WeightsMatrix`

## [1.0.3] - 2020-05-22

### Added

- CONTRIBUTING.md
- PR Template
- logo

### Changed

- `x/z` attr_writer changed to a function that standardizes input
- MIT -> GPL-3-Clause License

## [1.0.2] - 2020-05-08 (First Changelog Commit)

### Added

- Global Statistical Classes
- Local Statistical Classes
- WeightsMatrix
- Weights Queries
- Data queries
- Spatial Lag computations
- Array extensions
- Numo extensions
- Add examples/usage to docs
- Create RDocs
- Write SparseMatrix C ext
- Add `#summary` method to statistics that will combine stat vals with p-vals, and quads or hot/cold spot info.
- Add ability to assign `x` or `z` on stat classes so users are not forced to query data to input it into models. Add example to README.

### Changed

- Memoize expensive functions within classes
- Make star a parameter to getis-ord class
- Refactor Global Moran and BVMoran
- Support non-numeric keys in WeightsMatrix/General refactor
- Change instances of `standardized` and `windowed` to `standardize` and `window`, respectively.
- Add `positive` and `negative` groups for `GetisOrd` and `Geary`, similar to how `#quads` is implemented.
- Refactor stats to inherit an abstract class.

### Removed

- Pure Ruby CSR Matrix

[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/keithdoggett/spatial_stats/compare/v1.0.1...v1.0.3
[1.0.2]: https://github.com/keithdoggett/spatial_stats/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/keithdoggett/spatial_stats/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/keithdoggett/spatial_stats/compare/v0.2.2...v1.0.0
[0.2.2]: https://github.com/keithdoggett/spatial_stats/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/keithdoggett/spatial_stats/compare/v0.1.1...v0.2.1
[0.1.1]: https://github.com/keithdoggett/spatial_stats/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/keithdoggett/spatial_stats/releases/tag/v0.1.0
