#!/bin/bash
cd ~/minecraft-server/
exec java -Xmx4G -Xms1G -jar server.jar nogui

# chmod +x start.sh
# sudo systemctl daemon-reexec
# sudo systemctl daemon-reload
# sudo systemctl enable minecraft.service
# sudo systemctl start minecraft.service
