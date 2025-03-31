!#/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade

# Install the necessary packages
sudo apt install -y git

# Install Java
sudo apt install openjdk-21-jre-headless

# Check the Java version
java -version

# Create a new directory for the Minecraft server
wget https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar

# Run the server
java -Xmx1024M -Xms1024M -jar server.jar nogui

# Accept the EULA
echo "eula=true" > eula.txt

# Allow the Minecraft port
sudo ufw allow 25565

# Start the server in the background
nohup java -Xmx1024M -Xms1024M -jar server.jar nogui > server.log 2>&1 &