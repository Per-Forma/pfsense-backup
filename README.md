# pfsense-backup
Automate pfSense firewall XML configuration backups for multiple appliances

## What's here
The pfSense opensource firewall is a great tool for networks with a budget. However, backups are a manual process unless you choose to pay for the service.

pfSense posts on their docs a method of pulling the config as does this project attempts to, however, testing has proven the wget method they suggust to not work. 
Investigation revealed that a client web browser uses a MIME Multipart Media Encapsulation Upload method to initiate the configuration pull request. This project replicates that behavior.
(https://doc.pfsense.org/index.php/Remote_Config_Backup)

## How it works
We use a configuration file `pfhosts` that should contain a space delimitated list of hosts to connect to, a username, and a password.

We then connect to the host attempt to login to it and then download the XML configuration file as `{hostname}.xml`

When downloading the config backup file is overwritten each time and doesn't track history. Internally we place these files in a CVS to accomplish that task.

## What it works with
This project employs a version check of the remote pfSense appliance. Currently, it will attempt to backup versions `2.3.x` and `2.4.x`
This is mainly due to a change in the pfSense project reguarding the naming of the form controls from the configuration backup web page.

Future versions should expand on the supported versions.
