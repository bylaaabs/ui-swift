# AGENTS.md

guidance for any agent, or human, working in this repository. the studio-wide rules live in the handbook (bylaaabs/handbook); this file is what applies here.

## laaabs.

three people in madrid. three sides: tools by laaabs. (open source, free), apps by laaabs. (a subscription, not open source), software by laaabs. (custom work). products are lowercase and never typed in an interface: they are drawn from brand.

## rules of the house

- everything lowercase; english only; never an em dash or an en dash, use " - ".
- platforms in this order: macOS, windows, iOS / iPadOS, android.
- rust for cores and services, typescript for web front ends, swift / kotlin / winui only as the native layer on a rust core.
- every piece of work has an issue; branches are `<type>/<slug>`; conventional commits; pull requests only, never a push to main; never merge without being asked.
- `map/` and `brand/` are submodules; `service.yaml` at the root describes this repo and must agree with `map/map/services.yaml`.
- `CLAUDE.md` is just `@AGENTS.md`. edit this file, not that one.

## ui-swift

the design kit for every laaabs. app on macOS and iOS, the swift twin of `ui-web`: the marks, the tokens and the components that repeat. apps import `LaaabsKit`, at a pinned tag, and delete their own `Theme/`.

- `LaaabsWordmarks` is `brand/generated/swift`, compiled as it is: the marks come from brand's vectors and are never retyped or re-exported as images here.
- `LaaabsKit` is everything an app uses: `Wordmark`, and next the tokens and the components.
- `Gallery` puts every piece on one screen: `swift run Gallery`, or `swift run Gallery --png out.png` to compare without a window.

## conventions

- the first version changes nothing an app shows: it is baaar's theme (shared by taaab and caaapture) with the same public names, so moving an app onto the kit is deleting its `Theme/` and building. making the apps look the same is a later, separate version, decided with the gallery.
- an app pins an exact tag. a change here reaches an app only through a pull request in that app.
- no colour that is not in brand: black `#0a0a0a`, white at an opacity, cyan `#00b5e2` as a signal only.
- no analytics, no tracking sdk, ever.

## commands

- `swift build` and `swift test`. in a folder that is synced (the desktop, icloud), `swift test` fails to sign the test bundle ("resource fork, finder information, or similar detritus"): build outside it, `swift test --scratch-path /tmp/ui-swift`.
- `swift run Gallery` / `swift run Gallery --png out.png`.
- after cloning: `git submodule update --init`. when brand changes: bump the `brand` submodule.
