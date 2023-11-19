#!/bin/bash

# Set environment variables for relocating packages
# Default values
vmware_registry_username=""
vmware_registry_password=""
install_registry_hostname=""
install_registry_username=""
install_registry_password=""
selected_package=""
install_repo="tap"  # Default value for --install-repo flag
version=""

# Default choice values
option_name="TAP Packages"
package_name=tap-packages
vmware_repo_path=tanzu-application-platform
existing_tags=""
result_urls=""
pkgr_name="<repository_name>"

# Counters for calculations
relocated=0
failed_to_relocate=0

# Function to choose package for relocation
choose_package() {
  echo "Choose a package to relocate:"
  echo "1. TAP Packages"
  echo "2. Full TBS Dependencies Package"
  echo "3. Spring Cloud Gateway for Kubernetes"

  read -p "Enter your choice (1, 2, or 3): " choice

  case $choice in
    1)
      option_name="TAP Packages"
      package_name=tap-packages
      vmware_repo_path=tanzu-application-platform
      selected_package=1
      ;;
    2)
      option_name="Full TBS Dependencies Package"
      package_name=full-tbs-deps-package-repo
      vmware_repo_path=tanzu-application-platform
      selected_package=2
      ;;
    3)
      option_name="Spring Cloud Gateway for Kubernetes"
      package_name=scg-package-repository
      vmware_repo_path=spring-cloud-gateway-for-kubernetes
      selected_package=3
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
}

# Function to handle Docker login
docker_login() {
  local registry=$1
  local username=$2
  local password=$3

  echo "Docker Login to $registry"
  if docker login $registry -u $username -p $password; then
    echo "Docker login to $registry successful"
  else
    echo "Error: Docker login to $registry failed"
    exit 1
  fi
}

# Function to print update PackageRepository command
print_update_command() {
  local input_version="$1"
  local tap_version="X.X.X"

  local url="${install_registry_hostname}/${install_repo}/${package_name}:${input_version}"

  case $selected_package in
    1)
      tap_version=$input_version
      ;;
    *)
      ;;
  esac

  echo -e "
   +----------------------------------------------------------------------------------------------------------------------------+
   1. To update package repository:
   tanzu package repository update $pkgr_name  \\
     --url ${url}  \\
     --namespace tap-install

   2. To install new TAP package version:
   tanzu package installed update tap  \\
     -p tap.tanzu.vmware.com  \\
     -v ${tap_version}  \\
     --values-file tap-values.yaml  \\
     -n tap-install
   +----------------------------------------------------------------------------------------------------------------------------+
   "
}

# Parse command-line arguments or use default values
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vmware-username)
      vmware_registry_username=$2
      shift 2
      ;;
    --vmware-password)
      vmware_registry_password=$2
      shift 2
      ;;
    --install-registry-hostname)
      install_registry_hostname=$2
      shift 2
      ;;
    --install-registry-username)
      install_registry_username=$2
      shift 2
      ;;
    --install-registry-password)
      install_registry_password=$2
      shift 2
      ;;
    --package)
      case "$2" in
        tap)
          option_name="TAP Packages"
          package_name=tap-packages
          vmware_repo_path=tanzu-application-platform
          selected_package=1
          ;;
        tbs)
          option_name="Full TBS Dependencies Package"
          package_name=full-tbs-deps-package-repo
          vmware_repo_path=tanzu-application-platform
          selected_package=2
          ;;
        scg)
          option_name="Spring Cloud Gateway for Kubernetes"
          package_name=scg-package-repository
          vmware_repo_path=spring-cloud-gateway-for-kubernetes
          selected_package=3
          ;;
        *)
          echo "Invalid package option: $2"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --install-repo)
      install_repo=$2
      shift 2
      ;;
    --version)
      version=$2
      shift 2
      ;;
    *)
      echo "Invalid argument: $1"
      exit 1
      ;;
  esac
done

# If any required argument is missing, prompt the user for input
if [ -z "$vmware_registry_username" ]; then
  read -p "Enter VMware Registry Username: " vmware_registry_username
fi

if [ -z "$vmware_registry_password" ]; then
  read -s -p "Enter VMware Registry Password: " vmware_registry_password
  echo # Move to the next line after password input
fi

if [ -z "$install_registry_hostname" ]; then
  read -p "Enter Local Registry Hostname (FQDN): " install_registry_hostname
fi

if [ -z "$install_registry_username" ]; then
  read -p "Enter Local Registry Username: " install_registry_username
fi

if [ -z "$install_registry_password" ]; then
  read -s -p "Enter Local Registry Password: " install_registry_password
  echo # Move to the next line after password input
fi

# Check if --package option is provided
if [ -z "$selected_package" ]; then
  choose_package
fi

# Check if --version option is provided
if [ -z "$version" ]; then
  read -p "Enter the version number(s) you want to relocate (separated by space): " input_versions
else
  input_versions="$version"
fi

# Login to VMware registry
docker_login "registry.tanzu.vmware.com" "$vmware_registry_username" "$vmware_registry_password"

# Login to local registry
docker_login "$install_registry_hostname" "$install_registry_username" "$install_registry_password"

# Parse existing tags in local registry
existing_tags=$(imgpkg tag list -i ${install_registry_hostname}/${install_repo}/${package_name} | grep -v sha | sort -V)

# List existing tags in local registry target repo
if [ "$existing_tags" != "" ] ; then
  echo "Existing tags in target repo '${install_registry_hostname}/${install_repo}/${package_name}':"
  tags_with_newlines=$(echo "$existing_tags" | tr ' ' '\n')
  echo "$tags_with_newlines"
else
  echo "No existing tags in target repo '${install_registry_hostname}/${install_repo}/${package_name}' ---> Skipping"
fi

echo "Retrieving available versions for download..."
# List available package versions for relocation
available_versions=$(imgpkg tag list -i registry.tanzu.vmware.com/${vmware_repo_path}/${package_name} | grep -v sha | sort -V)

# Iterate through existing tags and check for [already exists] matches
for tag in $existing_tags
do
  if [[ "$available_versions" =~ $tag ]]; then
    available_versions="${available_versions/$tag/$tag [already exists]}"
  fi
done
echo "$available_versions"

# Iterate through input versions and relocate packages
for current_version in $input_versions
do
  echo "Relocating ${option_name} version: $current_version"
  if imgpkg copy -b registry.tanzu.vmware.com/${vmware_repo_path}/${package_name}:${current_version} --to-repo ${install_registry_hostname}/${install_repo}/${package_name} ; then
    echo "Successfully relocated $option_name version $current_version"
    (( relocated=relocated+1 ))
    current_url="$option_name version $current_version URL: [${install_registry_hostname}/${install_repo}/${package_name}:${current_version}]"

    # Concatenate the current_url to result_urls with a newline
    result_urls+="\t$current_url\n"
    print_update_command $current_version
  else
    echo "Failed to relocate ${option_name} $current_version"
    (( failed_to_relocate=failed_to_relocate+1 ))
  fi
done

if (( failed_to_relocate == 0 )) ; then
  echo "Packages relocation completed"
else
  echo "Failed to relocate ${failed_to_relocate} packages."
fi

if (( relocated > 0 )) ; then
  echo "Resulted URLs:"
  echo -e $result_urls
else
  echo "No packages were relocated."
fi
