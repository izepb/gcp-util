# GVM Controller for Google Cloud

A simple, powerful Zsh shell function to manage a GCP - starting with VM configs. This script centralises common `gcloud` commands into a single, easy-to-use interface called `gvm` (just to avoid having to type VM names and zones and making sure the flags are right, etc).

## My own use cases

-   Start, stop, and check the status of VM.
-   Resize the machine type (e.g., from `n1-standard-4` to `n1-highmem-8`). (This can be done to add or remove GPU based on machine type)
-   Connect via SSH.
-   Automatically stops the VM for operations that require it.

## Installation

1.  **Save the Script:**
    Create a directory to store the shell functions and save the `gvm` function into a file within it.

    ```sh
    mkdir -p ~/.zsh_functions
    # Now, save the gvm function into the file below:
    # ~/.zsh_functions/gcp.zsh
    ```

2.  **Update `.zshrc`:**
    Add the following line to  `~/.zshrc` file to load the function every time you open a new terminal.

    ```sh
    # Add this to ~/.zshrc
    source ~/.zsh_functions/gcp.zsh
    ```

3.  **Reload Shell:**
    Apply the changes to current terminal session.

    ```sh
    source ~/.zshrc
    ```

## Configuration

To use the script for a specific VM, we need to edit the configuration variables at the top of the `gvm` function in `~/.zsh_functions/gcp.zsh`.

```zsh
# --- Configuration ---
# Set your virtual machine's name and zone here for easy management.
local _VM_NAME="your-vm-name-here"
local _VM_ZONE="your-vm-zone-here"
# --- End Configuration ---
```

-   `_VM_NAME`: The name of your Google Compute Engine instance.
-   `_VM_ZONE`: The zone where your instance is located (e.g., `europe-west4-c`).

## Usage

The script is used with the syntax `gvm <command> [options]`.

| Command               | Description                                                      | Example                                |
| --------------------- | ---------------------------------------------------------------- | -------------------------------------- |
| `start`               | Starts the VM.                                                   | `gvm start`                            |
| `stop`                | Stops the VM.                                                    | `gvm stop`                             |
| `status`              | Checks the current status (e.g., `RUNNING`, `TERMINATED`).       | `gvm status`                           |
| `ssh`                 | Connects to the VM via SSH.                                      | `gvm ssh`                              |
| `resize <type>`       | Changes the machine type. **Automatically stops the VM first.** | `gvm resize n1-highmem-8`              |
| `help` (or any other) | Displays the help message.                                       | `gvm help`                             |

