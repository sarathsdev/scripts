#!/bin/bash

# Function to prompt user for input
prompt_input() {
    read -p "$1: " input
    echo "$input"
}

# Function to stop Tomcat server
stop_tomcat() {
    echo "Stopping Tomcat server..."
    "$TOMCAT_SHUTDOWN_SCRIPT"  # Call the Tomcat shutdown script
}

# Function to start Tomcat server
start_tomcat() {
    echo "Starting Tomcat server..."
    "$TOMCAT_STARTUP_SCRIPT"  # Call the Tomcat startup script
}

# Prompt user for domain name of the virtual host
VIRTUAL_HOST=$(prompt_input "Enter the domain name of the virtual host")

# Prompt user for host aliases
VIRTUAL_HOST_ALIAS=$(prompt_input "Enter the host aliases (comma-separated, if multiple)")

# Prompt user for app_base directory location
APP_BASE=$(prompt_input "Enter the app_base directory location (relative to Tomcat's webapps directory)")

# Prompt user for Tomcat server.xml location
SERVER_XML=$(prompt_input "Enter the location of the Tomcat server.xml file")

# Prompt user for Tomcat startup script location
TOMCAT_STARTUP_SCRIPT=$(prompt_input "Enter the location of the Tomcat startup script")

# Prompt user for Tomcat shutdown script location
TOMCAT_SHUTDOWN_SCRIPT=$(prompt_input "Enter the location of the Tomcat shutdown script")

# Stop Tomcat server
stop_tomcat

# Backup the original server.xml file
cp -r "$SERVER_XML" "$SERVER_XML.bak"

# Format host aliases for XML
HOST_ALIASES_XML=$(echo "$VIRTUAL_HOST_ALIAS" | sed 's/,/ /g' | awk '{print "        <Alias>" $1 "</Alias>"}')

# Define the virtual host configuration
VIRTUAL_HOST_CONFIG="
    <Host name=\"$VIRTUAL_HOST\"  appBase=\"$APP_BASE\" unpackWARs=\"true\" autoDeploy=\"true\">
$HOST_ALIASES_XML
        <Context path=\"\" docBase=\".\" debug=\"0\" reloadable=\"true\"/>
    </Host>
"


# Escape special characters in the virtual host configuration
VIRTUAL_HOST_CONFIG_ESC=$(printf '%s\n' "$VIRTUAL_HOST_CONFIG" | sed 's:[\&/]:\\&:g;$!s/$/\\/')

# Add the virtual host configuration to server.xml
#sed -i "/<Engine/a $VIRTUAL_HOST_CONFIG" "$SERVER_XML"
awk -v vhc="$VIRTUAL_HOST_CONFIG" '/<Engine/{print; print vhc; next} 1' "$SERVER_XML" > tmpfile && mv tmpfile "$SERVER_XML"

echo "Virtual host configuration for $VIRTUAL_HOST has been added to $SERVER_XML"

# Start Tomcat server
start_tomcat

echo "Tomcat server started successfully."


#$NEW_IP= ifconfig | awk '/\<([0-9]{1,3}\.){3}[0-9]{1,3}\>/ && $2 != "127.0.0.1" {print $2}'


# Update /etc/hosts using awk
#sudo awk -v domain="$VIRTUAL_HOST" -v new_ip="$NEW_IP" -v alias="$VIRTUAL_HOST_ALIAS" '$2 == domain { $1 = new_ip; $3 = alias; print } 1' /etc/hosts > temp && sudo mv temp /etc/hosts
