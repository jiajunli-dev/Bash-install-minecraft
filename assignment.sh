#!/usr/bin/env bash

# TODO Write down your name and studentnumber of the author(s)
# Jiajun Li (1056944) and Choukri Bouchrit (1059788)

# Global variables
# TODO Define (only) the variables which require global scope
source dev.conf

    #if [ -f "$INSTALL_DIR/Minecraft/Minecraft.deb" ]; then
    #     echo "Minecraft.deb is already downloaded"
    # else
    #     sudo curl -o "$INSTALL_DIR/Minecraft/Minecraft.deb" "$MINECRAFT_URL"
    # fi

    # if [ -f "$INSTALL_DIR/BuildTools/spigot.jar" ]; then
    #     echo "BuildTools.jar is already downloaded"
    # else
    #     sudo curl -o "$INSTALL_DIR/BuildTools/spigot.jar" "$BUILDTOOLS_URL"
    # fi

# INSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_with_apt() {
    # Do NOT remove next line!    
    echo "function install_with_apt"

    local package=$1
    if [ "$package" = "update" ]; then
        sudo apt update || handle_error "Failed to update apt"
        echo "Updated apt sources"
        sudo apt install openjdk-17-jdk -y || handle_error "Failed to install openjdk-17-jdk"
        echo "Installed openjdk-17-jdk"
    fi
        
    if [ "$package" = "install dependencies" ]; then
        for package in "gdebi" "wget" "make" "curl"; do
            sudo apt install "$package" || handle_error "Failed to install $package"
            echo "Installed $package"
        done
    fi
        
    if [ "$package" = "autoremove" ]; then
        for package in "gdebi wget" "make" "curl"; do
            sudo apt remove "$package" || handle_error "Failed to remove $package"
            echo "Removed $package"  
        done
    fi
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_package() {
    # Do NOT remove next line!
    echo "function install_package"

    local package=$1
    if [ ! -f "$INSTALL_DIR/setup_log.txt" ]; then
        handle_error "Setup function has not been executed. Please run setup first"
    fi
    
    case "$package" in
        "MINECRAFT")  
            local minecraft_dir="${INSTALL_DIR}/minecraft"
            mkdir "$minecraft_dir"
            
            if [ -f "$minecraft_dir/minecraft.deb" ]; then
                echo "Minecraft.deb is already downloaded"
                exit 1
            else 
                local minecraft_url="$MINECRAFT_URL"
                local minecraft_file="$minecraft_dir/minecraft.deb"
                sudo curl -o "$minecraft_file" "$minecraft_url" || handle_error "Failed to download Minecraft"
            fi

            sudo gdebi -n "$INSTALL_DIR/minecraft/minecraft.deb" || handle_error "Failed to install Minecraft"
            ;;
        "SPIGOTSERVER")          
            local spigot_dir="${INSTALL_DIR}/server"
            mkdir "$spigot_dir"

            if [ -f "$spigot_dir/spigot.jar" ]; then
                echo "spigot.jar is already downloaded"
                exit 1
            else
                local spigot_url="$BUILDTOOLS_URL"
                local spigot_file="$spigot_dir/BuildTools.jar"
                sudo curl -o "$spigot_file" "$spigot_url" || handle_error "Failed to download Spigot"
            fi

            cp -n spigotstart.sh "$INSTALL_DIR/server/spigotstart.sh" || handle_error "Failed to copy spigotstart.sh"
            sudo chmod +x "$INSTALL_DIR/server/spigotstart.sh" || handle_error "Failed to provide execute permission"

            cd "$INSTALL_DIR/server" || handle_error "Failed to change directory to spigotserver"
            sudo java -jar BuildTools.jar || handle_error "Failed to build spigotserver"
            mv spigot-*.jar spigot.jar || handle_error "Failed to move spigot.jar"

            java -jar /tmp/apps/server/spigot.jar || handle_error "Failed to build spigotserver"
            ;;
    esac
}


# CONFIGURATION

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function configure_spigotserver() {
    # Do NOT remove next line!
    echo "function configure_spigotserver"

    sudo apt install ufw -y || handle_error "Failed to install ufw"  

    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    sudo ufw allow ssh || handle_error "Failed to allow SSH port with ufw"
    sudo ufw enable || handle_error "Failed to enable ufw"
    
    sudo ufw allow "$SPIGOTSERVER_PORT" || handle_error "Failed to allow Spigot server port $spigot_port with ufw"

    local server_properties="$INSTALL_DIR/server/server.properties"
    sudo sed -i 's/\(gamemode=\)survival/\1creative/' "$server_properties" || handle_error "Failed to configure gamemode in server.properties"

    sudo systemctl restart spigot || handle_error "Failed to restart Spigot service"
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function create_spigotservice() {
    # Do NOT remove next line!
    echo "function create_spigotservice"
    
    sudo cp spigot.service /etc/systemd/system/spigot.service || handle_error "Failed to copy spigot.service"
    sudo systemctl daemon-reload || handle_error "Failed to reload systemd"
    sudo systemctl enable spigot.service || handle_error "Failed to enable spigot.service"
}

# ERROR HANDLING

# TODO complete the implementation of this function
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # TODO read the arguments from $@
        # Make sure NOT to use empty argument values

    # TODO print a specific error message
    echo "Error: $1"
    # TODO exit this function with an integer value!=0
    exit 1
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_minecraft() {
    # Do NOT remove next line!
    echo "function rollback_minecraft"

    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_spigotserver {
    # Do NOT remove next line!
    echo "function rollback_spigotserver"

    # TODO if something goes wrong then call function handle_error

}


# UNINSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_minecraft {
    # Do NOT remove next line!
    echo "function uninstall_minecraft"  

    # TODO remove the directory containing minecraft 

    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotserver {
    # Do NOT remove next line!
    echo "uninstall_spigotserver"  
    
    # TODO remove the directory containing spigotserver 

    # TODO create a service by calling the function create_spigotservice

    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotservice {
    # Do NOT remove next line!
    echo "uninstall_spigotservice"

    # TODO disable the spigotservice with systemctl disable
    # TODO delete /etc/systemd/system/spigot.service

    # TODO if something goes wrong then call function handle_error
    
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function remove() {
    # Do NOT remove next line!
    echo "function remove"

    # TODO Remove all packages and dependencies

    # TODO if something goes wrong then call function handle_error

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

}

function test_spigotserver() {
    # Do NOT remove next line!
    echo "function test_spigotserver"    

    # TODO Start the spigotserver

    # TODO Check if spigotserver is working correctly
        # e.g. by checking if the API responds
        # if you need curl or aNOTher tool, you have to install it first

    # TODO Stop the spigotserver after testing
        # use the kill signal only if the spigotserver canNOT be stopped normally

}

function setup() {
    # Do NOT remove next line!
    echo "function setup"    
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Creating directorie: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR" || handle_error "Failed to create directorie: $INSTALL_DIR"
    else
        echo "$INSTALL_DIR directory already exists"
    fi

    local log_file="setup_log.txt"
    echo "$(date): Setup function executed" >> "$INSTALL_DIR/$log_file"

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

create_spigotservice

#main "$@"
