#Churchbells

Basic script designed to play bell chimes at a church. It is super lightweight and should run on practically any linux machine.

When the script is executed, it will chime in the hour and play two files from the relavant folder and log the files that were played. There is a hidden file to keep track of the last files played.

For everyday hymns, the default folder is used. There are special folders for Christmas, July 4, and Easter. Christmas eve will also play from the Chistmas folder. 

General and Easter chimes have been provided, and Christmas and July 4 chimes are being worked on. It will play any .wav files you place in the folder, so feel free to use your own sound files. 

#Activation
Currently, the best way to trigger the chimes is to set up a cron scheduler for the times you would like the bells to go off. For example, if I wanted to set them to go off at noon and six, the notation would be as follows:
0 12,18 * * * /path/to/churchbells/bells.sh

You can set up/edit a cron scheduler with crontab -e
