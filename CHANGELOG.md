# Changelog

All notable changes to Note are documented here.

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
