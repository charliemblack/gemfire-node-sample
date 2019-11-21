# #!/bin/bash

# # Attempt to set APP_HOME
# # Resolve links: $0 may be a link
# PRG="$0"
# # Need this for relative symlinks.
# while [ -h "$PRG" ] ; do
#     ls=`ls -ld "$PRG"`
#     link=`expr "$ls" : '.*-> \(.*\)$'`
#     if expr "$link" : '/.*' > /dev/null; then
#         PRG="$link"
#     else
#         PRG=`dirname "$PRG"`"/$link"
#     fi
# done
# SAVED="`pwd`"
# cd "`dirname \"$PRG\"`/.." >&-
# APP_HOME="`pwd -P`"
# cd "$SAVED" >&-
$APP_HOME = "c:/users/pivotal/Src/Repos/gemfire-node-sample"

$DEFAULT_LOCATOR_MEMORY = "128m"

$DEFAULT_SERVER_MEMORY = "1024m"

$DEFAULT_JVM_OPTS = "--J=-XX:+UseParNewGC "
$DEFAULT_JVM_OPTS += "--J=-Djava.net.preferIPv4Stack=true "
$DEFAULT_JVM_OPTS += "--J=-XX:+UseConcMarkSweepGC "
$DEFAULT_JVM_OPTS += "--J=-XX:CMSInitiatingOccupancyFraction=50 "
$DEFAULT_JVM_OPTS += "--J=-XX:+CMSParallelRemarkEnabled "
$DEFAULT_JVM_OPTS += "--J=-XX:+UseCMSInitiatingOccupancyOnly "
$DEFAULT_JVM_OPTS += "--J=-XX:+ScavengeBeforeFullGC "
$DEFAULT_JVM_OPTS += "--J=-XX:+CMSScavengeBeforeRemark "
$DEFAULT_JVM_OPTS += "--J=-XX:+UseCompressedOops "
$DEFAULT_JVM_OPTS += "--mcast-port=0"

$HOSTNAME = hostname
$LOCATORS = $HOSTNAME + "[10334]," + $HOSTNAME + "[10335]"


$MY_CLASSPATH = $APP_HOME + "/etc"


$STD_SERVER_ITEMS = " "
$STD_SERVER_ITEMS += "--rebalance "
$STD_SERVER_ITEMS += "--classpath=" + $MY_CLASSPATH

$STD_LOCATOR_ITEM = ""

$firstTimeLocator = true

# function waitForPort($portNum) {
# 	$rVal = false
#     while (!rVal) {
#         echo -n "."
#         sleep 1
#         rVal = Test-NetConnection -ComputerName $HOSTNAME -Port $portNum
# 	}
# }

Function launchLocator($locNum) {
	$dirName = $APP_HOME + "/data/locator$locNum"
	New-Item -ItemType "directory" -Path $dirName
    Push-Location $dirName

	$securityProps = $APP_HOME + "/etc/gfsecurity.properties"
	$locatorName = "locator$locNum" + "_$HOSTNAME"
	$locatorDir = $APP_HOME + "/data/locator" + $locNum
    gfsh -e "start locator --security-properties-file=$securityProps --initial-heap=$DEFAULT_LOCATOR_MEMORY --max-heap=$DEFAULT_LOCATOR_MEMORY $DEFAULT_JVM_OPTS --name=$locatorName --port=1033$locNum --dir=$locatorDir --locators=$LOCATORS --classpath=$MY_CLASSPATH --J=-Dgemfire.security-manager=org.apache.geode.examples.security.ExampleSecurityManager"

    Pop-Location
}

Function launchServer($serverNum) {
	$dirName = $APP_HOME + "/data/server$serverNum"
	New-Item -ItemType "directory" -Path $dirName
	Push-Location $dirName

	$securityProps = $APP_HOME + "/etc/gfsecurity.properties"
	$serverPort = "4040$serverNum"
	$serverName = "server$serverNum" + "_$HOSTNAME"

    gfsh -e "connect --locator=$LOCATORS  --security-properties-file=$APP_HOME/etc/gfsecurity.properties" -e "start server --locators=$LOCATORS --security-properties-file=$securityProps --server-port=$serverPort --J=-Xmx$DEFAULT_SERVER_MEMORY --J=-Xms$DEFAULT_SERVER_MEMORY $DEFAULT_JVM_OPTS --name=$serverName --dir=$APP_HOME/data/server$serverNum $STD_SERVER_ITEMS"

    Pop-Location

}


For ($i=4; $i -le 5; $i++) {
    launchLocator($i)
    # Stagger the launch so the first locator is the membership coordinator.
    Start-Sleep -Seconds 1
}

# Only need to wait for one locator
# waitForPort 10334
# waitForPort 10335

Start-Sleep -Seconds 10

Push-Location $APP_HOME/data/locator4

gfsh -e "connect --locator=$LOCATORS  --security-properties-file=$APP_HOME/etc/gfsecurity.properties" -e "configure pdx --read-serialized=true --disk-store=DEFAULT"

Pop-Location

For ($i=1; $i -le 2; $i++) {
    launchServer($i)
}

#wait

Push-Location $APP_HOME/data/server1

gfsh -e "connect --locator=$LOCATORS --security-properties-file=$APP_HOME/etc/gfsecurity.properties" -e "create region --name=test --type=PARTITION"

Pop-Location

#curl -X PUT "http://localhost:8080/book/put?isbn=0525565329" `
#  -H "Content-Type: application/json" `
#  -d "{
#  "FullTitle": "The Shining",
#  "ISBN": "0525565329",
#  "MSRP": "9.99",
#  "Publisher": "Anchor",
#  "Authors": "Stephen King"
#}"

curl -X PUT "http://localhost:8080/book/put?isbn=0525565329" -H "Content-Type: application/json" -d "{FullTitle: The Shining,ISBN: 0525565329,MSRP: 9.99,Publisher: Anchor,Authors: Stephen King}"
#curl -X PUT http://localhost:8080/book/put?isbn=0525565329 -d "{\"FullTitle\": \"The Shining\",\"ISBN\": \"0525565329\",\"MSRP\": \"9.99\",\"Publisher\": \"Anchor\",\"Authors\": \"Stephen King\"}"

#curl -X GET http://localhost:8080/book/get?isbn=0525565329