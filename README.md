# Synology Drive Client Custom Deployment

This repository contains as Powershell script and config.json file for setting up Synology Drive Clients mass deployment.
The Powershell script adds the current machines name to the backup path during deployment. 

Read the [Synology Drive Client Mass Deployment Guide](https://global.download.synology.com/download/Document/Software/UserGuide/Package/SynologyDrive/All/enu/Synology_Drive_Client_Mass_Deployment_Guide_enu.pdf)

# Usage
1) Edit `config.json` with the appropriate fields
2) Download the Synology Drive Client .msi installer from the [Synology Software Center](https://www.synology.com/en-us/support/download/RS3621RPxs?version=7.3#utilities)
3) Copy the installer, config file, and `deploy.ps1` to a network resource that each endpoint computer can reach
4) Edit the `$INSTALLER_PATH` and `$CONFIG_PATH` values to point to the two files from step 3
5) Using GPO configure each machine to execute the script


# Params
- `do_uninstall [Boolean]`: default = $false
    - Set to $true to uninstall the software before installing
