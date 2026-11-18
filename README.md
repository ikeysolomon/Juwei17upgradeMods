# JUWEI17 UART and 400-Step Motor Upgrade

> **Review draft.** This repository is private. GitHub Pages has not been enabled. Verify the wiring and live FRAM values before using this configuration on the mount.

This page documents the JUWEI17 ESP32 OnStepX 10.28x configuration for the TMC2209 hardware-UART connection, MB85RC64 FRAM, and Moons Industries NEMA17 motors rated at 400 full steps per revolution (0.9 degrees per full step).

## UART configuration

The JUWEI17 pinmap in `OnStepX/src/pinmaps/Pins.Juwei17.h` selects `Serial1` for the TMC hardware UART, at 115200 baud:

```cpp
#define SERIAL_TMC          Serial1
#define SERIAL_TMC_BAUD     115200
#define SERIAL_TMC_RX       23
#define SERIAL_TMC_TX       5
#define SERIAL_TMC_ADDRESS_MAP(axis) ((axis == 0) ? 0 : ((axis == 1) ? 1 : 3))
```

In `OnStepX/Config.h`, UART is enabled for both TMC2209 axes:

```cpp
#define AXIS1_DRIVER_MODEL       TMC2209
#define AXIS1_DRIVER_UART       ON

#define AXIS2_DRIVER_MODEL       TMC2209
#define AXIS2_DRIVER_UART       ON
```

For this pinmap, GPIO 5 is the ESP32 UART transmit signal and GPIO 23 is receive. The TMC2209 uses a single-wire UART interface. Confirm the board's actual trace, connector, and UART interface circuit against the JUWEI17 schematic and driver documentation before wiring; firmware pin definitions alone do not prove the physical modification. Ensure a common signal ground and compatible logic levels. Do not connect ESP32 GPIO directly to a motor-supply rail.

## 400-step motor configuration

A 0.9-degree motor makes 400 full steps per revolution. The configured step scale depends on the motor's full steps, microstep setting, and total mechanical reduction:

```text
steps per degree = full steps per revolution * microsteps * total reduction / 360
```

The 10.28x source configuration sets both axes to 16 microsteps and `7184.222` steps per degree, with 500 mA hold and 1200 mA run current:

```cpp
#define AXIS1_STEPS_PER_DEGREE      7184.222
#define AXIS1_DRIVER_MICROSTEPS      16
#define AXIS1_DRIVER_IHOLD           500
#define AXIS1_DRIVER_IRUN            1200

#define AXIS2_STEPS_PER_DEGREE      7184.222
#define AXIS2_DRIVER_MICROSTEPS      16
#define AXIS2_DRIVER_IHOLD           500
#define AXIS2_DRIVER_IRUN            1200
```

These are source defaults, not proof that the mount's actual gear train has been measured or that these values are active at runtime. Confirm the motor and reduction ratio for each axis and calculate the scale before operating the mount.

## FRAM runtime settings: important mismatch

This build selects `NV_MB85RC64` for non-volatile settings. The source comments warn that runtime axis settings can override the values in `Config.h`. The latest verified workspace notes record `3592.222` steps per degree in FRAM for both axes, while this source tree contains `7184.222` for both. Therefore, do not assume the 400-step motor scale is active just because the firmware was built from this source. Read the current FRAM values, confirm the correct mechanical scale, then update and read back only the required fields.

The repository's firmware history also records serial-response problems after upload, followed by restoration of a known-good image. Confirm the controller's live version and settings before treating the 10.28x firmware or the motor calibration as installed and verified.

## Commissioning checklist

- Inspect the UART routing and interface circuit on the modified board; verify GPIO 5 TX, GPIO 23 RX, and the TMC2209 address mapping.
- Confirm both motors' 400-step rating and each axis's actual gear reduction.
- Read back FRAM settings before making changes; reconcile the `3592.222` recorded runtime values with the `7184.222` source defaults.
- Verify TMC2209 UART communication, current limits, microsteps, and axis direction at low speed with the mount unloaded.
- Check measured motion against commanded motion before tracking or slewing under load.
- Confirm the running firmware version and save the final verified source and runtime settings.

## Source files

- `Firmware/OnStepX-10.28x-JUWEI17/OnStepX/Config.h`
- `Firmware/OnStepX-10.28x-JUWEI17/OnStepX/src/pinmaps/Pins.Juwei17.h`

This README documents selected settings from the local JUWEI17 OnStepX 10.28x source tree; it does not redistribute the full firmware source.
