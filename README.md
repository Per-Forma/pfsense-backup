# pfsense-backup
Automate pfSense firewall XML configuration backups for multiple appliances

## What it is
The pfSense opensource firewall is a great tool for networks with a budget. However, backups are a manual process unless you pay for the service.

The pfSense project posts, in their docs, a method of pulling the config for automated backup using a similiar method to this project, however, testing has shown that the wget method they suggust does not work for some pfSense versions. 
Investigation revealed that a client web browser uses a MIME Multipart Media Encapsulation Upload method to post the form which initiates the configuration download request. Whereas the wget method is limited to a URL Encoded Form post. This project replicates the behavior of a web browser and posts the MIME file to initiate the download.
(https://doc.pfsense.org/index.php/Remote_Config_Backup)

### Usage
#### Get Started
Edit the `pfhosts` file to include a line for each appliance you wish to pull backups from. Lines should read out as follows:
`hostname username password`

Execute the shell script named `pfbkup.sh`

## How it works
We use a configuration file `pfhosts` that must contain a space delimitated list consisting of a host to connect to, username, and a password. Further details are included in the file as comments.

We then connect to each specified hosts in succession, attempt to login, and then download the XML configuration file which is saved as `{hostname}.xml`

Each host's downloaded XML config file is stored in the same directory the scripts are executed from and are overwritten on each run. This project does not attempt to track config change history. We suggust these files be stored in a CVS or GIT repo it change tracking is desired.

## What it works with
This project employs a version check that is run aganst each appliance after attempting to login. Currently, it will backup versions `2.3.x` and `2.4.x`
This functionality was initially necessary due to a change in the pfSense project reguarding the naming of form controls on the configuration backup page.

Future versions should expand on the supported versions of pfSense.

### Fully Tested pfSense Versions
Below is a list of versions that have been confirmed to work with the current branch. This list is not all inclusive, only a list of confirmed working versions.

`2.3.1-RELEASE-p1`

`2.4.1-RELEASE`
