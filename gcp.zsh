# A powerful controller function for a Google Cloud VM
# Usage: gvm <command> [options]
function gvm() {
  # --- Configuration ---
  # Set your virtual machine's name and zone here for easy management.
  local _VM_NAME="your-vm-name-here"
  local _VM_ZONE="your-vm-zone-here"
  # --- End Configuration ---

  # First, check if the 'gcloud' command-line tool is available.
  if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: 'gcloud' command not found."
    echo "Please ensure the Google Cloud SDK is installed and in your PATH."
    return 1
  fi

  # The first argument is the primary action (e.g., start, stop, resize).
  local action="$1"
  # shift moves the remaining arguments to the left, so $1 becomes the next argument.
  shift

  # --- Helper Functions ---

  # _get_vm_status: Fetches the current status of the VM (e.g., RUNNING, TERMINATED).
  # It silences errors (2>/dev/null) if the VM doesn't exist.
  _get_vm_status() {
    gcloud compute instances describe "$_VM_NAME" --zone="$_VM_ZONE" --format='get(status)' 2>/dev/null
  }

  # _ensure_stopped: A critical helper that checks if the VM is running.
  # If it is, it stops it before proceeding with an operation that requires it.
  _ensure_stopped() {
    local vm_status=$(_get_vm_status)
    if [[ "$vm_status" == "RUNNING" ]]; then
      echo "⚠️  This action requires the VM to be stopped. Stopping '$_VM_NAME' now..."
      gcloud compute instances stop "$_VM_NAME" --zone="$_VM_ZONE"
    elif [[ "$vm_status" == "TERMINATED" ]]; then
      echo "✅ VM is already stopped. Proceeding."
    else
      echo "❌ Could not determine VM status or it's in a transient state ($vm_status)."
      echo "   Please check the GCP console and try again."
      return 1 # Return an error code
    fi
  }

  # --- Main Command Logic ---

  # A case statement to handle the different actions passed to the function.
  case "$action" in
    start)
      echo "🚀 Starting VM '$_VM_NAME'..."
      gcloud compute instances start "$_VM_NAME" --zone="$_VM_ZONE"
      ;;

    stop)
      echo "🛑 Stopping VM '$_VM_NAME'..."
      gcloud compute instances stop "$_VM_NAME" --zone="$_VM_ZONE"
      ;;

    status)
      echo "🔎 Checking status for '$_VM_NAME'..."
      local vm_status=$(_get_vm_status)
      if [[ -n "$vm_status" ]]; then
        echo "   Status: $vm_status"
      else
        echo "   Could not find VM '$_VM_NAME' in zone '$_VM_ZONE'."
      fi
      ;;

    resize|type)
      local new_type="$1"
      if [[ -z "$new_type" ]]; then
        echo "❌ Error: Please specify a machine type."
        echo "   Example: gvm resize n1-highmem-8"
        return 1
      fi
      # Ensure the VM is stopped before resizing. If the check fails, exit.
      if ! _ensure_stopped; then return 1; fi
      echo "🔧 Resizing '$_VM_NAME' to '$new_type'..."
      gcloud compute instances set-machine-type "$_VM_NAME" --zone="$_VM_ZONE" --machine-type="$new_type"
      echo "✅ Success! You can now start the VM with 'gvm start'."
      ;;

    gpu-add)
      # Set defaults for GPU type and count if not provided by the user.
      local gpu_type="${1:-nvidia-tesla-t4}"
      local gpu_count="${2:-1}"
      if ! _ensure_stopped; then return 1; fi
      echo "⚡ Attaching $gpu_count x $gpu_type GPU(s) to '$_VM_NAME'..."
      gcloud compute instances add-accelerator "$_VM_NAME" --zone="$_VM_ZONE" \
        --accelerator="type=$gpu_type,count=$gpu_count"
      echo "✅ Success! You can now start the VM with 'gvm start'."
      ;;

    gpu-remove)
      local gpu_type="$1"
      if [[ -z "$gpu_type" ]]; then
        echo "❌ Error: Please specify the GPU type to remove."
        echo "   Example: gvm gpu-remove nvidia-tesla-t4"
        return 1
      fi
      if ! _ensure_stopped; then return 1; fi
      echo "➖ Detaching '$gpu_type' GPU(s) from '$_VM_NAME'..."
      gcloud compute instances remove-accelerator "$_VM_NAME" --zone="$_VM_ZONE" \
        --accelerator="type=$gpu_type"
      echo "✅ Success! You can now start the VM with 'gvm start'."
      ;;

    ssh)
      echo "💻 Connecting to '$_VM_NAME' via SSH..."
      gcloud compute ssh "$_VM_NAME" --zone="$_VM_ZONE"
      ;;

    # Default case for invalid commands or asking for help.
    *)
      echo "Usage: gvm <command> [options]"
      echo ""
      echo "Commands:"
      echo "  start               Starts the VM."
      echo "  stop                Stops the VM."
      echo "  status              Checks the current status (RUNNING, TERMINATED)."
      echo "  ssh                 Connects to the VM via SSH."
      echo "  resize <type>       Changes the machine type (e.g., n1-highmem-8)."
      echo "  gpu-add [type] [n]  Attaches GPU(s). Defaults to 1x nvidia-tesla-t4."
      echo "  gpu-remove <type>   Detaches all GPUs of a specific type."
      ;;
  esac
}