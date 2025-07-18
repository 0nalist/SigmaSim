# SigmaSim

SigmaSim is a satirical life sim and financial incremental game where you claw your way from broke beta to sigma übermensch, all inside a virtual desktop environment. Click, scheme, and optimize your way to the top—or die grinding.

---

## Architecture Overview

### 1. **Engine & Entry Points**
- **Engine:** The project uses the [Godot Engine](https://godotengine.org/) (GDScript).
- **Main Scene:** The virtual desktop environment (`desktop_env.tscn`) acts as the player’s hub, spawning "apps" and "popups" as independent "panes" wrapped in "WindowFrames".

### 2. **Core Systems**
Most simulation logic is organized into Autoload singletons, which are always available and coordinate different subsystems:

- **GameManager:** Handles main game state, scene transitions, pause/game over logic.
- **WindowManager:** Controls spawning, focusing, and minimizing/maximizing app windows, as well as registering app scenes.
- **PlayerManager:** Stores the active player's stats, handles persistent data, stats, and progression.
- **PortfolioManager:** Manages financial stats (cash, credit, loans, stocks, crypto).
- **BillManager:** Tracks recurring costs and lifestyle choices.
- **GPUManager:** Runs the simulation for crypto mining and GPU state.
- **WorkerManager:** Handles worker generation, assignment, and progression for workforce-related systems.
- **SaveManager:** Serializes/deserializes player and world data to disk.

### 3. **Apps & UI**
- **Apps** (like `Grinderr`, `BrokeRage`, `EarlyBird`, `Minerr`) are implemented as individual scenes with their own scripts and logic, loaded by the WindowManager.
- **UI Components:** Common UI elements (e.g., `window_frame.gd`) provide draggable, resizable, and interactive windows within the desktop environment.
- **Signals & Events:** Communication between managers, UI, and apps uses Godot’s signal system to keep systems decoupled.

### 4. **Resource & Data Organization**
- **Resources:** Shared data like upgrade definitions, worker types, and profiles are stored in the `resources/` directory.
- **Data-Driven:** Many systems (e.g., upgrades, lifestyle options, worker types) are defined in dictionaries or resource files for flexibility.
- **Persistence:** Save/load logic serializes dictionaries of player and world state. Managers implement `get_save_data()`/`load_from_data()` for modular persistence.

### 5. **Simulation Loops**
- **Frame/Physics Processing:** Mini-games (e.g., EarlyBird) and real-time simulations run their logic in `_process` or `_physics_process` for smooth updates.
- **Batch Updates:** Managers like `WorkerManager` and `GPUManager` process entity lists (e.g., workers, GPUs) in loops, emitting signals for changes.
- **Task/Event Scheduling:** Uses TimeManager autoload for daily/periodic events (e.g., new workers, bill payments, market updates).

### 6. **Modularity and Extensibility**
- **Component-Based:** New apps can be added as scenes and registered with the WindowManager.
- **Loose Coupling:** Managers interact via signals and only depend on documented interfaces, making it easier to add or refactor systems.
- **Expandable Data:** Add new upgrades, lifestyles, and resources with minimal code changes.

---

## Directory Structure (abridged)

- `/autoloads/` — Global game managers (singletons)
- `/components/` — App UIs, game scenes, and upgrade UI scenes
- `/resources/` — Data assets (profiles, upgrades, worker types, etc.)
- `/scripts/` — Shared logic (desktop, utility scripts)
- `/assets/` — Art, UI, and media resources

---

## Extending or Modifying

- **To add an app:** Create a new scene under `/components/apps/`, write logic, and register it in `WindowManager`.
- **To add a new stat, lifestyle, or upgrade:** Modify or add to the relevant manager and resource files.
- **To persist new game data:** Implement `get_save_data()` and `load_from_data()` in the relevant manager.

---

*This project is an early prototype using placeholder art and incomplete systems. For questions on system boundaries or contributing, see the source code or open an issue.*
*All rights reserved*
