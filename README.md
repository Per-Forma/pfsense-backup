# pfsense-backup
Automate pfSense firewall XML configuration backups for multiple appliances

## What's here
The pfSense opensource firewall is a great tool for networks with a budget. However, backups are a manual process unless you choose to pay for the service.

pfSense posts, in their docs, a method of pulling down the config in a similiar method to this project, however, testing has proven the wget method they suggust to not work for newer pfSense versions. 
Investigation revealed that a client web browser uses a MIME Multipart Media Encapsulation Upload method to post the form which initiates the configuration download request. This project replicates the behavior of a web browser.
(https://doc.pfsense.org/index.php/Remote_Config_Backup)

## How it works
We use a configuration file `pfhosts` that must contain a space delimitated list of hosts to connect to, a username, and a password. Further details are included in the file

We then connect to the specified hosts, attempt to login, and then download the XML configuration file as `{hostname}.xml`

Each host's donloaded XML config file is overwritten on each run and  this project doesn't attempt to track history. We suggust these files be stored in a CVS or GIT repo to accomplish that task.

## What it works with
This project employs a version check that is checked for each appliance. Currently, it will attempt to backup versions `2.3.x` and `2.4.x`
This is mainly due to a change in the pfSense project reguarding the naming of the form controls from the configuration backup web page.

Future versions should expand on the supported versions.

### Fully Tested pfSense Versions
Below is a list of versions that have been confirmed to work with the current branch.

2.3.1-RELEASE-p1
2.4.1-RELEASE