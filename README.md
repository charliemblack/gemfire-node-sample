Example book service

# Install 
In the future the download location one would goto either the GemFire or Cloud Cache product download pages in https://network.pivotal.io  Since we are currently in a phase where the binaries aren't offfically available I can't post a image of how to download.


* GemFire - https://network.pivotal.io/products/pivotal-gemfire
* Cloud Cache - https://network.pivotal.io/products/p-cloudcache


Once you have downloaded the right artifact copy it to the `<projet>` directory.    This is important for the pushing to PCF.

```bash
git clone <exmples repo>
cd <project>/scripts
./startGemFrire.sh
cd ..
npm install gemfire-nodejs-all-v2.0.0-build.3.tgz 
npm install
```

# Run Locally
 It is very common for developers to run locally so they can iterate quickly on the features that they are working.   Since we are going to eventually pushed to Pivotal Cloud Foundary we are going to target our local environement to mock a Cloud Foundary environement.

 Cloud foundary injects the services binding through a `VCAP_SERVICES` environement varible.    So we are going to mock that environement varible to do local testing so our application doesn't have to handle any environement differantly.

## Expose the VCAP_SERVICES to the application through the environement 
```
export VCAP_SERVICES='{"p-cloudcache":[{"label":"p-cloudcache","provider":null,"plan":"dev-plan","name":"pcc-dev","tags":["gemfire","cloudcache","database","pivotal"],"instance_name":"pcc-dev","binding_name":null,"credentials":{"distributed_system_id":"0","gfsh_login_string":"connect --url=https://localhost:7070/gemfire/v1 --user=super-user --password=1234567 --skip-ssl-validation","locators":["localhost[10334]"],"urls":{"gfsh":"https://localhost:7070/gemfire/v1","pulse":"https://localhost:7070/pulse"},"users":[{"password":"1234567","roles":["cluster_operator"],"username":"super-user"},{"password":"1234567","roles":["developer"],"username":"app"}],"wan":{"sender_credentials":{"active":{"password":"no-password","username":"no-user"}}}},"syslog_drain_url":null,"volume_mounts":[]}]}'
```
## Run some servers 

In the scripts directory there is a `startGemFire.sh` command that will start up two locators and two cache servers.    The locators allow clients to find the cache servers.   To simplify local development I have the `startGemFire.sh` script create the regions for you.

## Run the NodeJS server 
```
node src/server.js
```

## Add a book locally 
```
curl -X PUT \
  'https://cloudcache-node-sample.apps.pcfone.io/book/put?isbn=0525565329' \
  -H 'Content-Type: application/json' \
  -d '{
  "FullTitle": "The Shining",
  "ISBN": "0525565329",
  "MSRP": "9.99",
  "Publisher": "Anchor",
  "Authors": "Stephen King"
}'
```
## Get a book locally
```
curl -X GET \
  'https://cloudcache-node-sample.apps.pcfone.io/book/get?isbn=0525565329' \
  -H 'Content-Type: application/json' 

```

# Run on PCF

Please reviewe the manifest and at minimum update or change the service instance that the application will be bound to.   In the example I have bound the application instance to `cloudcache-dev`.   Once you have done that just cf push your application and run the curl commands against that server.

## Create the Cloud Cache service instance

1 -  Create a cloud cache instance in Pivotal Cloud Foundary.   The manifest assumes that the cloud cache instance is called `cloudcache-dev`.
```
$ cf create-service p-cloudcache dev-plan cloudcache-dev
```
2 - Create the service key 
```
$ cf create-service-key cloudcache-dev cloudcache-dev_service_key
```
3 - Using the GemFire command line tool ``gfsh`` create the region with the policy that we want for the data.

```
voltron:gemfire cblack$ gfsh
    _________________________     __
   / _____/ ______/ ______/ /____/ /
  / /  __/ /___  /_____  / _____  / 
 / /__/ / ____/  _____/ / /    / /  
/______/_/      /______/_/    /_/  

Monitor and Manage Pivotal GemFire
gfsh>connect --use-http=true --url=https://somehost/gemfire/v1 --user=cluster_operator --password=*****

Successfully connected to: GemFire Manager HTTP service @ https://somehost/gemfire/v1
gfsh>create region --name=test --type=PARTITION
                     Member                      | Status
------------------------------------------------ | -----------------------------------------------------------------------------------
cacheserver-7541bb25-71b2-4ae7-ad80-9d518e18facd | Region "/test" created on "cacheserver-7541bb25-71b2-4ae7-ad80-9d518e18facd"

Cluster-0 gfsh>exit
```
Note: The version of Cloud Cache I am using is backed by GemFire version 9.8.3 - make sure you are using the same versions of GemFire as your cloud cache instance.

4 -`cf push` the application and give it a try using postman or curl.

## Add a book 
```
curl -X PUT \
  'https://cloudcache-node-sample.apps.pcfone.io/book/put?isbn=0525565329' \
  -H 'Content-Type: application/json' \
  -d '{
  "FullTitle": "The Shining",
  "ISBN": "0525565329",
  "MSRP": "9.99",
  "Publisher": "Anchor",
  "Authors": "Stephen King"
}'
```
## Get a book by ISBN
```
curl -X GET \
  'https://cloudcache-node-sample.apps.pcfone.io/book/get?isbn=0525565329' 
```
