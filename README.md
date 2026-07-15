# Track Team

A Flutter app for health program supervisors to locate and navigate to active
field teams during campaigns.

Supervisors import the `deviceTraceDataList` spreadsheet exported from the
campaign server. The app stores every trace in a local SQLite database and
works fully offline from that point on — find the closest team by GPS, drill
down through the geo hierarchy, or explore the team map, then hand off to
Google Maps for turn-by-turn navigation.

## Features

- **Import device traces** from `.xlsx` exports. Re-importing is idempotent
  (rows are merged by device and trace date); an optional switch replaces all
  existing data instead. Every import is logged.
- **Nearest teams** — detects your position with GPS and lists teams sorted
  by straight-line distance, ONLINE teams first by default. When an export
  contains no online devices the app says so and offers to show all teams
  instead of dead-ending.
- **Browse by area** — cascade filter through LGA → Ward → Health Facility →
  Distribution Point. Every level is optional; results are distance-sorted
  whenever a GPS fix is available.
- **Team map** — all located teams on an OpenStreetMap view with
  status-colored markers and your own position. Tap a marker for the team
  card and navigation.
- **One-tap navigation** — every team card opens Google Maps driving
  directions to the team's last known location.
- **Team details** — full record, sync trail across imports, copy
  coordinates to the clipboard.
- **Freshness at a glance** — every card shows how long ago the device last
  synced; anything older than 24 hours is flagged as stale.
- **Search** teams by name, username or device id from the home screen.
- Material 3 design, light and dark theme.

## Expected spreadsheet format

The importer matches columns by header name (order does not matter) and
understands both inline-string and shared-string cell encodings, Excel serial
dates and ISO date strings. Relevant headers:

| Header | Used for |
|---|---|
| `Device Id` | Team identity (required) |
| `Trace Date`, `Last Synched at` | Freshness, latest-trace resolution |
| `Last Synched by`, `User Name` | Team display name |
| `LGA`, `Ward`, `Health Facility`, `Distribution Point` | Cascade filters |
| `Last Known Location` | `"lat, lng"` coordinates for distance and navigation |
| `Status` | ONLINE / OFFLINE |
| `IMEI`, `Device Model`, `App Version`, `Settlement` | Detail screen |

Rows without coordinates are imported but excluded from distance features.
A device appearing on several rows keeps its full sync trail; all queries
resolve each team to its latest trace.

## Getting started

Prerequisites: [Flutter](https://docs.flutter.dev/get-started/install) 3.32+
and an Android device or emulator.

```sh
flutter pub get
flutter run
```

Build a release APK locally:

```sh
flutter build apk --release
```

Or grab the APK from CI: every push runs the **Build APK** workflow
(analyze → test → build) and uploads `app-release.apk` as an artifact. The
workflow uses the default debug signing; add a keystore and signing config
in `android/app/build.gradle.kts` before distributing through a store.

### Permissions

- **Location (while in use)** — sorting teams by distance from you.
- **Internet** — OpenStreetMap tiles on the map screen. Everything else
  works offline.

## Architecture

Layered per the Flutter team's
[architecture guidance](https://docs.flutter.dev/app-architecture):

```
lib/
├── domain/models/      # DeviceTrace, Team, GeoFilter, ImportResult, stats
├── data/
│   ├── services/       # xlsx parser, SQLite, geolocation, Maps hand-off
│   └── repositories/   # TeamRepository: imports + latest-per-device queries
├── ui/
│   ├── core/           # theme, formatters, shared widgets
│   └── features/       # home, import, nearest, browse, map, team detail
└── routing/            # go_router configuration
```

Views are lean; each feature has a `ChangeNotifier` view model injected with
`provider`. The spreadsheet parser reads the OOXML directly (`archive` +
`xml`), and parsing runs off the UI thread via `compute`. SQLite access goes
through `sqflite` with an upsert on `UNIQUE(device_id, trace_date)`.

## Tests

```sh
flutter test
```

The suite covers the parser against a 100-row slice of a real export
(`test/fixtures/sample_traces.xlsx`), repository queries on an in-memory
SQLite database (`sqflite_common_ffi`), view-model behaviour with a fake
location service, and widget rendering. To sanity-check a full production
export:

```sh
FULL_EXPORT_PATH=/path/to/deviceTraceDataList.xlsx \
  flutter test test/full_export_smoke_test.dart --run-skipped
```

## Roadmap ideas

- Pull exports directly from the campaign server API instead of manual files
- Offline map tile caching for low-connectivity areas
- Marker clustering for very dense team maps
- Per-LGA coverage dashboard
- CSV import
- Localization (Yoruba, Hausa)
