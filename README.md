# KarenConflag

A minimal World of Warcraft 1.12.1 (Vanilla) addon that tracks the Conflagrate cooldown.

## Features

- Shows a Conflagrate icon only when in combat and the talent is learned
- Countdown timer while on cooldown
- Pulses with a glow effect when ready to cast
- Separate opacity settings for on-cooldown and ready states
- Settings persist across sessions

## Configuration

Type `/karenconflag` to open the config window. Options include:

- **Opacity CD** — icon opacity while Conflagrate is on cooldown
- **Opacity Ready** — icon opacity when Conflagrate is ready
- **Size** — icon size in pixels
- **X / Y** — position offset from screen center, with `+`/`-` buttons for pixel precision
- **Unlock / Lock** — drag the icon to reposition it, lock to save

## Requirements

- World of Warcraft 1.12.1 (Vanilla)
- Conflagrate talent (Destruction tree)
