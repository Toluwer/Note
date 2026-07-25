# Changelog

All notable changes to Note are documented here.

## Unreleased

### Added

- `Section:CreateProgressBar` and `Section:CreateProgress` with determinate, indeterminate, ranged, status, prefix, suffix, and flag support
- `Section:CreateDataTable` and `Section:CreateTable` with sortable columns, row selection, pagination, runtime row replacement, and table-aware search
- `Section:CreateContextMenu` with anchored and pointer-positioned opening, icons, shortcuts, dividers, checkable items, destructive actions, and arbitrary target binding
- `Section:CreateCommandPalette` with live filtering, keyboard navigation, shortcuts, configurable commands, and global open-key support

### Fixed

- Tooltips now size to their actual text instead of always using the maximum width
- Short tooltip labels stay compact while longer text wraps and grows vertically
- Removed the dark visual scrim behind modal dialogs
- Dialogs now use one temporary blur that animates in and out
- Rapid dialog replacement reuses the blur without stacking effects
- Dialog panels animate through fixed-geometry scale and group transparency
- Input validation errors now clear immediately when the typed value becomes valid
- Live validation recovery applies to both normal and password fields
- Programmatic `SetValue` calls clear an existing error when the new value is valid
- Revealed password inputs now hide and clear the dot mask instead of drawing it beneath the real text
- Password mask visibility stays synchronized during typing and programmatic value changes
- Dropdowns now animate a fixed overlay surface instead of changing popup geometry
- Open and close animations reverse smoothly without stale destruction callbacks
- Rapid repeated clicks no longer resize, jump, or destroy a reopened dropdown
- Dropdown chevrons rotate smoothly with the popup state

### Changed

- Added `Blur` and `BlurSize` dialog options and synchronized the showcase and README
- Updated the showcase with matching username and password validation examples
- Added a numeric-input example using the existing `CreateInput` component instead of introducing a duplicate number-input control
- Expanded `examples/showcase.lua` with progress bar, data table, context menu, and command palette demonstrations
- Added `examples/dropdowns.lua` with single-select, multi-select, and rapid reversal tests

## 0.2.3 - 2026-07-24

### Fixed

- Section collapse now continues from the currently visible height when interrupted
- Expansion layout updates cannot force an active tween to jump to its final height
- Rapid alternating clicks remain smooth in both directions

## 0.2.2 - 2026-07-24

### Fixed

- Removed the decorative line beneath section headers
- Rebuilt section collapse and expansion around one measured clip height
- Cancelled interrupted section tweens and ignored stale completion callbacks
- Rapid repeated collapse clicks no longer cause snapping, delayed hiding, or layout jumps

### Changed

- Updated the showcase and README to reflect the smooth collapsible-section behavior

## 0.2.1 - 2026-07-24

### Fixed

- Notifications now use content-aware compact widths and grow vertically for wrapped text
- Removed the notification progress strip and leading status icon
- Frosted glass no longer creates a `Lighting.BlurEffect` or blurs the game view

### Changed

- `Note:SetFrostedGlass` now switches between translucent and opaque UI surfaces only
- Updated notification examples and documentation to match the compact card design

## 0.2.0 - 2026-07-24

### Added

- Frosted-glass rendering with translucent theme tokens and an owned, configurable `BlurEffect`
- `Section:CreateThemeButtons` / `CreateThemeSwitcher` for ready-made Dark and Light theme controls
- `Window:ApplyTheme`, `Window:ClearAccent`, and `Note:SetFrostedGlass`

### Fixed

- Validation messages and input fields no longer shift into or clip through each other
- Page and sidebar scrollbars remain inset from rounded window edges
- Selected and disabled tabs now re-evaluate every theme-bound color and transparency token
- Theme switches reset the previous custom accent by default so the entire palette changes together
- First and last scrolling content no longer clip against the page viewport

### Changed

- Updated every runnable example and the README to use the frosted neutral theme workflow
- Retained the color picker as the optional custom-accent control

## 0.1.1 - 2026-07-24

### Fixed

- Removed the title-bar divider while minimized so it cannot protrude through rounded corners
- Restored the divider only after the window finishes expanding

### Changed

- Synchronized all examples with the neutral Dark and Light defaults
- Removed default window accent overrides from the basic and showcase examples
- Updated the theme example to focus on Dark, Light, and the retained color picker
- Updated README theme guidance to make accent colors explicitly opt-in

## 0.1.0 - 2026-07-24

### Added

- Modular client-side Luau architecture and generated single-file distribution
- Root GUI, compatibility, cleanup, signal, animation, input, overlay, validation, and theme systems
- Dark and light themes, custom accents, inherited custom themes, animated runtime updates
- Draggable and resizable windows with minimize, restore, close, search, tabs, and sections
- Button, toggle, slider, input, searchable dropdown, keybind, color picker, label, paragraph, and divider
- Centralized tooltips, notifications, and modal dialogs
- Flags, serializable configuration import/export, and optional filesystem adapters
- Official Lucide atlas registry and attribution
- Runnable basic, showcase, theme, and notification examples
- Deterministic bundler and static consistency checker
