# Mobile (Android / iOS)

## Design

- Viewport **1080×1920** portrait
- Stretch `canvas_items` + `expand` (notches / tablets)
- Renderer **mobile** (Metal / Vulkan / OpenGL)
- Safe-area pad on score HUD
- Touch + mouse emulate touch for desktop testing

## Desktop preview window

Override **540×960** (½ design) — large enough to play; scales to phone on device.

## Export checklist

1. Godot → Project → Export → Android / iOS
2. Package / Bundle id: `com.yourstudio.aureole`
3. Orientation: Portrait only
4. Test on a real device after APK / Xcode archive
