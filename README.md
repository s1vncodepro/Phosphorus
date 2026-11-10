# Phosphorus

A small desktop app for keeping track of your own assignments. Written in C++17
with a Qt Quick (QML) interface.

## What it does

- Add assignments with a title, course, due date, priority and notes.
- See at a glance what is to do, due this week, overdue and completed. The
  summary tiles and the sidebar are filters: click one to narrow the list.
- Search by title, course or notes, filter by course, and sort by due date,
  priority or title.
- Tick assignments off, edit them by clicking a card, delete them (with undo).
- Light and dark themes; the layout folds to a single column in a narrow window.
- Everything is saved automatically to a JSON file on your computer. Nothing
  leaves your machine.

Shortcuts: `Ctrl+N` new assignment, `Ctrl+F` search, `Esc` close the dialog.

## Building

You need CMake 3.21+, a C++17 compiler and Qt 6.4 or newer with the
**Qt Quick** and **Qt Quick Controls** modules.

- **Windows / macOS:** install Qt with the [Qt online installer](https://www.qt.io/download-qt-installer),
  then either open `CMakeLists.txt` in Qt Creator and press Run, or build from a
  terminal and point CMake at your Qt install, e.g.
  `-DCMAKE_PREFIX_PATH=C:/Qt/6.8.0/msvc2022_64`.
- **Ubuntu / Debian:**
  ```sh
  sudo apt install cmake g++ qt6-base-dev qt6-declarative-dev libgl1-mesa-dev \
      qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
      qml6-module-qtquick-templates qml6-module-qtquick-window \
      qml6-module-qtqml-workerscript
  ```

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/phosphorus            # build\Release\phosphorus.exe with Visual Studio
```

Run the unit tests with `ctest --test-dir build`.

## Where your data lives

Assignments are stored in `assignments.json` in the per-user app data folder:

| OS      | Location                                       |
| ------- | ---------------------------------------------- |
| Windows | `%APPDATA%\Phosphorus`                         |
| macOS   | `~/Library/Application Support/Phosphorus`     |
| Linux   | `~/.local/share/Phosphorus`                    |

Set the `PHOSPHORUS_DATA_DIR` environment variable to use a different folder.

## Layout

| Path                     | What                                                    |
| ------------------------ | ------------------------------------------------------- |
| `src/assignmentstore.*`  | The data model: add/edit/remove, due labels, JSON saving |
| `src/assignmentfilter.*` | Filtering, searching and sorting for the list           |
| `src/main.cpp`           | Start-up; hands the model to the UI                     |
| `qml/`                   | The interface (`Main.qml` is the window, `Theme.qml` the colours) |
| `tests/`                 | Unit tests for the model and filter                     |
