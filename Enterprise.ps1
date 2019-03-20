#                                                               ..........
#       .          .............'..''''''',,'''.           ....................
#     ..............................''.......;cc'       ..........................
#        .      .............';:;,,;::;,,,,,,,;,.     ..............................
#                             .'''''''.              .''....'.........................
#                                ......            ............................''''....
#                                 .......         ...........................';cc;,''...
#                                   ......       ..'''.......................;oooc;,,''.
#                                    ...'.........'''''''''.........''........:ddlc:,'...
#                          .. ...................''''''''''''',,..'ck0d;......;odooc;'...
#                          ...';:;,......,;::;;;,,'',,,,,,,,',;:;;:oO0x:,''...;ooolc;'''.
#                             ............,:::::;'',,,,,,,,,,;;;;;::cc:;,,''',cooc:;,'''.
#                                   ......      ..',,,,,,,,,;:::;;;;;;;;;;;;;cddl:;;,''..
#                                 .......         .',,,,,,,;;:::::;;;;;;;;;;;;clc:;,'''.
#                                .......           .',,,;;;;:::;:::::;;;;;;,,,,;;,,'''.
#                              ........             .';;;;;::::;;;;::::;;;,,,,,,,,,,'.
#          .........        ..................,,.     .;;;;;;;;;;;;;::::;;,,,,,,;;,'.
#  .....'..      ..,,;;;;;;;;;;;;,,;::::;;;;;col'       .,;::;;;;;::::::;;,,,,,,'..
#       .          .............'..''''''',,'''.          ..',;;:::::::;;;;;,'..
#                                                             ....'''''''...
# Enterprise v1.0
# Written by wolfy
# 22 July 2018
# This script is intended to be used for discovering all hosts on a Class B
#     network. It then outputs a csv containing all host ips, with the option
#     to include TTL as well. This takes a *very* long time, and is intended
#     to be used for finding hosts that may not be currently tracked by anyone
#
# NOTE: The default class B scanned is 10.x.x.x,

$oct1 = $oct2 = $ip = 0

# Iterates through each possible value in the last octet
function Class-C-Map($oct1, $oct2) {

    for ( $ip = 0; $ip -le 254; $ip++ ) {
        #echo 10.$oct1.$oct2.$ip
        ping -w 20 -n 1 10.$oct1.$oct2.$ip | sls "Reply" >> ENT_replies.txt
    }
}

# Iterates through each possible value in the third octet
function Slash-20-Map($oct1) {

    for ( $oct2 = 0; $oct2 -le 254; $oct2++ ) {
        echo "Scanning 192.$oct1.$oct2.0/24..."
        Class-C-Map $oct1 $oct2
    }
}

# Iterates through each possible value in the second octet
function Class-B-Map {
    for ( $oct1 = 0; $oct1 -le 254; $oct1++ ) {
        Slash-20-Map $oct1
    }
}

# Parses out the IP address from the file containing the replies
function Parse-IP-Address {
    $infile  = gc .\ENT_replies.txt
    $ipregex = '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' # regex to grab the IP address from reply data
    $infile | sls -Pattern $ipregex | % { $_.Matches } | % { $_.Value } > ENT_found_hosts.csv
}

# Parses out the IP address and TTL from the file containing the replies
function Parse-IP-TTL {
    $infile   = gc .\ENT_replies.txt

    $ipregex  = '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' # regex to grab the IP address from reply data
    $ttlregex = '(\d+)(?!.*\d)'                          # regex to grab the TTL from reply data

    $infile | sls -Pattern $ipregex | % { $_.Matches } | % { $_.Value } > ENT_found_IPs_only.csv
    $infile | sls -Pattern $ttlregex | % { $_.Matches } | % { $_.Value } > ENT_found_TTLs_only.csv

    $ips = gc .\ENT_found_IPs_only.csv
    $ttls = gc .\ENT_found_TTLs_only.csv

    Clear-Content -path * -filter ENT_found_hosts.csv -force

    for ( $i = 0; $i -lt $ips.Count; $i++ ){
        ( '{0},{1}' -f $ips[$i], $ttls[$i] ) | ac ENT_found_hosts.csv
    }

    # Delete the temp files
    Remove-Item -path * -filter ENT_found_IPs_only.csv -force
    Remove-Item -path * -filter ENT_found_TTLs_only.csv -force
}

# Run the script
echo "Starting scan..."
Class-B-Map
Parse-IP-address
#Parse-IP-TTL
