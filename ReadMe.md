
# Understanding YUNA Workflow

This document explains the purpose, relationships, and functionality of the YUNA system.

---

## What is YUNA?

YUNA (Yielding Universal Node Automation) is a workflow system designed to automate the preparation and deployment of operating system images. It provides structured processes and allows for device-specific customizations, enhancing consistency and reliability in system deployment. YUNA manages custom configurations, device-specific settings, and stage-based system actions, such as:

- **Audit Stage**: Verifying system integrity and settings.
- **Resealed Stage**: Locking down the system configuration for production use.
- **Recovery Stage**: Creating or managing recovery images for system restoration.

---

## Components of YUNA

### 1. Configuration Files
- **`config.json`**: Contains global settings and details about image stages (e.g., AUDIT, RESEALED, RECOVERY).
- **`current_stage.json`**: Tracks the current stage in the workflow.

### 2. Device-Specific Configuration
- Stored in `devices/*.json`, these files include supported devices and their respective configurations (e.g., registry entries, scripts).
- Example: A device like "HP ZBook Fury 16" may have custom registry settings and scripts for installation.

### 3. Operating System Scripts and Registry
- Located under `operatingsystems/*`, these include:
  - OS-specific scripts (e.g., PowerShell scripts for configuration).
  - Registry entries for customization.
  - Stage-specific actions (AUDIT, RESEALED, RECOVERY).

### 4. PowerShell Scripts
- **`app.ps1`**: The main script that orchestrates the workflow.
- **`capture.ps1`**: Handles the creation of WIM (Windows Imaging Format) files using tools like DISM.

---

## Workflow Relationships

The system operates in a logical sequence of steps, ensuring that configurations are applied and validated before proceeding to the next stage. The key relationships are:

1. **Input Data**: YUNA begins by reading `config.json` and `current_stage.json` to load configurations.
2. **Stage Selection**: Based on the current stage, it identifies whether a valid stage exists or terminates with an error.
3. **Device Configuration**: It checks if the device is supported by consulting the `devices/*.json` files.
4. **OS Configuration**: Applies scripts and registry settings based on the operating system.
5. **Custom Settings**: Executes additional custom configurations provided in scripts or registry files.
6. **Stage Actions**: Executes specific actions (e.g., AUDIT, RESEALED) related to the current stage.
7. **Capture and Save**: Uses `capture.ps1` to create a WIM image and saves it to `D:\Images`.

---

## How YUNA Works

1. **Initialization**:
   - Reads input configuration files.
   - Loads and validates device and OS-specific data.

2. **Validation**:
   - Ensures that the device is supported and that the required scripts/registries exist.

3. **Execution**:
   - Applies OS and custom settings.
   - Runs stage-specific scripts.

4. **Image Creation**:
   - Uses PowerShell to automate WIM file creation and stores the output in the designated directory.

5. **Completion**:
   - Confirms the success of the operation or flags errors for unsupported devices or stages.

---

## Data Flow

The data flow within YUNA can be described as follows:

1. **Input:** User initiates the workflow; configuration files are loaded.
2. **Validation:** Device types and operating systems are checked.
3. **Execution:** Configurations and scripts are applied.
4. **Output:** The created WIM image is stored, and feedback is provided to the user.

---

## Benefits of YUNA

- **Standardization:** Ensures uniform configurations across devices.
- **Flexibility:** Adaptable to specific requirements.
- **Reliability:** Reduces manual errors.
- **Efficiency:** Fast image deployment.

---

## Summary

YUNA is an efficient, structured workflow system that streamlines the deployment of OS images with customization for specific devices and use cases. By automating tasks like configuration application, image creation, and validation, YUNA ensures consistent, error-free system preparation. It combines technical precision with flexibility, making it a powerful solution for enterprise system deployment.

---

## Visual Representation

Below is a visual representation of the YUNA workflow:

![YUNA Workflow Flowchart](YUNA_Flowchart.png)
