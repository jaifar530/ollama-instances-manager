# ollama-instances-manager
Title: Ollama Instance Manager

Description:
The Ollama Instance Manager is a bash script designed to automate the creation and management of multiple instances of the Ollama application running on Ubuntu 22. This script simplifies the process of scaling the Ollama service by allowing users to easily create and delete instances based on their requirements.

Key Features:
1. Instance Creation:
   - The script prompts the user to specify the desired number of instances to create (between 1 and 54100).
   - It verifies the existence of the `ollama.service` file, which serves as a template for creating new instances.
   - The script creates copies of the `ollama.service` file, renaming each copy with a unique instance number (e.g., `ollama-1.service`, `ollama-2.service`, etc.).
   - It modifies each copied service file to include a unique description and environment variables for the instance.
   - The script starts and enables each created instance using systemd.

2. Instance Deletion:
   - The script allows users to delete previously created Ollama instances.
   - It identifies all the `ollama-x.service` files in the `/etc/systemd/system/` directory.
   - The script stops and disables each instance and removes the corresponding service file.

3. Input Validation:
   - The script validates user inputs to ensure they meet the required criteria.
   - It checks if the script is being run with sudo or as the root user.
   - It verifies that the `ollama.service` file exists before creating instances.
   - The script validates the number of instances provided by the user, ensuring it is within the allowed range.

4. Error Handling:
   - The script provides informative error messages if any prerequisites are not met or if invalid inputs are provided.
   - It handles scenarios such as the `ollama.service` file not existing or the user entering an invalid number of instances.

5. Systemd Integration:
   - The script leverages systemd for managing the Ollama instances.
   - It reloads the systemd daemon after creating or deleting instances to ensure the changes take effect.
   - The script starts and enables the created instances using systemd commands.

Prerequisites:
- Ubuntu 22 operating system
- Sudo or root access
- Existing `ollama.service` file in the `/etc/systemd/system/` directory

Usage:
1. Clone the repository containing the Ollama Instance Manager script.
2. Open a terminal and navigate to the cloned repository's directory.
3. Make the script executable using the command: `chmod +x ollama_instance_manager.sh`.
4. Run the script with sudo or as the root user: `sudo ./ollama_instance_manager.sh`.
5. Follow the prompts to create or delete Ollama instances.

Note: Exercise caution when running this script, especially in production environments. Ensure you have the necessary permissions and backups in place before modifying system files and services.

By automating the process of creating and managing Ollama instances, the Ollama Instance Manager script simplifies the scaling and deployment of the Ollama application on Ubuntu 22. It provides a convenient and efficient way to handle multiple instances, enabling users to adapt to changing demands and optimize resource utilization.
