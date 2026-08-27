# Windows 10 IoT Enterprise LTSC Image Toolkit

A PowerShell configuration script and a documented Audit Mode workflow for
building a repeatable Windows 10 IoT Enterprise LTSC 2021 image from legitimate
Microsoft installation media.

> [!IMPORTANT]
> This repository does not contain Windows or Office binaries, ISO images,
> product keys, or activation tools. You must supply correctly licensed source
> media and software.

> [!CAUTION]
> `setup.ps1` changes machine and user policy, removes selected provisioned
> applications, and adjusts Windows Update targeting. Test it in a disposable
> virtual machine, take a snapshot first, and review the script before running
> it. There is currently no automated rollback.

## What the Script Does

| Area | Changes |
| --- | --- |
| Consumer features | Disables suggested apps, tailored experiences, and silent consumer installs through policy and registry settings |
| Copilot and AI policy | Applies policy keys that disable Copilot and Windows AI data analysis where those policies are supported |
| App cleanup | Removes a defined list of consumer Appx packages while retaining Microsoft Store and Xbox components |
| Gaming preferences | Enables automatic Game Mode and disables mouse acceleration |
| Update targeting | Keeps the installed Windows product and display version as the target release until explicitly unlocked |
| Optional toolbox | Creates local scripts for Steam/Epic installation, GPU-driver links, hibernation, visual effects, and update-policy removal |

The script configures an installed system. It does **not** automatically capture
a WIM, assemble an ISO, install Office, or preinstall every application in the
finished image; those are separate administration steps.

## Workflow

```mermaid
flowchart LR
    ISO[Licensed Windows media] --> VM[Disposable VM]
    VM --> AUDIT[Audit Mode]
    AUDIT --> CONFIG[Review and run setup.ps1]
    CONFIG --> VERIFY[Update and verify]
    VERIFY --> SYSPREP[Sysprep /generalize]
    SYSPREP --> WINPE[Boot WinPE]
    WINPE --> WIM[Capture install.wim]
    WIM --> FINAL[Assemble deployment media]
```

## Requirements

- Licensed Windows 10 IoT Enterprise LTSC 2021 installation media
- A virtual machine with a restorable snapshot
- Administrator access inside the VM
- PowerShell 5.1 or later
- Windows ADK/WinPE or equivalent deployment tooling for image capture
- DISM and an ISO-authoring tool for the manual capture/assembly stages

## Build Procedure

### 1. Create a clean VM

Install Windows from official media. Before changing the image, take a VM
snapshot and disconnect networking if your build process requires an offline
first-boot path.

At the region-selection screen, press `Ctrl+Shift+F3` to restart into Audit
Mode.

### 2. Review and run the configuration script

Copy this repository into the VM, inspect `setup.ps1`, and run it from an
elevated PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

Reboot and verify application removal, policies, Windows Update behavior, and
the generated `Optional Tweaks` directory before continuing.

### 3. Generalize the installation

After completing updates and removing temporary installers or VM-specific
tools, run Sysprep:

```cmd
%WINDIR%\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown
```

### 4. Capture the image

Boot into WinPE and capture the generalized Windows partition. Adjust drive
letters for your environment:

```cmd
Dism /Capture-Image /ImageFile:S:\install.wim /CaptureDir:C:\ /Name:"Windows 10 IoT LTSC"
```

If required by your source media, set the edition metadata:

```cmd
wimlib-imagex.exe info install.wim 1 --image-property FLAGS=EnterpriseS
```

### 5. Assemble deployment media

Replace `sources\install.wim` in a working copy of the licensed installation
media and include [`tools/ei.cfg`](tools/ei.cfg). Build a new ISO with your
preferred deployment tool, then test the complete OOBE flow in a second VM.

## Repository Layout

```text
.
├── README.md
├── setup.ps1       # System configuration and optional-toolbox generator
└── tools/
    └── ei.cfg      # EnterpriseS edition/channel metadata
```

## Scope and Support

This is a reproducible lab workflow, not a Microsoft-supported deployment
product. Windows policies and component names can change over time; validate
the behavior against the exact LTSC build and update level you intend to ship.

## License

MIT. See [LICENSE](LICENSE).
