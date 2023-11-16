# AdiBags Bound Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.7.7] 2023-11-16
### Changed
- Bump Classic TOC to 1.15.0

## [1.7.6] 2023-11-08
### Changed
- Bump Retail TOC to 10.2.0
- Bump Wrath TOC to 3.4.3

## [1.7.5] 2023-09-08
### Changed
- Bump Retail TOC to 10.1.7
- Bump Classic TOC to 1.14.4

## [1.7.4] 2023-07-15
### Fixed
- Permanently fix the intermitent bug when depositting materials in the bank.
### Changed
- Bump Retail TOC to 10.1.5
- Bump Wrath TOC to 3.4.2

## [1.7.2] 2023-05-13
### Fixed
- Tentatively fix the intermitent bugs cropping up when depositing materials in the bank.

## [1.7.1] 2023-05-06
### Added
- Addon icon (shows up in addon list in-game)

## [1.7.0] 2023-05-03
### Changed
- Bump Retail TOC to 10.1.0
- Update API usage

## [1.6.3] 2023-03-22
### Changed
- Bump Retail TOC to 10.0.7

## [1.6.2] 2023-03-15
### Fixed
- Prevent tradable recipes from being wrongly categorized as BoE

## [1.6.1] 2023-02-03
### Added
- Filter option for Poor/Common (gray/white) BoE items added in 10.0.5

## [1.6.0] 2023-02-02
### Fixed
- Removed the local cache.

API calls are cached client-side anyway, and this fixes a bug where equiping a
BoE item would not update that item's category, so it would stay in BoE even
though it is now a Soulbound item.

## [1.5.3] 2023-01-25
### Changed
- Bump Retail TOC to 10.0.5

## [1.5.2] 2023-01-22
### Changed
- Bump Wrath TOC to 3.4.1

## [1.5.1] 2022-11-21
### Fixed
- Tooltip scanning works again in Retail (#4)

## [1.5.0] 2022-11-05
### Changed
- Bump Retail TOC to 10.0.2

## [1.4.0] 2022-11-05
### Changed
- Removed a lot of dead code
- Simplified localization, since we only support `enUS` for now

## [1.3.2] 2022-11-01
### Fixed
- Fixed Battle Pets error

## [1.3.1] 2022-10-30
### Fixed
- My dumb ass named the Classic TOC files wrong and it didn't release properly. This release does nothing but rectify that.
- Rename Classic TOC files (`_` and not `-`, genius)

## [1.3.0] 2022-10-30
### Added
- Support for Classic Era

## [1.2.0] 2022-10-30
### Added
- Support for Wrath Classic

### Changed
- Equipable check is now faster and uses less memory

## [1.1.0] 2022-10-28
### Added
- Support for BoP items

## [1.0.0] 2022-10-28
### Added
- Scanned items are now cached

### Changed
- Tooltip scanning now more efficient & resilient

### Fixed
- Categories are now set properly again

## [0.6.0] 2022-10-26
### Changed
- Bumped TOC to 10.0.0

## [0.5.0] 2022-08-17
### Changed
- Bumped TOC to 9.2.7

## [0.4.0] 2022-06-06
### Changed
- Bumped TOC to 9.2.5

## [0.3.0] 2022-05-05
### Added
Initial release.

### Changed
- Bumped TOC to 9.2
