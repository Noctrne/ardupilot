# ArduSub Custom

This repository contains the results of research on **custom thruster configuration for ROVs using ArduSub firmware**.

The customization of the thruster configuration is used to determine a **control allocation** that matches the designed thruster arrangement. The results of this research can be used as a basis for determining a more optimal physical configuration of an underwater vehicle for operation under diverse underwater environmental conditions.

This research is intended for firmware running on **Pixhawk 6C**. To apply the configuration to another Pixhawk series, the target board can be adjusted through the `--board` parameter during the build process.

---

## Prerequisites

Before using this repository, make sure the following are available:

* Ubuntu 22.04 or later
* Docker Engine
* Git
* This repository

### Docker Engine

Install Docker Engine by following the official documentation:

[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

### Git

Make sure Git is installed:

```bash
git --version
```

---

# How to Use

## Preparation

### 1. Clone ArduPilot as the Base Repository

Use the ArduPilot repository as the development base:

```bash
cd ~

git clone --recurse-submodules https://github.com/Noctrne/ardupilot.git

cd ardupilot

git submodule update --init --recursive
```

### 2. Check the Target Board

Make sure the **Pixhawk 6C** target is available:

```bash
./waf list_boards | grep Pixhawk6C
```

If `Pixhawk6C` appears in the output, the target board is available for the build process.

### 3. Optional: Create a Development Branch

To keep the main branch clean, create a dedicated development branch:

```bash
git switch -c 6thrust-6dof
git status
```

The branch name can be adjusted as needed.

---

## Crosscheck

The main file modified during the customization process is:

```text
ardupilot/
└── libraries/
    └── AP_Motors/
        └── AP_Motors6DOF.cpp
```

> **Note:** Ideally, the custom thruster configuration should only require changes to this file.

---

# Custom Thruster Configuration

## 1. Open `AP_Motors6DOF.cpp`

Go to the ArduPilot directory:

```bash
cd ~/ardupilot
```

Open the file:

```bash
nano libraries/AP_Motors/AP_Motors6DOF.cpp
```

Other editors such as `gedit`, `pico`, or VS Code can also be used.

## 2. Configure `SUB_FRAME_CUSTOM`

Find the following section in `AP_Motors6DOF.cpp`:

```cpp
case SUB_FRAME_CUSTOM:
    // Put your custom motor setup here
    // break;
```

Insert the **thruster allocation matrix** obtained from your configuration into this section.

### Example: 6-Thruster ROV

Before:

```cpp
case SUB_FRAME_CUSTOM:
    // Put your custom motor setup here
    // break;
```

After:

```cpp
case SUB_FRAME_CUSTOM:

    _frame_class_string = "MY_CUSTOM";

    add_motor_raw_6dof(AP_MOTORS_MOT_1,  0,       0,       -1.0f,  0,     1.0f,  0,       1);
    add_motor_raw_6dof(AP_MOTORS_MOT_2,  0,       0,        1.0f,  0,     1.0f,  0,       2);
    add_motor_raw_6dof(AP_MOTORS_MOT_3,  1.0f,   -1.0f,    -0.5f, -1.0f,  0,       -1.0f,  3);
    add_motor_raw_6dof(AP_MOTORS_MOT_4, -1.0f,   -1.0f,     0.5f, -1.0f,  0,        1.0f,  4);
    add_motor_raw_6dof(AP_MOTORS_MOT_5,  1.0f,    1.0f,    -0.5f, -1.0f,  0,        1.0f,  5);
    add_motor_raw_6dof(AP_MOTORS_MOT_6, -1.0f,    1.0f,     0.5f, -1.0f,  0,       -1.0f,  6);

    break;
```

### Important: `break;` Must Be Present

Do not remove:

```cpp
break;
```

Without `break;`, execution may **fall through** to:

```cpp
SUB_FRAME_SIMPLEROV_3
```

which can cause the next frame configuration to be executed as well.

### Keep `SUB_FRAME_CUSTOM`

The custom configuration must remain under:

```cpp
case SUB_FRAME_CUSTOM:
```

Do not replace this internal enum with another frame enum.

The following string:

```cpp
_frame_class_string = "MY_CUSTOM";
```

is an identifier for the custom frame and can be changed as needed.

---

# Important Design Note

## Do Not Modify `output_armed_stabilizing()`

The ArduSub controller algorithm **does not need to be modified** to use this custom thruster configuration.

In the upstream ArduSub implementation, dedicated output paths are provided for frames such as `VECTORED` and `VECTORED_6DOF`. Meanwhile, `SUB_FRAME_CUSTOM` uses the **generic mixer**, which calculates the following control contributions:

```text
roll + pitch + yaw
+
throttle + forward + lateral
```

> **Do not add `SUB_FRAME_CUSTOM` to the condition that calls `output_armed_stabilizing_vectored_6dof()`.**

Let all ArduSub modes—such as **Stabilize**, **Alt Hold / Depth Hold**, and other control modes—continue to generate controller commands normally. These commands are then passed to the **custom mixer** according to the defined thruster allocation matrix.

The purpose of this research is to modify the **motor control allocation**, not the ArduSub control algorithms.

---

# Verify the Changes

Before building the firmware, review the changes in the repository.

### Check formatting

```bash
git diff --check
```

### Review the modified file

```bash
git diff -- libraries/AP_Motors/AP_Motors6DOF.cpp
```

Ideally, changes related to the custom configuration should only appear in:

```text
libraries/AP_Motors/AP_Motors6DOF.cpp
```

---

# Build Firmware

This repository provides `.sh` scripts to assist the firmware build process using Docker.

## 1. Build the Docker Image

Go to the ArduPilot directory:

```bash
cd ~/ardupilot
```

Run:

```bash
chmod +x Personal_Research/make_dockerimage.sh
./Personal_Research/make_dockerimage.sh
```

## 2. Compile the Custom Firmware

After the Docker image has been created successfully:

```bash
chmod +x Personal_Research/build_customrov.sh
./Personal_Research/build_customrov.sh
```

The script compiles the modified firmware.

## 3. Check the Build Output

Check the Pixhawk 6C build directory:

```bash
cd ~/ardupilot/build/Pixhawk6C/bin/
```

The resulting firmware is expected to be available as:

```text
ardusub.apj
```

---

# Workflow Summary

```text
Clone ArduPilot
      │
      ▼
Check Pixhawk 6C Target
      │
      ▼
Edit AP_Motors6DOF.cpp
      │
      ▼
Add SUB_FRAME_CUSTOM
      │
      ▼
Verify Git Diff
      │
      ▼
Build Docker Image
      │
      ▼
Compile Custom Firmware
      │
      ▼
Generate ardusub.apj
```

---

# Project Structure

The relevant repository structure is:

```text
ardupilot/
├── libraries/
│   └── AP_Motors/
│       └── AP_Motors6DOF.cpp
│
└── Personal_Research/
    ├── make_dockerimage.sh
    └── build_customrov.sh
```

---

# Notes

* The thruster configuration is defined through the allocation matrix under `SUB_FRAME_CUSTOM`.
* The main modification is made in `libraries/AP_Motors/AP_Motors6DOF.cpp`.
* `output_armed_stabilizing()` does not need to be modified for this custom configuration.
* The `break;` statement under `SUB_FRAME_CUSTOM` must be preserved.
* The 6-thruster matrix shown above can be replaced according to the control allocation of the ROV configuration being researched.
* The default build target described in this README is **Pixhawk 6C**.

---

# License

Add the repository license information here.

