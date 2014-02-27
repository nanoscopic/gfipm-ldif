GFIPM Attribute LDIF Generation Tool
Copyright (C) 2014 David Helkowski
License: CC BY-NC-ND 3.0, license.txt, http://creativecommons.org/licenses/by-nc-nd/3.0/

The included generate_ldif.pl file generates LDIF files that are helpful for setting up an LDAP store to record users with GFIPM standardized information.

The script reads information from the 'gfipm.xml' file included, and can write out three different files.
All three have been generated via the script and included in the GIT repo under the output folder for ease of using those file directly.

The included gfipm.xml file has been preconfigured with an example class of a fictitous organization that would like to use a certain selection of attributes. You should alter gfipm.xml to have the attributes desired or needed for your organization. Multiple such class nodes can be placed within the gfipm.xml file.

The three files are as follows:

output/99-user.ldif
This is a file that is suitable for placing within the schema folder of an LDAP Server such as OpenDS or OpenDJ. Note that if there are existing attributes there, you should merge the contents of this file with the one here in order or you will obviously wipe out any existing custom attributes by using this file.
  
output/gfipm.ldif
This is a file that is suitable for applying to an actively running LDAP server using an ldapmodify command similar to the following template:
ldapmodify -h localhost -p 1389 -D "cn=[ldap admin user]" -w [ldap admin password] -c -a -f ~/gfipm.ldif

output/gfipm-map.txt
This is a file showing mappings of the creating custom LDAP names to the official schema names as distributed in the GFIPM specification.
  
Todo / Ideas:
- Add the entire list of GFIPM attributes from the specification into the gfipm.xml file. A proper layout of all of them within OID space has already been created, but has not yet been included in this project.
- Allow for group names to be set on the gfipm att nodes themselves, as an easier way to select which attributes you want to use in your classes.
- Allow for wildcard OID expressions to be used when specifying attributes.
- Allow for required attributes to be set, not just optional ( MAY ) ones
- Choose a better name than '99-user.ldif' for placing in LDAP store schema folder
- Turn the script into a full fledged CPAN module, potentially as application within the App:: space
- Add code to allow the script to detect various popular LDAP stores and be able to automatically import the new stuff in for you.
- Make a database of commonly used schemas somewhere, and have the script use it remotely, so that it can cover more things besides the GFIPM standard.

Version History:
1.0 - Initial release on github
