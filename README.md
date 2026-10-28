# NewFile

Companion to [OpenTerm](https://github.com/kpmoran/OpenTerm).

A one-click "new text file" button for the Finder toolbar. Click it and it creates
`NewFile.txt` in the folder of the frontmost Finder window, selects the new file so you
can rename it immediately, and quits.

- If no Finder window is open, the file goes on the Desktop.
- If `NewFile.txt` already exists, it creates `NewFile 2.txt`, `NewFile 3.txt`, ...
- Never shows dialogs. Problems are written to `~/Library/Logs/NewFile.log`.
- Also works from Spotlight, the Dock, or `open -a NewFile`.

## Build and install

    ./build.sh
    rm -rf /Applications/NewFile.app && cp -R build/NewFile.app /Applications/

Requires Xcode command line tools (uses `swiftc`, no Xcode project needed).

## Put it in the Finder toolbar

1. Open a Finder window and go to Applications.
2. Hold **Cmd** and drag `NewFile.app` up into the window's toolbar. Drop it where you want it.
3. Click it. The first time, macOS asks whether NewFile may control Finder. Click **OK**.

To remove it from the toolbar, Cmd-drag it out of the toolbar.

## Permissions

The app is ad-hoc signed, so macOS ties the "control Finder" permission to the exact build.
After every rebuild you will be asked once more. If you ever clicked "Don't Allow", re-enable it in
System Settings > Privacy & Security > Automation > NewFile > Finder.

## Layout

    Sources/main.swift   the whole app (~100 lines)
    Info.plist           LSUIElement=true keeps it out of the Dock
    build.sh             compiles, bundles, ad-hoc signs
    Icon/source.png      original 512px artwork
    AppIcon.icns         app icon (this is what shows in the toolbar), built from Icon/AppIcon.iconset

## Changing the icon

Replace Icon/source.png with a square PNG (transparent background), then:

    for s in 16 32 128 256 512; do
      sips -z $s $s Icon/source.png --out Icon/AppIcon.iconset/icon_${s}x${s}.png
      sips -z $((s*2)) $((s*2)) Icon/source.png --out Icon/AppIcon.iconset/icon_${s}x${s}@2x.png
    done
    iconutil -c icns Icon/AppIcon.iconset -o AppIcon.icns
    ./build.sh

## License

MIT, see [License.md](License.md).
