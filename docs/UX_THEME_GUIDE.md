Design System Overview

- Palette: Uses brand green `#5BA843`, teal `#3B969D`, and purple accent `#6C38B8` with neutral dark surfaces. Light/dark are supported; app currently defaults to dark for consistency until all screens are refactored.
- Typography: Headings use Poppins, body uses Nunito. Access via `Theme.of(context).textTheme`.
- Tokens: Use `DesignTokens` for subject colors, spacing, and radii. Use `AppGradients.primary` for brand gradients.
- Surfaces: Prefer `Theme.of(context).colorScheme.surface` for cards and `onSurface`/`onSurfaceVariant` for text.
- Inputs/Buttons: Use Material buttons (Elevated/Filled/Outlined) to inherit colors and rounded corners.

How to Build Screens

- Background: Wrap pages in `AnimatedBackground(child: Scaffold(...))` and set `Scaffold.backgroundColor: Colors.transparent` if you need translucency.
- Text: Do not hardcode `Colors.white` or `Colors.black`. Use `Theme.of(context).colorScheme.onSurface` or `textTheme`.
- Cards: Use `Card` or `Container(color: colorScheme.surface)` with rounded corners and subtle shadow.
- Chips/Pills: Use opacity of subject colors from `DesignTokens.getSubjectColor(subject)` for accents.
- Icons: Choose `colorScheme.primary` or the relevant subject color.

Next Steps

- Refactor remaining screens to remove hardcoded colors.
- Switch `ThemeMode` back to `system` after refactor.
