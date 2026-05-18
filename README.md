# Termux Service Setup

A quick and easy way to set up common services on your Termux device with security, idempotency, and minimal typing.

## Features

- **Interactive Selection**: Choose which services to install using a simple menu.
- **Boot Support**: Automatically configures services to start on device boot (requires Termux:Boot).
- **One-Click Controls**: Adds home screen shortcuts to stop services and open Web UIs (requires Termux:Widget).
- **Secure & Idempotent**: Skips already configured services and ensures basic security.
- **Storage Integration**: Connects Termux to your Android shared storage.

## Services Supported

- **OpenSSH**: Secure remote access.
- **Syncthing**: Continuous file synchronization.
- **Transmission**: Lightweight BitTorrent client with Web UI.
- **Mosquitto**: MQTT broker for IoT and automation.
- **Navidrome**: Modern Subsonic-compatible personal music streamer.

## Prerequisites

For the best experience, please install the following from [F-Droid](https://f-droid.org/):

1. [Termux](https://f-droid.org/en/packages/com.termux/)
2. [Termux:Boot](https://f-droid.org/en/packages/com.termux.boot/) (Optional: for start-on-boot)
3. [Termux:Widget](https://f-droid.org/en/packages/com.termux.widget/) (Optional: for home screen shortcuts)

## Installation

Open Termux and copy/paste the following command:

```bash
curl -sL https://raw.githubusercontent.com/brad/termux-server/termux-service-setup-16714057685171292445/setup.sh | bash
```



## Post-Installation

### 1. Enable Boot Start
If you installed **Termux:Boot**, open the app once after installation. This allows Android to trigger the boot scripts located in `~/.termux/boot/`.

### 2. Use Shortcuts
If you installed **Termux:Widget**:
1. Long-press on an empty space on your Android home screen.
2. Select **Widgets**.
3. Find **Termux:Widget** and drag it to your home screen.
4. You will now see a list of shortcuts to stop services or open their Web UIs.

### 3. Permissions
If shortcuts to open Web UIs (e.g., Syncthing) don't work, ensure Termux has the **"Display over other apps"** permission enabled in Android Settings.

## Security
- **SSH**: After installation, run `passwd` in Termux to set a secure password for SSH access.
- **Web UIs**: It is highly recommended to set up usernames and passwords within the Web UIs of Syncthing and Transmission once they are running.
