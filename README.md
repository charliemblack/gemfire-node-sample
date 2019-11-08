Example book service

# Install 
In the future the download location one would goto either the GemFire or Cloud Cache product download pages in https://network.pivotal.io  Since we are currently in a phase where the binaries aren't offfically avaible I can't post a image of how to download.


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

So if you haven't created a Cloud Cache service instance go and create one now.    Using the command line or browser interface create a Cloud Cache instance and it corrisponding service key

## Create the Region that the application will use

A region is the main storage concept in GemFire/Cloud Cache.   So before we can store books we need to create a region.   Review your service ket that you have created - the JSON element `gfsh_login_string` will have the text you need to type into gfsh to connect.    From our above `VCAP_SERVICES` example we can see that string as `connect --url=https://localhost:7070/gemfire/v1 --user=super-user --password=1234567 --skip-ssl-validation`.   Just make sure to download the right version of GemFire to connect to your systems Cloud Cache.

```
gfsh
connect --url=https://localhost:7070/gemfire/v1 --user=super-user --password=1234567 --skip-ssl-validation
create region --name=owin_example --type=PARTITION
```

## Push the NodeJS application

```
cd <project>
cf push
```


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