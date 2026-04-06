# 🌩️ Agentic AI & Data Science Workspace Setup 
**Project:** `agentic-480806` | **Zone:** `asia-southeast1-a`

Welcome to the automated lab environment setup. As data scientists and developers, managing our compute infrastructure efficiently is just as critical as the models we build. To ensure our workshops run smoothly and consistently, I have prepared this suite of Bash scripts. 

These scripts automate the provisioning, configuration, and teardown of Google Cloud Spot VMs, allowing us to rapidly spin up our development environments and connect to them seamlessly via VS Code Remote SSH. 

Please read through the architecture of these scripts before executing them.

---

### 📋 Prerequisites
Before running any scripts, ensure you have the following configured on your local machine:
1. **Google Cloud SDK (`gcloud`)** installed and initialized.
2. **VS Code** with the **Remote - SSH** extension installed.
3. Git Bash (for Windows users) or a standard Unix terminal (Mac/Linux).

To authenticate your terminal, run:
```bash
gcloud auth login
```

---

### 🛠️ Script Execution Order

#### `0_create_key.sh` — SSH Key Generation
Security is paramount. This script generates a dedicated RSA SSH key pair (`workshop_key`) specifically for this lab environment under the user `student`. It also formats the public key precisely as required by Google Cloud's metadata system.
* **Run this exactly once.** If the key already exists, the script will safely skip generation.

#### `1_create_vms.sh` — Infrastructure Provisioning
This is the core provisioning script. It automatically verifies your `gcloud` authentication and ensures you are working within the correct project (`agentic-480806`). 
* You will be prompted to enter the number of VMs required. 
* The script provisions **Spot VMs** (e2-standard-2 running Debian 11). We use Spot instances to optimize resource costs during our experiments.
* **Note:** The script injects the SSH key generated in Step 0 directly into the VMs upon creation.

#### `2_get_info.sh` — VS Code Integration
Once your VMs are running, you need a way to connect to them. This script dynamically queries the GCP API to fetch the external NAT IP addresses of all your running instances.
* It outputs a pre-formatted SSH configuration block.
* **Action Required:** Copy the output provided by this script and paste it directly into your local SSH config file (`~/.ssh/config` or `C:\Users\NAME\.ssh\config`). 
* *Windows Users:* Pay close attention to the terminal output for specific instructions on mapping your `IdentityFile` path.

#### `3_terminate_vms.sh` — Resource Teardown
Clean up your resources when the lab is complete. Leaving unused VMs running consumes unnecessary budget. This script safely queries and deletes all instances matching the `vm-*` naming convention in our zone.
* It includes a safety prompt (`Are you sure?`) to prevent accidental deletions.

#### `4_fix_vscode.sh` — The Debugger
Occasionally, VS Code Remote SSH will hang or throw a "Failed to set up dynamic port forwarding" error. This usually happens when the remote VS Code server daemon enters a corrupted state on the VM. 
* Run this script and provide the VM number (e.g., `1` for `vm-1`). 
* It will SSH into the machine and cleanly purge the `~/.vscode-server` directory. Afterward, simply reload your VS Code window to install a fresh server instance.

---

### 💡 Best Practices for the Lab
* **Always run Step 3** when you are done for the day. Spot VMs are cheap, but they aren't free.
* If you encounter connection timeouts, double-check that your university or corporate firewall isn't blocking outbound SSH (Port 22) connections.
* Read the terminal outputs. I have designed these scripts to give you explicit, step-by-step feedback.

See you in the lab.

**Wasit Linmprasert (อ.มด)**