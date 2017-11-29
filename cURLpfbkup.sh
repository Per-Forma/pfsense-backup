host=$1
user=$2
pass=$3

echo 'Connecting to '$host

#Get the initial CSRF Magic Token
csrf=$(curl -s -S --insecure --cookie-jar cookies/${host}cookie.txt http://${host}/diag_backup.php | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/')


crlf=$'\r\n' #creates variable representing Windows (CR LF) required for line termination by the MIME Multipart Media Encapsulation file upload specification.

#Get the 2nd CSRF Magic Token
csrf2=$(curl -s -S --location --insecure --cookie cookies/${host}cookie.txt --cookie-jar cookies/${host}cookie.txt --data "login=Login&usernamefld=$user&passwordfld=$pass&__csrf_magic=$csrf" http://${host}/diag_backup.php | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/;q')

#Attention: Need to write a check here for failed login.

#After logging in, Get the pfSense version
pfver=$(curl -s -S --location --insecure --cookie cookies/${host}cookie.txt --cookie-jar cookies/${host}cookie.txt http://${host}/index.php | grep -P '<strong>\d\.\d\.\d.*<\/strong>' | grep -Po '\d\.\d\.\d')

#Break apart the full version into Major Minor and Point Release
pfmaver=$(echo $pfver | grep -Po '^\d')
pfmiver=$(echo $pfver | grep -Po '(?<=^\d\.)\d')
pfptver=$(echo $pfver | grep -Po '(?<=^\d\.\d\.)\d')

#This IF checks for a known compatible version of pfSense to backup
if [ "$pfmaver" == 2 ]; then
	echo 'Major Version 2'
	if [ "$pfmiver" == 3 ]; then
		echo 'Minor Version 3'
		buttonaction='Submit'
	elif [ "$pfmiver" == 4 ]; then
		echo 'Minor Version 4'
		buttonaction='download'
	else
		echo 'Unknown Minor Version'
		exit
	fi
else
	echo 'Unknown Major Version'
	exit
fi

#Building the MIME Multipart Media Encapsulation file
poststring="-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"__csrf_magic\"${crlf}${crlf}$csrf2${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"backuparea\"${crlf}${crlf}${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"donotbackuprrd\"${crlf}${crlf}yes${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"encrypt_password\"${crlf}${crlf}${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"${buttonaction}\"${crlf}${crlf}Download configuration as XML${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"restorearea\"${crlf}${crlf}${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"conffile\"; filename=\"\"${crlf}Content-Type: application/octet-stream${crlf}${crlf}${crlf}-----------------------------7e12e22ee971f00${crlf}Content-Disposition: form-data; name=\"decrypt_password\"${crlf}${crlf}${crlf}-----------------------------7e12e22ee971f00--${crlf}"

#Post file to initiate XML backup
curl -s -S --location --insecure --cookie cookies/${host}cookie.txt --cookie-jar cookies/${host}cookie.txt -H "Content-Type: multipart/form-data; boundary=---------------------------7e12e22ee971f00"  -d "$poststring" http://${host}/diag_backup.php > ${host}.xml

#Deleting cookie after completion
rm cookies/${host}cookie.txt
