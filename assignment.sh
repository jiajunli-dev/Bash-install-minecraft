#!/usr/bin/env bash

# TODO Write down your name and studentnumber of the author(s)
# Jiajun Li (1056944) and Choukri Bouchrit (1059788)

# Global variables
# TODO Define (only) the variables which require global scope
source dev.conf

# INSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_with_apt() {
    # Do NOT remove next line!    
    echo "function install_with_apt"

    # Update apt sources and install openjdk-17-jdk
    local package=$1
    if [ "$package" = "update" ]; then
        sudo apt update || handle_error "Failed to update apt"
        echo "Updated apt sources"
        sudo apt install openjdk-17-jdk -y || handle_error "Failed to install openjdk-17-jdk"
        echo "Installed openjdk-17-jdk"
    fi
    
    # Install required dependencies
    if [ "$package" = "install dependencies" ]; then
        for package in "gdebi" "wget" "make" "curl"; do
            sudo apt install "$package" -y || handle_error "Failed to install $package"
            echo "Installed $package"
        done
    fi
    
    # Remove installed dependencies
    if [ "$package" = "autoremove" ]; then
        for package in "gdebi" "wget" "make" "curl"; do
            sudo apt remove "$package" -y || handle_error "Failed to remove $package"
            echo "Removed $package"  
        done
    fi
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_package() {
    # Do NOT remove next line!
    echo "function install_package"
    
    # Check if the setup function has been executed
    local package=$1
    if [ ! -f "$INSTALL_DIR/setup_log.txt" ]; then
        handle_error "Setup function has not been executed. Please run setup first"
    fi
    
    # Install Minecraft or Spigotserver using switch statement
    case "$package" in
        "MINECRAFT")
            # Check if the directory exists, if not create it
            local minecraft_dir="$INSTALL_DIR/minecraft"
            if [ -d "$minecraft_dir" ]; then
                echo "Directory exists."
            else
                echo "Directory does not exist creating: $minecraft_dir."
                mkdir "$minecraft_dir" 
                if [ -d "$minecraft_dir" ]; then
                    echo "Directory successfully created."
                else
                    handle_error "Failed to create directory: $minecraft_dir"
                fi
            fi
            
            
            # Check if the file exists, if not download it
            if [ -f "$minecraft_dir/minecraft.deb" ]; then
                handle_error "Minecraft is already downloaded"
            else 
                local minecraft_url="$MINECRAFT_URL"
                local minecraft_file="$minecraft_dir/minecraft.deb"
                sudo curl -o "$minecraft_file" "$minecraft_url" || handle_error "Failed to download Minecraft" "minecraft"
            fi

            # Install Minecraft
            sudo gdebi -n "$INSTALL_DIR/minecraft/minecraft.deb" || handle_error "Failed to install Minecraft" "minecraft"
            ;;
        "SPIGOTSERVER")          
            # Check if the directory exists, if not create it
            local spigot_dir="$INSTALL_DIR/server"
            if [ -d "$spigot_dir" ]; then
                echo "Directory exists."
            else
                echo "Directory does not exist creating: $spigot_dir."
                mkdir "$spigot_dir"
                if [ -d "$spigot_dir" ]; then
                    echo "Directory successfully created."
                else
                    handle_error "Failed to create directory: $spigot_dir"
                fi
            fi

            # Check if the file exists, if not download it
            if [ -f "$spigot_dir/spigot.jar" ]; then
                handle_error "Spigot.jar is already downloaded"
            else
                local spigot_url="$BUILDTOOLS_URL"
                local spigot_file="$spigot_dir/BuildTools.jar"
                sudo curl -o "$spigot_file" "$spigot_url" || handle_error "Failed to download Spigot" "spigot"
            fi

            # Copy spigotstart.sh to the server directory and provide execute permission
            cp -n spigotstart.sh "$INSTALL_DIR/server/spigotstart.sh" || handle_error "Failed to copy spigotstart.sh"
            sudo chmod +x "$INSTALL_DIR/server/spigotstart.sh" || handle_error "Failed to provide execute permission"

            # Build spigotserver
            cd "$INSTALL_DIR/server" || handle_error "Failed to change directory to spigotserver"
            sudo java -jar BuildTools.jar || handle_error "Failed to build spigotserver" "spigot"
            mv spigot-*.jar spigot.jar || handle_error "Failed to move spigot.jar"

            # Run it for the first time and set eula to true
            java -jar /tmp/apps/server/spigot.jar || handle_error "Failed to first start spigotserver" "spigot"
            echo "eula=true" > eula.txt          
            ;;
    esac
}


# CONFIGURATION

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function configure_spigotserver() {
    # Do NOT remove next line!
    echo "function configure_spigotserver"

    # Set server_port to 25565
    local server_port=25565

    # Install ufw
    sudo apt install ufw -y || handle_error "Failed to install ufw"  

    # Configure ufw to use the default deny / allow policy
    sudo ufw default deny incoming || handle_error "Failed to deny incoming with ufw"
    sudo ufw default allow outgoing || handle_error "Failed to allow outgoing with ufw"

    # Allow ssh and enable ufw
    sudo ufw allow ssh || handle_error "Failed to allow SSH port with ufw"
    sudo ufw enable || handle_error "Failed to enable ufw"
    
    # Allow the Spigot server port
    sudo ufw allow "$server_port" || handle_error "Failed to allow Spigot server port $server_port with ufw"

    # Set gamemode to creative in server.properties
    local server_properties="$INSTALL_DIR/server/server.properties"
    sudo sed -i 's/\(gamemode=\)survival/\1creative/' "$server_properties" || handle_error "Failed to configure gamemode in server.properties"

    # Restart the Spigot service
    sudo systemctl restart spigot.service || handle_error "Failed to restart Spigot service"
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function create_spigotservice() {
    # Do NOT remove next line!
    echo "function create_spigotservice"
    
    # Check if the spigot.service file exists
    local path=$(sudo find / -type f -name spigot.service 2>/dev/null)
    if [ -f "/etc/systemd/system/spigot.service" ]; then
        echo "spigot.service exist."
        exit 1
    else    
        cd /
        cd $(dirname $path) || handle_error "Failed to change directory to $path"
    fi

    # Add WorkingDirectory to spigot.service to prevent root folder getting filled with server files
    local file="spigot.service"
    if grep -q "^WorkingDirectory=" "$file"; then
        echo "WorkingDirectory is already defined in $file"
    else
        sed -i '/^\[Service\]/a WorkingDirectory=/tmp/apps/server' "$file"
        echo "WorkingDirectory added to $file"
    fi

    # Copy spigot.service to /etc/systemd/system and enable the service
    sudo cp spigot.service /etc/systemd/system/spigot.service || handle_error "Failed to copy spigot.service"
    sudo systemctl enable spigot.service || handle_error "Failed to enable spigot.service"
    sudo systemctl daemon-reload || handle_error "Failed to reload systemd"

    echo "Spigot service has been created"
}

# ERROR HANDLING

# TODO complete the implementation of this function
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # Print a specific error message
    echo "Error: $1"

    local rollback=$2
    if [ "$rollback" = "minecraft" ]; then
        echo "Second argument matches 'Minecraft'"
    elif [ "$rollback" = "spigot" ]; then
        echo "Second argument matches 'Spigot'"
    fi
    
    # Exit this function with an integer value!=0
    exit 1
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_minecraft() {
    # Do NOT remove next line!
    echo "function rollback_minecraft"
    #First, we check if the folder was made
    #if this is the case, we remove it with all it's contents
    if [ -d "$INSTALL_DIR/minecraft" ]
    then
        rm -rf "$INSTALL_DIR/minecraft"
    else
        handle_error "There's nothing to rollback"
    fi

    #Here we check if the removal was actually done
    #If this is not the case, we let the user know about it
    if [ -d "$INSTALL_DIR/minecraft" ]
    then
        handle_error "rollback minecraft was unsuccessful"
    fi
    echo "rollback minecraft was successful"
    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_spigotserver {
    # Do NOT remove next line!
    echo "function rollback_spigotserver"

    # TODO if something goes wrong then call function handle_error

    #First, we check if the folder was made
    #if this is the case, we remove it with all it's contents
    if [ -d "$INSTALL_DIR/server" ]
    then
        rm -rf "$INSTALL_DIR/server"
    else
        handle_error "There's nothing to rollback"
    fi

    #Here we check if the removal was actually done
    #If this is not the case, we let the user know about it
    if [ -d "$INSTALL_DIR/server" ]
    then
        handle_error "rollback server was unsuccessful"
    fi
    echo "rollback server was successful"
}


# UNINSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_minecraft {
    # Do NOT remove next line!
    #Comment:
    #Check if the directory exists, and if so: delete it completely.
    #Handles cases such as:
    #-Directory doesn't exist
    #Removing directory and files wasn't done right
    echo "function uninstall_minecraft"  
    #deleting folder
    if [ -d "$INSTALL_DIR/minecraft" ]
    then
        #deleting folder
        echo "uninstalling minecraft..."
        rm -rf "$INSTALL_DIR/minecraft"
        if [ -d "$INSTALL_DIR/minecraft" ]
        then
            handle_error "Deleting minecraft folder has failed"
        else
            echo "Minecraft folder has been uninstalled"
        fi
        
        launcherdir=$(find / -type d -name ".minecraft" 2>/dev/null)
        #deleting minecraft (not using minecraft-launcher --clean, it doesn't work)
        rm -vr $launcherdir

        #the following line is used to delete the launcher (again, because --clean doesn't work)
        if ! sudo apt -y remove minecraft-launcher
        then
            handle_error "deleting minecraft has failed"
        else
            echo "minecraft has succesfully been deleted"
        fi       
    else
        echo "Minecraft folder doesn't exist"
    fi
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotserver {
    # Do NOT remove next line!
    echo "uninstall_spigotserver"  
    
    # TODO remove the directory containing spigotserver
    if [ -d "$INSTALL_DIR/server" ]; then
        sudo rm -rf "$INSTALL_DIR/server" || handle_error "Failed to remove server directory"
        
        uninstall_spigotservice || handle_error "Failed to uninstall spigot service"
        echo "Spigot server and spigot service have been removed successfully"
    else
        echo "Server directory does not exist."
    fi 
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotservice {
    # Do NOT remove next line!
    echo "uninstall_spigotservice"

    # Check if the spigot.service file exists
    if [ -f "/etc/systemd/system/spigot.service" ]; then
        # Stop and disable the spigot service and remove the service file from /etc/systemd/system and reload systemd
        sudo systemctl stop spigot.service || handle_error "Failed to stop spigot.service"
        sudo systemctl disable spigot.service || handle_error "Failed to disable spigot.service"
        sudo rm /etc/systemd/system/spigot.service || handle_error "Failed to remove spigot.service"
        sudo systemctl daemon-reload || handle_error "Failed to reload systemd"

        echo "Spigot service has been uninstalled"
    else
        echo "File does not exist."
    fi
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function remove() {
    # Do NOT remove next line!
    echo "function remove"

    uninstall_minecraft
    uninstall_spigotserver

    if [ -d "$INSTALL_DIR" ]; then
        sudo rm -rf "$INSTALL_DIR" || handle_error "Failed to remove installation directory"
        echo "Installation directory has been removed"
    else
        echo "Installation directory does not exist"
    fi

    install_with_apt "autoremove"
}


# TEST

# TODO complete the implementation of this function
function test_minecraft() {
    # Do NOT remove next line!
    echo "function test_minecraft"

    # TODO Start minecraft

    # TODO Check if minecraft is working correctly
        # e.g. by checking the logfile

    # TODO Stop minecraft after testing
        # use the kill signal only if minecraft canNOT be stopped normally

    #starting minecraft in the background (otherwise script won't continue)
    if [ ! -d "$INSTALL_DIR/minecraft" ]; then
        handle_error "Minecraft is not installed"
    fi
    
    minecraft-launcher &

    #use pgrep to find the oldest (-o) process related to minecraft (minecraft-launcher)
    minecraft_id=$(pgrep -o minecraft)
    echo $minecraft_id
    sleep 10  #wait a bit for minecraft to finish launching and see if it keeps running

    #check if it is still running
    
    if pgrep minecraft > /dev/null
    then
        echo "Minecraft application is running."
        kill $minecraft_id #send termination signal
    else
        handle_error "Minecraft application failed to start."
    fi

    #provide some feedback for the user, the purpose of the sleep:
    #-give the process enough time to terminate. if it is still running send a kill signal
    echo "shutting down Minecraft..."
    sleep 10
    if pgrep minecraft > /dev/null 
    then
        echo "Minecraft application is still running after sending termination signal."
        echo "Now forcefully shutting down Minecraft"
        kill -9 $minecraft_id
    else
        echo "Minecraft application terminated successfully."
    fi
}

function test_spigotserver() {
    # Do NOT remove next line!
    echo "function test_spigotserver"    

    if [ ! -d "$INSTALL_DIR/server" ]; then
        handle_error "Spigot server is not installed"
    fi

    # Install netcat as a tool to check if the server is running
    sudo apt install netcat -y || handle_error "Failed to install netcat"

    # Start spigotserver, wait for 60 seconds to let the server load everything
    sudo systemctl start spigot.service || handle_error "Failed to start minecraft"
    sleep 60

    # Configure spigotserver and restart the server, wait for 90 seconds to let the server load everything
    configure_spigotserver
    sleep 90

    # Check if the server is running on port 25565 using netcat
    nc -zv -4 localhost 25565

    # Stop spigotserver
    sudo systemctl stop spigot.service || handle_error "Failed to stop spigot.service"

    # Check if the server is stopped correctly, If not kill the server using pkill
    if ! sudo systemctl is-active --quiet spigot.service; then
        echo "Spigot server stopped successfully"
    else
         sudo pkill -f 'java -jar /tmp/apps/server/spigot.jar' || handle_error "Failed to kill spigotserver"
         echo "Spigot server could not be stopped normally and was killed using pkill"  
    fi

    # Remove netcat
    sudo apt remove netcat -y || handle_error "Failed to remove netcat"
}

function setup() {
    # Do NOT remove next line!
    echo "function setup"    
    
    # Check if the installation directory exists, if not create it
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Creating directorie: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR" || handle_error "Failed to create directorie: $INSTALL_DIR"
    else
        echo "$INSTALL_DIR directory already exists"
    fi

    # Create a log file in the installation directory
    local log_file="setup_log.txt"
    echo "$(date): Setup function executed" >> "$INSTALL_DIR/$log_file"

    # Update apt sources and install required dependencies
    install_with_apt "update"
    install_with_apt "install dependencies"
}

function main() {
    # Do NOT remove next line!
    echo "function main"
    
    # TODO read the arguments from $@
        # make sure NOT to use empty argument values
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <command> <options>"
        exit 1
    fi

    # TODO use a switch statement to execute
    case "$1" in
        # setup that creates the installation directory and installs all required dependencies 
        "setup")
            setup
            ;;
        # remove that removes installation directory and uninstalls all required dependencies (even if they were already installed)
        "remove")
            remove
            ;;
        # minecraft with an argument that specifies the one of the following actions
            # installation of minecraft client
            # test
            # uninstall of minecraft client
        "minecraft")
            shift
            case "$1" in
                "--install")
                    install_package "MINECRAFT"
                    ;;
                "--test")
                    test_minecraft
                    ;;
                "--uninstall")
                    uninstall_minecraft
                    ;;
                *)
                    handle_error "Invalid option for minecraft: $1"
                    ;;
            esac
            ;;
        # spigot with an argument that specifies the one of the following actions
            # installation of both spigot server and service
            # test
            # uninstall of both spigot server and service
        "spigotserver")
            shift
            case "$1" in
                "--install")
                    install_package "SPIGOTSERVER"
                    create_spigotservice
                    ;;
                "--test")
                    test_spigotserver
                    ;;
                "--uninstall")
                    uninstall_spigotserver
                    ;;
                *)
                    handle_error "Invalid option for spigotserver: $1"
                    ;;
            esac
            ;;
        *)
            handle_error "Invalid command: $1"
            ;;
    esac          
}

main "$@"
