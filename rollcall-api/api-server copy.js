//-- 	Setting Configuration 	--//
const config = require('config');
let azure;
let access;
let group;
let sync;
let rollcall;
let mode;

azure = config.get('azure');
access = config.get('access');
sync = config.get('sync');
group = config.get('group');
rollcall = config.get('rollcall');
mode = config.get('mode');

function readConfig () {
	azure = config.get('azure');
	access = config.get('access');
	sync = config.get('sync');
	group = config.get('group');
	rollcall = config.get('rollcall');
	mode = config.get('mode');


};
readConfig();
async function writeConfig(data, type) {
	return new Promise (resolve => {
	var configFile = fs.readFileSync("./config/default.json");
	var configJSON = JSON.parse(configFile)
	
		if(type == azure){
		}
		if(type == access){
		configJSON.access.URL = data.url
		configJSON.access.CLIENT_ID = data.client_id
		configJSON.access.CLIENT_SECRET = data.client_secret
		configJSON.access.DOMAIN = data.domain
		var configContent = JSON.stringify(configJSON);
		}

		if(type == sync){
		configJSON.sync.synctype = data.synctype
		configJSON.sync.syncvalues = data.syncvalues
		configJSON.sync.frequency = data.frequency
		configJSON.sync.day = data.day
		configJSON.sync.time = data.time
		var configContent = JSON.stringify(configJSON);
		}

		if(type == group){
		configJSON.group.synctype = data.synctype
		configJSON.group.syncvalues = data.syncvalues
		configJSON.group.frequency = data.frequency
		configJSON.group.day = data.day
		configJSON.group.time = data.time
		var configContent = JSON.stringify(configJSON);
		}
	
	fs.writeFile("./config/default.json", configContent, 'utf8', function (err) {
		if (err) {
			console.log("An error occured while writing JSON Object to File.");
			return console.log(err);
		}
		console.log("Updated config file.");
	});
	resolve('done')
})
};

//--							--//

const Koa = require('koa')
const cors = require('@koa/cors');
const Router = require('koa-router')
const bodyParser = require('koa-bodyparser')
const mount = require('koa-mount');
const basicAuth = require('koa-basic-auth');
const {google} = require('googleapis');
const schedule = require('node-schedule');
const fs = require('fs');
const readline = require('readline');

//Added for Azure
const fetch = require('./fetch');
const auth = require('./auth');

const jsondiffpatch = require('jsondiffpatch')

const chalk = require('chalk');

const router = new Router()  
const app = new Koa();
app.use(bodyParser())
app.use(router.routes())

// Adding CORS to remove Angular proxy dependency
app.use(cors())

const api_cred_user = rollcall.apiUser;
const api_cred_pass = rollcall.apiPassword;

app.use(async (ctx, next) => {
	try {
		await next();
	} catch (err) {
		console.log(err)
	  if (401 == err.status) {
		ctx.status = 401;
		ctx.set('WWW-Authenticate', 'Basic');
		ctx.body = 'Unauthenticated.';
	  } else {
		throw err;
	  }
}});
console.log(api_cred_pass)
if(api_cred_pass == "")
{
	console.log("API Credentials Not Set. Have you deleted ./config/default.JSON? Try running config.js again.")
	process.exit()
}

app.use(mount('/', basicAuth({ name: api_cred_user, pass: api_cred_pass})));


const superagent = require('superagent');

// Include the logger module
const winston = require('winston');
const { exit } = require('process');

const logger = winston.createLogger({
	format: winston.format.simple(),
	level: 'info',
	transports: [
	  new winston.transports.File({ filename: 'api-server.log',  maxsize: 1000, maxFiles: 2, tailable: true  })
	]
  });

const synclog = winston.createLogger({
	format: winston.format.simple(),
	

	level: 'info',
	transports: [
	  new winston.transports.File({ filename: 'sync.log', maxsize: 1000, maxFiles: 2, tailable: true })
	]
});

const PORT = process.env.PORT || 8080;

app.listen(PORT, () => {
	  
console.log(chalk
    `{white ====================================================================} {greenBright.bold 
        8888888b.          888 888                   888 888
        888   Y88b         888 888                   888 888
        888    888         888 888                   888 888
        888   d88P .d88b.  888 888  .d8888b  8888b.  888 888
        8888888P" d88""88b 888 888 d88P"        "88b 888 888
        888 T88b  888  888 888 888 888      .d888888 888 888
        888  T88b Y88..88P 888 888 Y88b.    888  888 888 888
        888   T88b "Y88P"  888 888  "Y8888P "Y888888 888 888 } {white
====================================================================}`+
    chalk`\nRollcall Server API is listening on {bold http://localhost:${PORT}}`+
    chalk`{white \nMode: ${mode} }`+
    chalk`{white \n====================================================================}`
	
    
        )
});
logger.info(new Date().toUTCString());

logger.info(`Rollcall Server API is listening on http://localhost:${PORT}}`)
//==================================================================================================================






//==========================================================
// Inbound Request API paths
//==========================================================

//--AZURE ROUTES--//

//---GET All Users---//
router.get('/azure/users', async function (ctx, next) {
	
	let result = await getAzureUsers();
	console.log('AAD Users Found: ' + result["value"].length + '\n');
	logger.info(new Date().toUTCString());
	
	logger.info('AAD Users Found: ' + result["value"].length + '\n');
	ctx.body = result
	await next();
	});

//---GET All Groups---//
router.get('/azure/groups', async function (ctx, next) {
	
	let result = await getAzureGroups();
	console.log('AAD Groups Found: ' + result["value"].length + '\n');
	logger.info('AAD Groups Found: ' + result["value"].length + '\n');
	ctx.body = result
	await next();
	});

//--GOOGLE ROUTES--//

//---GET All Users---//
router.get('/google/users', async function (ctx, next) {
	
	let result = await listAllGoogleUsers();
	console.log('Users Found: ' + result.length + '\n');
	logger.info(new Date().toUTCString());

	logger.info('Users Found: ' + result.length + '\n');
	ctx.body = result
	await next();
	});

//---GET All Groups---//
router.get('/google/groups', async function (ctx, next) {

	let result = await listAllGoogleGroups();
	console.log('Groups Found: ' + result.length + '\n');
	logger.info(new Date().toUTCString());
	logger.info('Groups Found: ' + result.length + '\n');
	ctx.body = result
	await next();
	});


//---PING---/
// Used to check if Access Sync is running
router.all('/ping', async function (ctx, next) {
	ctx.set('Access-Control-Allow-Origin', '*')
	
	let result = {status: 'ok'}
	ctx.body = result
	await next();
	});

//---Check Access---/
// Used to check if Azure API and Access API configured and can be accessed
router.get('/status', async function (ctx, next) {
	
	ctx.set('Access-Control-Allow-Origin', '*')
	
	let result = {
		azure: `${aadStatus}`,
		access: `${astatus}`
	  }
	ctx.body = result
	await next();
	});

router.get('/logs', async function (ctx, next) {
		ctx.set('Access-Control-Allow-Origin', '*')
		
		const stream = fs.createReadStream(__dirname + '/api-server.log')
	
		ctx.body = stream
		await next();
		});

router.get('/synclog', async function (ctx, next) {
		
		ctx.set('Access-Control-Allow-Origin', '*')
		const stream = fs.createReadStream(__dirname + '/sync.log')
		ctx.body = stream
		await next();
		});

//---GET All Users---//
router.get('/allusers', async function (ctx, next) {
	
	let result = await listAllUsers();
	console.log('Users Found: ' + result.length + '\n');
	logger.info(new Date().toUTCString());

	logger.info('Users Found: ' + result.length + '\n');
	ctx.body = result
	await next();
	});

//---GET AccessUsers---//
router.get('/allaccessusers', async function (ctx, next) {
	
	let result = await listAccessUsers();
	console.log('Access Users Found: ' + result.Resources.length + '\n');
	logger.info(new Date().toUTCString());

	logger.info('Access Users Found: ' + result.Resources.length + '\n');

	ctx.body = result.Resources
	
	await next();
	});

//---GET All Access Groups---//
router.get('/allaccessgroups', async function (ctx, next) {
	let result = await getAllAccessGroups();
	console.log('Access Groups Found: ' + result.length + '\n');
	logger.info(new Date().toUTCString());
	logger.info('Access Groups Found: ' + result.length + '\n');

	ctx.body = result
	await next();
	});

//---GET Access Directories---//
// List all directories that exist in Access
router.get('/accessdirs', basicAuth({ name: api_cred_user, pass: api_cred_pass}), async function (ctx, next) {
	let result = await getAccessDirs();
	console.log(result.items.length + ' directories found.\n');
	logger.info(new Date().toUTCString());

	logger.info(result.items.length + ' directories found.\n');

	ctx.body = result


	await next();

	});

//---POST Create Directory Users---//
// Creates a directory in Access for Sync
router.post('/createdir', async function (ctx, next) {
	let request = ctx.request.body
	
	let b = {
		'type': 'OTHER_DIRECTORY',
		'domains': [request.domains],
		'name': `${request.name}`
	}
	;
	ctx.set('Access-Control-Allow-Origin', '*')
	console.log('Creating Directory...')
	const result = await createDir(b);
	logger.info(new Date().toUTCString());
	console.log(result)
	logger.info('Creating Directory...')
	logger.info(result)
	ctx.body = result
	await next();
});

// Creates a directory in Access for Sync
router.delete('/deletedir', async function (ctx, next) {
	let request = ctx.request.body
	
	let id = request.id

	ctx.set('Access-Control-Allow-Origin', '*')
	console.log('Deleting Directory... ' )
	const result = await deleteDir(id);
	logger.info(new Date().toUTCString());

	logger.info('Deleting Directory...' + request)
	logger.info(result)
	ctx.body = result
	await next();
});

router.delete('/cleartenant', async function (ctx, next) {
	ctx.set('Access-Control-Allow-Origin', '*')
	console.log('Clearing Tenant Details... ' )
	const result = await clearTenantConfig();
	logger.info(new Date().toUTCString());

	logger.info('Clearing Tenant Details... ')

	astatus = null
	accessBearer = ''
	ctx.body = result
	await next();
});

//---GET All Groups---//
router.get('/allgroups', async function (ctx, next) {
	
	let result = await listAllGroups();
	console.log('Groups Found: ' + result.length + '\n');
	logger.info(new Date().toUTCString());

	logger.info('Groups Found: ' + result.length + '\n');
	ctx.body = result
	await next();
	});

//---Return Secrets for Access---//
// Gets credentials used for Access OAuth
router.get('/secrets', async function (ctx, next) {
	
	let result = await getSecrets();

	ctx.body = result
	await next();
	});

//---Return User Sync Settings---//
// Returns User Sync settings saved in database
router.get('/getusersync', async function (ctx, next) {
	
	let result = await getUserSyncSettings();
	ctx.body = result
	//await next();
	});

//---Return Group Sync Settings---//
// Returns Group Sync settings saved in database
router.get('/getgroupsync', async function (ctx, next) {
	
	let result = await getGroupSyncSettings();
	ctx.body = result

//	await next();
	});

//---Return Sync Schedule Settings---//
// Returns schedule settings saved in database
router.get('/getsyncschedule', async function (ctx, next) {
	
	let result = await getSchedule();
	ctx.body = result
	await next();
	});

//---Force Sync---//
// Forces an immediate sync
router.get('/forcesync', async function (ctx, next) {
	
	let result = await forceSync();
	ctx.body = {
		result: result
	}
	await next();
	});

//---Save Config for Access---//
// Saves credentials entered in UI into database for Access OAuth
router.post('/saveconfig', async function (ctx) {
	ctx.set('Access-Control-Allow-Origin', '*')

	let request = ctx.request.body

	let result = await saveCredentials(request)

	ctx.body = result
	});

//---Save Sync Settings from Rollcall---//
// Saves Sync Settings entered in UI into database 
router.post('/savesyncschedule', async function (ctx) {
	ctx.set('Access-Control-Allow-Origin', '*')

	let request = ctx.request.body

	let result = await saveSyncSchedule(request)
	let schedule = await getSchedule();
	doAll();
	ctx.body = {
		result: result,
		schedule: schedule
	};
	});

//---Save User Sync Settings from Rollcall---//
// Saves User Sync Settings entered in UI into database 
router.post('/savesyncusers', async function (ctx) {
	ctx.set('Access-Control-Allow-Origin', '*')

	let request = ctx.request.body
	let result = await saveSyncUsers(request)
	let schedule = await getSchedule();
	ctx.body = {
		result: result,
		schedule: schedule
	};
	});

//---Save Group Settings from Rollcall---//

// Saves Group Settings entered in UI into database 
router.post('/savesyncgroups', async function (ctx) {
	ctx.set('Access-Control-Allow-Origin', '*')
	let request = ctx.request.body
	let result = await saveSyncGroups(request)
	ctx.body = result
	});

//Clear Sync Schedule Config
router.post('/cleargroupconfig', async function (ctx) {

	
	let result = await clearGroupConfig()
	ctx.body = result
	});

router.post('/clearsyncconfig', async function (ctx) {

	
	let result = await clearSyncConfig()
	ctx.body = result
	});


//==========================================================
// General API functions
//==========================================================

//---Users---//

//Compare Azure User attributes with current Access User attributes
async function diffUsers(azureUser, accessUser) {
	const aadUser = azureUser;
	const auser = accessUser;
	
	const azureUserData = {
		name: {
			givenName: aadUser.givenName || null,
			familyName: aadUser.surname || null
		},
		emails: aadUser.mail,
		suspended: aadUser.accountEnabled,
		title: aadUser.jobTitle || null,
		department: aadUser.department || null,
		businessPhones: aadUser.businessPhones[0] || null
	 }
	 
	let aDept;
	if(auser["urn:scim:schemas:extension:enterprise:1.0"] != undefined){
		aDept = auser["urn:scim:schemas:extension:enterprise:1.0"]
		.department || null
	}
	 const accessUserData = {
		name: {
			givenName: auser.name.givenName || null,
			familyName: auser.name.familyName || null
		},
		emails: auser.emails[0].value,
		suspended: auser.active || null,
		title: auser.title || null,
		department: aDept,
		businessPhones: auser["phoneNumbers"][0].value || null
	 }
	 
	return new Promise (resolve => {
		var diffs = jsondiffpatch.diff(accessUserData, azureUserData)
		if (diffs) {
			let changes = jsondiffpatch.patch(azureUserData, diffs)
			
			const newBody = {
				changes,
				userlocation: auser.meta.location
			}
			                                                                                       
			resolve(newBody);
		}
		else {
			console.log("No User Attribute Updates Required.")
			resolve('')
		} 
	  });
}

//Compare AAD Group attributes with current Access Group attributes
function diffGroup(group, accessGroup) {
	const aadgroup = group;
	const agroup = accessGroup[0];
	const azureGroupData = {
		name: aadgroup.displayName || null,
	 }
	 const accessGroupData = {
		name:  agroup.displayName || null,
	 }
	return new Promise (resolve => {
		var diffs = jsondiffpatch.diff(accessGroupData, azureGroupData)
		if (diffs) {
			let changes = jsondiffpatch.patch(azureGroupData, diffs)
			console.log("Changes: \n" + `${agroup.displayName} will be renamed to ${changes.name}. \n` )
  
  synclog.info("Changes: \n" + `${agroup.displayName} will be renamed to ${changes.name}. \n` )
			const newBody = {
				changes,
				access_id: agroup.id,
				grouplocation: agroup.meta.location
			}                                                                                                
			resolve(newBody);
		}
		else {
			console.log('No Group Attribute Updates Required. \n')
			resolve('')
		} 
	  });
}

//==========================================================
// Access SCIM API functions
//==========================================================

//--Create User in Access--//
function createUser(users) {
	const user = users;
	return new Promise (resolve => {
	const schemas = [
	  "urn:scim:schemas:core:1.0", "urn:scim:schemas:extension:workspace:tenant:sva:1.0", "urn:scim:schemas:extension:workspace:1.0", "urn:scim:schemas:extension:enterprise:1.0"
	]
	const createUserBody = {
	   schemas: schemas,
	   userName: user.mail,
	   active: user.accountEnabled,
	   externalId: user.id,
	   title: user.jobTitle || null,
	   name: {
		   givenName: user.givenName || null,
		   familyName: user.surname || null
	   },
	   emails: user.mail,
	   phoneNumbers: user.businessPhones || null,
	   //Custom Workspace ONE Access Schema required for the attributes sent below. Hard code internalUserType to 'Provisioned'
	   'urn:scim:schemas:extension:workspace:1.0': {
		  internalUserType: 'PROVISIONED' || null,
		  domain: domain || null,
		  userPrincipalName: user.userPrincipalName || null
	  	},
		'urn:scim:schemas:extension:enterprise:1.0': {
			department: user.department || null
		}
	}
	// Now create user
	superagent
		  .post(access_url + '/SAAS/jersey/manager/api/scim/Users')
		  .type('application/json')
		  .auth(accessBearer, { type: 'bearer'})
		  .send((createUserBody))
		  .end((err, res) => {
			if(err) {
  				logger.info(new Date().toUTCString());
				logger.info(err)
				resolve('error line 738')
			}
			console.log('Attempted Creation: ' + user.mail + ` (result: ${res.status})`)
  			synclog.info('Attempted Creation: ' + user.mail + ` (result: ${res.status})`)

			if (res.status < 200 || res.status > 299) {
				const response = {
					username: user.mail,
					statuscode: res.status,
					result: 'notadded'
				}
				let timedate = new Date().toISOString().
				  replace(/T/, ' ').      // replace T with a space
				  replace(/\..+/, '')     // delete the dot and everything after
				resolve (response)
			}
			else {
				const response = {
					username: user.mail,
					statuscode: res.status,
					access_id: res.body.id
				}
				//Get current date and time then regex to a useable format.
				let timedate = new Date().toISOString().
				  replace(/T/, ' ').      // replace T with a space
				  replace(/\..+/, '')     // delete the dot and everything after
				resolve (response);
			}
		},
		  );
		
	})
}

//---List all Access Users---//
function listAccessUsers() {
	if(access_url){
	return new Promise (resolve => {
	superagent
		.get(access_url + '/SAAS/jersey/manager/api/scim/Users')
		.auth(accessBearer, { type: 'bearer'})
		.query(`filter=Username co "${domain}"`)
      	.then(res => {
			const users = res.body;

			resolve(users);
      });
      
    });
}
}

//Create Directory in Access for Sync
function createDir(request) {
	return new Promise (resolve => {
	// Now create dir
	superagent
		  .post(access_url + '/SAAS/jersey/manager/api/connectormanagement/directoryconfigs')
		  .set('Content-Type', 'application/json')
		  .set('Content-Type','application/vnd.vmware.horizon.manager.connector.management.directory.other+json')
		  .auth(accessBearer, { type: 'bearer'})
		  .send((request))
		  .end((err, res) => {
			if(err) {
				resolve(err)
			}
			resolve('added directory')
		},
		  );
		
	})
}

function deleteDir(id) {
	return new Promise (resolve => {


	// Now delete dir
	superagent
		  .delete(access_url + '/SAAS/jersey/manager/api/connectormanagement/directoryconfigs/' + id)
		  .set('Content-Type', 'application/json')
		  .set('Content-Type','application/vnd.vmware.horizon.manager.connector.management.directory.other+json')
		  .auth(accessBearer, { type: 'bearer'})
		  .then(res => {
			const result = res.body;
			resolve(result);
      });
		
	})
}
//--Update User Attributes in Access--//
function updateUser(changedUser) {
	const schemas = [
		"urn:scim:schemas:core:1.0", "urn:scim:schemas:extension:workspace:tenant:sva:1.0", "urn:scim:schemas:extension:workspace:1.0", "urn:scim:schemas:extension:enterprise:1.0"
	  ]
	let aDept = ''
	if(changedUser.changes.department != undefined){
		aDept = changedUser.changes.department
	}
	
	const body = {
		schemas: schemas,
		name: {
			givenName: changedUser.changes.name.givenName || null,
			familyName: changedUser.changes.name.familyName || null
		},
		title: changedUser.changes.title,
		emails: changedUser.changes.emails,
		active: changedUser.changes.suspended,
		phoneNumbers: changedUser.changes.businessPhones,
		'urn:scim:schemas:extension:enterprise:1.0': {
			department: aDept || null
		}
	 }
	return new Promise (resolve => {
	// Now create user
	superagent
		  .patch(`${changedUser.userlocation}`)
		  .type('application/json')
		  .auth(accessBearer, { type: 'bearer'})
		  .send((body))
		  .end((err, res) => {
			if(err) {
				console.log("err")
  				logger.info(new Date().toUTCString());
				logger.info(err)
				resolve(err)
			}
			if (res.status < 200 || res.status > 299) {
				const response = {
					
					username: changedUser.changes.emails,
					statuscode: res.status
					
				}
				resolve (response)
				
			}
			else {
				const response = {
					
					username: changedUser.changes.primaryEmail,
					statuscode: res.status
					
				}
			resolve (response)
			} 
		},
		  );
		
	})
}

//---List all Access Groups---//
function getAllAccessGroups() {
	if(access_url){
	return new Promise (resolve => {
	
	superagent
		.get(access_url + '/SAAS/jersey/manager/api/scim/Groups')
		.auth(accessBearer, { type: 'bearer'})
      	.then(res => {
			const groups = res.body.Resources;
			resolve(groups);
      });
    });
}
}

//--Create Group in Access--//
function createGroup(groups) {
	const group = groups;
	return new Promise (resolve => {
	const schemas = [
	  "urn:scim:schemas:core:1.0", "urn:scim:schemas:extension:workspace:1.0", "urn:scim:schemas:extension:enterprise:1.0"
	]
	// Set body to be sent
	const createGroupBody = {
	   schemas: schemas,
	   displayName: group.displayName,
	   externalId: group.id,
	   //Custom Workspace ONE Access Schema required for the attributes sent below. Hard code internalGroupType to 'INTERNAL'
	   'urn:scim:schemas:extension:workspace:1.0': {
		  internalGroupType: 'INTERNAL' || null,
		  domain: domain || null
	  	}
	}
	// Now create group
	superagent
		  .post(access_url + '/SAAS/jersey/manager/api/scim/Groups')
		  .type('application/json')
		  .auth(accessBearer, { type: 'bearer'})
		  .send((createGroupBody))
		  .end((err, res) => {
			if(err) {
				console.log("Create Group Error.")
  				logger.info(new Date().toUTCString());
				logger.info(err)
				resolve(err)
			}
			if (res.status < 200 || res.status > 299) { //error catching
				const response = {
					name: group.displayName,
					statuscode: res.status,
					accessid: res.body.id,
					groupkey: group.id
				}
				resolve (response)
			}
			else {
				const response = {
					name: group.displayName,
					statuscode: res.status,
					accessid: res.body.id,
					groupkey: group.id
				}
				resolve (response)
			}
		},
		  );
		
	})
}

//--Convert Azure MemberID List to Access List--//
async function convertMembers(members) {
	console.log('Converting Azure Group Members (by username) to Access Group Members (by externalID')
	logger.info(new Date().toUTCString());
	const membersArray = async function() {
		var promises = [];
		for (let i = 0; i < members.length; i++) {
		


			const res = await getAccessUserId(members[i]);
			if(res.length == []) {
				console.log(`User doesn't exist. Needs to be created.`)
				if(members[i].email) {
					
				const gUser = await listUser(members[i].email)
				const aUser = await createUser(gUser)
				const val = {
					value: aUser.access_id
				}
				promises.push( val )
			}
		else {console.log(`User doesnt have email`)}
			}
			else {
			const val = {
				value: res[0].id
			}
			promises.push( val )
		}
		console.log('Processed ' + promises.length + ' members...\n');
		synclog.info('Processed ' + promises.length + ' members...\n')
		}
		return Promise.all(promises)
	}
	const memlist = await membersArray();
	return new Promise (resolve => {
	resolve(memlist)
	})
}

//--Add Azure Group members to Access Group--//
function addMembers(group, memlist) {
	console.log(`Adding ${memlist.length} users to ${group.name}`)
	synclog.info(`Adding ${memlist.length} users to ${group.name}`)
	synclog.info(`DONE`)

	




	return new Promise (resolve => {
	const body = {

		members: memlist
	}


	superagent
		.patch(access_url + `/SAAS/jersey/manager/api/scim/Groups/${group.accessid}`)
		.auth(accessBearer, { type: 'bearer'})
		.send((body))
      	.then(res => {

			console.log(chalk`Syncing ${group.name} {greenBright.bold DONE}`)

			resolve(res);
      });
      
    });
	
}

//--Update Access Group Details--//
function updateGroup(group) {
	console.log(`Modifying group to ${group.changes.name}`)
	logger.info(new Date().toUTCString());

	logger.info(`Modifying group to ${group.changes.name}`)

	return new Promise (resolve => {
	const body = {

		displayName: group.changes.name
	}


	superagent
		.patch(access_url + `/SAAS/jersey/manager/api/scim/Groups/${group.access_id}`)
		.auth(accessBearer, { type: 'bearer'})
		.send((body))
      	.then(res => {
			 
  logger.info(new Date().toUTCString());

			 logger.info(res.body)

			  resolve(res.body)
      });
      
    });
}

//---Get Access User by Username (username in Access == mail in AAD)---//
//changed for Azure to for user == just the email address
function getAccessUser(users) {
	const user = users;
	return new Promise (resolve => {
	superagent
		.get(access_url + '/SAAS/jersey/manager/api/scim/Users')
		.auth(accessBearer, { type: 'bearer'})
		.query(`filter=Username eq "${user}"`)
      	.then(res => {
			const rtn = res.body.Resources[0]

			resolve(rtn);
      });
      
    });
}

//---Get Access User ID by email address---//
function getAccessUserId(members) {
	return new Promise (resolve => {
	superagent
		.get(access_url + '/SAAS/jersey/manager/api/scim/Users')
		.auth(accessBearer, { type: 'bearer'})
		.query(`filter=Username co "${members.mail}"`)
      	.then(res => {
			const rtn = res.body.Resources
			resolve(rtn);
      });
      
    });
}

//---Get Access Group by externalId ---//
function getAccessGroup(groups) {
	const group = groups;
	return new Promise (resolve => {
	superagent
		.get(access_url + '/SAAS/jersey/manager/api/scim/Groups')
		.auth(accessBearer, { type: 'bearer'})
		.query(`filter=externalId co "${group.id}"`)
      	.then(res => {
			  
			const rtn = res.body.Resources
			resolve(rtn);
      });
      
    });
}

//--Add Users to Access according to Partial Sync Users list from Rollcall--//
async function syncPartialUserList(userNameArray) {
	console.log(chalk`Processing {blueBright.bold Partial User Sync}`)
	synclog.info(new Date().toUTCString());


	synclog.info(`Processing Partial User Sync`)
	
	const usersArray = async function() {
		var promises = [];
		for (let i = 0; i < userNameArray.length; i++) {
			const user = await getAccessUser(userNameArray[i]);		
			function createCheck() { return new Promise (resolve => {
				if(user == undefined){
					console.log(userNameArray[i] + 'Needs to be created')
				resolve(true)
				}
				else {
				resolve(false)
				}
			})
			}
		const create = await createCheck()
		if (create) {
		console.log(userNameArray[i] + 'Needs to be created')
		
		const azureUserData = await getAzureUser(userNameArray[i]);
	
		const res = createUser(azureUserData);
		console.log('Added ' + azureUserData.mail)
		synclog.info(new Date().toUTCString());

		synclog.info('Added ' + azureUserData.mail)

		promises.push( await res )
		console.log('Processed ' + promises.length + ' users...\n');
		synclog.info(new Date().toUTCString());

		synclog.info('Processed ' + promises.length + ' users...\n');

		}
		if (!create) {
			console.log(userNameArray[i] + ' already exists.')
			const azureUser = await getAzureUser(userNameArray[i]);
			let accessUser = user
			console.log('Checking for user attribute changes.')
			const changedUser = await diffUsers(azureUser, accessUser);
			if (changedUser) {
				console.log('Making changes to user.')
				 const result = await updateUser(changedUser)
				 const response = {
					
					username: user.mail,
					statuscode: 204
					
				}
				promises.push( response )
			}
			else {
			const response = {
					
				username: user.mail,
				statuscode: 200
				
			}
			promises.push( response )
		}
		}
		}
		return Promise.all(promises)
	}
	const result = await usersArray() 
	var errcount = 0;
	var createcount = 0;
	var modcount = 0;
	for (let i = 0; i < result.length; i++) {
		const res = result[i];
		if (res.statuscode == 201) {
			createcount++;
		   }
		if (res.statuscode == 204) {
			modcount++;
		   }
		if (res.statuscode == 409)  {
			 errcount++;
		   }
		
	}


	const res = {
	
		result: {
			processed: result.length,
			skipped: errcount,
			created: createcount,
			modified: modcount

		}
	}
	return res
}

//List Access Directories
function getAccessDirs() {

	if(access_url && accessBearer){
	return new Promise (resolve => {
	superagent
		.get(access_url + '/SAAS/jersey/manager/api/connectormanagement/directoryconfigs')
		.auth(accessBearer, { type: 'bearer'})
      	.then(res => {
			const dirs = res.body;
			resolve(dirs);
      });
      
    });
}
}

//Save OAuth Credentials
async function saveCredentials(request) {
	let type = access;
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		
		console.log(chalk.blueBright("Updated OAuth Credentials."))
		
		resolve('done')
      
    });
}

//Save Sync Schedule Settings
function saveSyncSchedule(request) {
	let type = sync;
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		
		console.log(chalk.blueBright("Updated Sync Schedule."))
		
		resolve('done')
      
    });
}

//Save Group Sync Values
function saveSyncGroups(request) {
	let type = group;
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		
		console.log(chalk.blueBright("Updated Sync Groups."))
		
		resolve(group)
    });
}

//Delete sync schedule from database
function clearSyncConfig() {
	let type = clearSync;
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		
		console.log(chalk.blueBright("Cleared Sync Schedule."))
		
		resolve('done')
      
    });
}

//Delete tenant info from database
async function clearTenantConfig() {
	let type = clearTenant;
	return new Promise (resolve => {
		writeConfig(request, type);
		getSecrets();
		console.log(chalk.blueBright("Cleared Tenant Info."))
		console.log(chalk.yellowBright("Deleting Bearer Token"))
		accessBearer = ''
		resolve('done')  
    });
}

function clearGroupConfig() {
	let type = clearGroup;
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		
		console.log(chalk.blueBright("Cleared Group Sync Info."))
		
		resolve('done')
      
    });
}

//Get schedule settings
async function getSchedule() {

	return new Promise(resolve => {
			
			const response = {
				synctype: sync.synctype, 
				syncvalues: sync.syncvalues,
				frequency: sync.frequency,
				day: sync.day,
				time: sync.time,
				numberTime: sync.time
				}
			resolve (response);

		
})
}

//Get Group Sync values
async function getGroupSyncSettings() {
	return new Promise(resolve => {
		
		const response = {
			synctype: group.synctype, 
			syncvalues: group.syncvalues,
			frequency: group.frequency,
			day: group.day,
			time: group.time,
			numberTime: group.time
		}
		resolve(response)
	
	})
}

//Parse the "partial group" list values
function parseGroupIDArray() {
	return new Promise(resolve => {	
		let groupIDArray;
		groupIDArray = group.syncvalues.split(',');
		resolve(groupIDArray);
	})
}


//######################################################################################################
//
// Workspace ONE Access Auth
//
//######################################################################################################

//---Send Request to get Bearer Token from Access---//

let accessBearer;
let access_url;
let client_id;
let client_secret;
let domain;

//Get OAuth credentials from config file
function getSecrets() {
	return new Promise(resolve => {

		 access_url = access.URL;
		 client_id = access.CLIENT_ID;
		 client_secret = access.CLIENT_SECRET;
		 domain = access.DOMAIN;

		const response = {
			url: access.URL,
			client_id: access.CLIENT_ID,
			client_secret: access.CLIENT_SECRET,
			domain : access.DOMAIN
		}



		resolve(response);
	})	
}

//Request OAuth bearer token from Access
function getBearer() {

  	const queryArguments = {
    grant_type: 'client_credentials',
	client_id: client_id,
    client_secret: client_secret,
  }
  const headers = {
    'Content-Type': 'application/x-www-form-urlencoded'
  }
  return new Promise(resolve => {
	superagent
	.post(access_url + '/SAAS/auth/oauthtoken')
	.query(queryArguments)
	.set(headers)
	.then(res => {
			if(res.body){
			accessBearer = res.body.access_token
			resolve('Bearer Token obtained from Access')
			}
		})
	.catch(err => {
		logger.info(new Date().toUTCString());
		logger.info(err)
		resolve('no data')})

	});
};

let astatus

//---Get Access OAuth Endpoint to get Bearer---//
async function callOauthEndpoint() {
	const creds = await getSecrets();
	if (creds == 'no data') {
		console.log(chalk`{red.bold No Access Tenant information has been provided.} Have you run setup using Rollcall UI?`)
		astatus = null;
		return false
	}
	const b = await getBearer();
	if(b != "no data") {
		astatus = true
		console.log('====================================================================')
		console.log(chalk`{green.bold Successfully obtained OAuth Token from Workspace ONE Access}`)
		console.log('====================================================================')
		logger.info(new Date().toUTCString());
		logger.info('Successfully obtained OAuth Token from Workspace ONE Access.')

	}
	else {
		console.log('====================================================================')
		console.log(chalk`{red.bold Unable to obtain OAuth Token from Workspace ONE Access \n}`)
			astatus = null
			if (access.URL) {
			console.log(chalk`{red.bold Access Tenant information exists, check credentials or url.}\n`)
			const data = true
			return data
			}
			else {
			console.log(chalk`{red.bold No Access Tenant information has been provided.} Have you run setup?`)
			const data = false
			return data
			}
	}
};

callOauthEndpoint();

//==========================================================
// Parse and Schedule Sync settings
//==========================================================

//Function that runs Sync Functions according to settings.
async function runSync(group) {
	console.log(chalk `Scheduled Sync Starting... {greenBright.bold SUCCESS }`)	
		if (group == 'groupall') {

			await processAllGroupSync();
		}
		if (group == 'grouppartial') {
		
			processSequenceSync();
		}
		if (!group ) {
		console.log('no groups.')
		}
}

//Function to put all Config and Settings together and decides what to schedule.
async function doAll() {
	const prom = async function() {
		const sched = await getSchedule()
		//const user = await getUserSyncSettings()
		const group = await getGroupSyncSettings() 
		if(sched.length) {
			
				let hUser
				let hGroup
				let hFrequency
				if (group[0].synctype == 'groupall'){hGroup = `All Groups`}
				if (group[0].synctype == 'grouppartial'){hGroup = `Selected Groups`}
				if (!group[0].synctype){hGroup = `No groups`}
				if (sched[0].frequency == 'hour'){hFrequency = `Hourly (on the hour)`}
				if (sched[0].frequency == 'day'){hFrequency = `Daily at ${sched[0].time}`}
				if (sched[0].frequency == 'week'){hFrequency = `Weekly on ${sched[0].day} at ${sched[0].time}`}
		
				const buildSched = {
					grouptype: group[0].synctype,
					groupvalues: group[0].syncvalues,
					synctype: sched[0].frequency,
					day: sched[0].day,
					time: sched[0].time,
					hourNumber: sched[0].hourNumber,
					hGroup: hGroup,
					hFrequency: hFrequency
				}

				return (buildSched)
			}
	
			else {
			let noSched = []
			return noSched
			}
		}
		const parsedVals = await prom()
		const doSched = async function(){

			
			if (parsedVals.synctype == 'hour') {
				
			let rule = new schedule.RecurrenceRule()
			rule.minute = 0

				schedule.scheduleJob(rule, async function() { runSync(parsedVals.grouptype) }
			//	schedule.scheduleJob('0 0 0/1 1/1 * ? *', async function() { runSync(parsedVals.grouptype) }
				);

				return 'ok'
			}
			if (parsedVals.synctype == 'day') {

				let rule = new schedule.RecurrenceRule()
				rule.hour = parsedVals.hourNumber

				schedule.scheduleJob(rule, function(){
					runSync(parsedVals.grouptype)
				});	
				return 'ok'
			}
			if (parsedVals.synctype == 'week') {
				let dayNumber
				if(parsedVals.day == 'Sunday'){dayNumber = 0}
				if(parsedVals.day == 'Monday'){dayNumber = 1}
				if(parsedVals.day == 'Tuesday'){dayNumber = 2}
				if(parsedVals.day == 'Wednesday'){dayNumber = 3}
				if(parsedVals.day == 'Thursday'){dayNumber = 4}
				if(parsedVals.day == 'Friday'){dayNumber = 5}
				if(parsedVals.day == 'Saturday'){dayNumber = 6}

				let rule = new schedule.RecurrenceRule()
				rule.hour = parsedVals.hourNumber
				rule.dayOfWeek = dayNumber
				schedule.scheduleJob(rule, function(){
					runSync(parsedVals.usertype, parsedVals.grouptype)
				});
				return 'ok'
			}
			else {return 'notok'}
		}
	const result = await doSched() 
	if (result == 'ok') {
		
		const prettySchedule = chalk`Rollcall Access-Sync Scheduled {whiteBright.bold ${parsedVals.hFrequency}}`
			console.log( prettySchedule )
			return 'scheduledone'
	}
	else {
	return parsedVals
	}
}

async function forceSync() {

	const prom = async function() {
		const sched = await getSchedule()
		const group = await getGroupSyncSettings() 

		if(sched) {
				console.log('Valid Schedule')
				let hFrequency
				if (sched.frequency == 'hour'){hFrequency = `Hourly (on the hour)`}
				if (sched.frequency == 'day'){hFrequency = `Daily at ${sched.time}`}
				if (sched.frequency == 'week'){hFrequency = `Weekly on ${sched.day} at ${sched.time}`}
		
				const buildSched = {
			

					grouptype: group.synctype,
					groupvalues: group.syncvalues,
					synctype: sched.frequency,
					day: sched.day,
					time: sched.time,
					hourNumber: sched.hourNumber,
					hFrequency: hFrequency
				}
				
  				logger.info(new Date().toUTCString());

				logger.info(buildSched)
				return (buildSched)
			}
	
			else {
			let noSched = []
			
			return noSched
			}
		}
		const parsedVals = await prom()
		const doSched = async function(){
			if (parsedVals.synctype) {	
				console.log('Valid Synctype. Running Sync')

				runSync(parsedVals.grouptype) 
				return 'ok'
			}
			else {return 'notok'}
		}
	const result = await doSched() 
	if (result == 'ok') {
		
		return 'ok'
	}
	else {
	
	return 'notok'
	}
}

//######################################################################################################
//
// Azure Authentication and Functions
//
//######################################################################################################

let aadStatus;

async function getGraphStatus() {
	const authResponse = await auth.getToken(auth.tokenRequest);
	let status = await fetch.graphStatus(auth.graphAPI.uri, authResponse.accessToken);
	return new Promise(resolve => {
            try {
               
				aadStatus = true;
				resolve (status);
            } catch (error) {

                console.log(error);
				resolve(error);
            }
		})
};

async function getAzureUsers() {
	const authResponse = await auth.getToken(auth.tokenRequest);
	const users = await fetch.callApi(auth.userAPI.uri, authResponse.accessToken);
	return new Promise(resolve => {
            try {
				
				resolve (users);
            } catch (error) {
                console.log(error);
				resolve(error);
            }
		})
};

async function getAzureGroups() {
	const authResponse = await auth.getToken(auth.tokenRequest);
	const groups = await fetch.callApi(auth.groupAPI.uri, authResponse.accessToken);
	return new Promise(resolve => {
            try {
				resolve (groups);
            } catch (error) {

                console.log(error);
				resolve(error);
            }
		})
};

async function getAzureGroupByID(groupID) {
	const authResponse = await auth.getToken(auth.tokenRequest);
	const group = await fetch.getGroup(groupID, authResponse.accessToken);
	return new Promise(resolve => {
            try {
				resolve (group);
            } catch (error) {
                console.log(error);
				resolve(error);
            }
		})
};

async function getAzureGroupMembers(groupID) {
	const authResponse = await auth.getToken(auth.tokenRequest);
	const group = await fetch.getGroupMembers(groupID, authResponse.accessToken);
	return new Promise(resolve => {
            try {
				resolve (group);
            } catch (error) {
                console.log(error);
				resolve(error);
            }
		})
};

async function getAzureUser(mail) {
	const authResponse = await auth.getToken(auth.tokenRequest);
	const user = await fetch.getUser(mail, authResponse.accessToken);
	return new Promise(resolve => {
            try {
				resolve (user);
            } catch (error) {
                console.log('error');
				resolve(error);
            }
		})
};

async function processSequenceSync() {
	console.log(chalk`Processing {cyanBright.bold Partial Group Sync}`)
	
	//Step One: Get Group Object Info to sync.
	//Gets the ids of the Groups from the Database that have been set to be synced.
	const ids = await parseGroupIDArray()

	//This takes the Group IDs Array and looks up the Group Information from Azure
	const prom = async function() {
		let promises = []
				for (let i = 0; i < ids.length; i++) {
				
					async function getGroup() { return new Promise (resolve => {
					
						getAzureGroupByID(ids[i]).then(data =>{
							console.log(data["id"])
							resolve (data)})
					})
					}
					const group = await getGroup()
					promises.push(await group)
					console.log('Processed ' + promises.length + ' groups...\n');
				}
			return Promise.all(promises)
		}
	//We now have the details of each Group that has been selected for Sync.
	const groups = await prom()
	
	//Step Two: Do the Sync or Creation of the Group, and then also get the members of the group.
	const prom2 = async function() {
		console.log(chalk`{cyan.bold Getting Group details and members.}`)
		var promises = [];
		var groupResults = [];
		let create;
		for (let i = 0; i < groups.length; i++) {
			async function createCheck() { return new Promise (resolve => {

				
					
				const res = getAccessGroup(groups[i]);


				
				
				// console.log('newres')
				// console.log(res)
				

				resolve(res);
					})
				}
			//Checks for each Group by ID to see if its been added to DB and therefore exists in Access.	
		const check = await createCheck()
		if(check[0]) {
			console.log(groups[i].displayName + ` (id/externalId: ${groups[i].id})` + ' previously created, skipping creation. \n')
			//resolving false means it doesn't need to be created (create = false)
			create = false;
			}
		else {
			//group doesn't exist in Access
			create = true;
			}
		//CREATE TRUE - Needs to be created
		if (create) {
			console.log('Need to create group.')
			//Create the Group in Access first.
			await createGroup(groups[i]); 
			console.log('Added ' + groups[i].displayName)
			//Get the members of the Group from Azure.
			const members = await getAzureGroupMembers(groups[i].id);
			let memberEmail = []
			//Add ONLY the member's email address to an array and return it.
			if(members !== undefined){
				for (let i = 0; i < members.length; i++) {		
					memberEmail.push(members[i].mail)
				}
			promises.push( memberEmail )
			}
		}
		//CREATE FALSE - Group doesn't need to be created.
		if (!create) {
			console.log('Group already exists.')
			//Get the members of the Group from Azure.
			const members = await getAzureGroupMembers(groups[i].id);	
			let memberEmail = []
			//Add ONLY the member's email address to an array and return it.
			if(members !== undefined){
				for (let i = 0; i < members.length; i++) {
					memberEmail.push(members[i].mail)
				}
			}
			//Now lookup the Group in Access to get current details.
			const accessGroup = await getAccessGroup(groups[i]);
			const group = groups[i]
			//Compare the group attributes between whats currently in Access and then what is in Azure.
			const changedGroup = await diffGroup(group, accessGroup);
			//If there are any changes, a value for changedGroup will be returned.
				if (changedGroup) {
					const res = await updateGroup(changedGroup)
					
				}
			promises.push( memberEmail )
			}
			}
			return Promise.all(promises)
		}
		//This gets a LIST of the emails.
	
		const emails = await prom2()
		//We need to convert the above LIST into a useable Array.
		let emailArray = []
		for (let i = 0; i < emails.length; i++) {
			const vals = emails[i].values()
			for (const value of vals){
				emailArray.push(value)
			}
		}

// 		let userResult = await syncPartialUserList(userEmails);
		let userResult = await syncPartialUserList(emailArray);



		//All users added to Access, now need to do memberships
	
		const prom3 = async function() {
		console.log(chalk`{cyan.bold Comparing and updating Group Memberships.}`)
			var promises = [];
			for (let i = 0; i < groups.length; i++) {
				const accessGroup = await getAccessGroup(groups[i]);
				const group = groups[i]
				const groupKey = {
					groupkey: groups[i].id
				}
				const members = await getAzureGroupMembers(groups[i].id);

				const convertedMembers = await convertMembers(members);
				//const convertedMembers = await members;
			
	
				const addDetails = {
					name: groups[i].displayName,
					accessid: accessGroup[0].id
				}
				const res = addMembers(addDetails, convertedMembers);
				promises.push( await res )
				}
			
			return Promise.all(promises)
			}
	
		const membershipresult = await prom3()

		var groupcreatecount = 0
		var groupmodcount = 0
		var grouperrcount = 0
	
		for (let i = 0; i < membershipresult.length; i++) {
			const res = membershipresult[i];
			if (res.statuscode == 201) {
				groupcreatecount++;
			   }
			if (res.statuscode == 204) {
				groupmodcount++;
			   }
			if (res.statuscode == 409)  {
				 grouperrcount++;
			   }
			
		}
		const result = {
			groups: {
				processed: membershipresult.length,
				created: groupcreatecount,
				modified: groupmodcount,
				errors: grouperrcount
			},
			users: userResult.result
		}
		return result
};


//######################################################################################################
//
// Google Authentication and Functions
//
//######################################################################################################

const SCOPES = ['https://www.googleapis.com/auth/admin.directory.user', 'https://www.googleapis.com/auth/admin.directory.group', 'https://www.googleapis.com/auth/admin.directory.orgunit'];
const TOKEN_PATH = './config/token.json'
const CREDENTIALS_PATH = './config/credentials.json'


let creds;

fs.readFile(CREDENTIALS_PATH, (err, content) => {
  if (err) return console.error('Error loading client secret file', err);
  creds = JSON.parse(content);
  authorize(JSON.parse(content), checkApi);
});


/**
 * @param {Object} credentials The authorization client credentials.
 * @param {function} callback The callback to call with the authorized client.
 */
async function authorize(credentials, callback) {
  const {client_secret, client_id, redirect_uris} = credentials.installed;
  const oauth2Client = new google.auth.OAuth2(
      client_id, client_secret, redirect_uris[0]);
  // Check if we have previously stored a token.
  fs.readFile(TOKEN_PATH, (err, token) => {
    if (err) return getNewToken(oauth2Client, callback);
	oauth2Client.credentials = JSON.parse(token);
	OAuth2Client = oauth2Client;
	callback(oauth2Client);
  });
}

/**
 * @param {google.auth.OAuth2} oauth2Client The OAuth2 client to get token for.
 * @param {getEventsCallback} callback The callback to call with the authorized client.
 */
function getNewToken(oauth2Client, callback) {
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
  });
  tokenurl = authUrl
  console.log('====================================================================')
  console.log(chalk`{yellowBright.bold Authorise Rollcall to use your Google credentials by visiting this url:\n}`, authUrl);
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  console.log('====================================================================')
  rl.question(chalk`{yellowBright.bold Enter the code from that page here:} `, (code) => {
	console.log('====================================================================')
    rl.close();
    oauth2Client.getToken(code, (err, token) => {
      if (err) return console.error('Error retrieving access token', err);
      oauth2Client.credentials = token;
	  storeToken(token);
      callback(oauth2Client);
      //res.end();
    });
  });
}

/**
 * @param {Object} token The token to store to disk.
 */
function storeToken(token) {
  fs.writeFile(TOKEN_PATH, JSON.stringify(token), (err) => {
    if (err) return console.warn(`Token not stored to ${TOKEN_PATH}`, err);
    console.log(`Token stored to ${TOKEN_PATH}`);
	logger.info(new Date().toUTCString());

    logger.info(`Token stored to ${TOKEN_PATH}`);

  });
}
let gstatus
/**
 * @param {google.auth.OAuth2} auth An authorized OAuth2 client.
 * 
 */
//changed below to only list a single user as we are now calling it in the other script

function checkApi(auth) {
  const service = google.admin({version: 'directory_v1', auth}); 
  
  service.users.list({
    customer: 'my_customer',
    maxResults: 1,
    orderBy: 'email',
   
  }, (err, res) => {
    if (err) return console.error('The API returned an error:', err.message);
	const users = res.data.users;
	gstatus = true
    if (users.length) {
	  console.log('====================================================================')
      console.log(chalk.greenBright('Successfully queried Google Directory.'));
	  logger.info(new Date().toUTCString());
	  logger.info('Successfully queried Google Directory.')
	  gauth = auth;
    } else {
      console.log('No users found.');
    }
  });
}

//---Users---//

//List a Single User
function listGoogleUser(user) {
	// when updating user, it seems to be sending ONLY the email address as user. Creating users sends as sub-attribute.
		return new Promise (resolve => {
			const headers = {
				'Content-Type': 'application/json',
				'Authorization': `Bearer ` + OAuth2Client.credentials.access_token
		}
		superagent
			//see line 393!!!
			.get('https://admin.googleapis.com/admin/directory/v1/users/' + user)
			.set(headers)
			  .then(res => {
				const users = res.body;
			
				resolve(users);
		  });
		  
		});
	}
	
//List All Google Directory Users
function listAllGoogleUsers(users = [], pageToken) {
		return new Promise (resolve => {
			const headers = {
				'Content-Type': 'application/json',
				'Authorization': `Bearer ` + OAuth2Client.credentials.access_token
		}
		superagent
			.get('https://admin.googleapis.com/admin/directory/v1/users')
			.set(headers)
			.query({ customer: 'my_customer',
			pageToken: pageToken	
			})
			  .then(res => {
				users = users.concat(res.body.users);
				console.log('Found ' + users.length + ' users...\n');
	  logger.info(new Date().toUTCString());
	
				logger.info('Found ' + users.length + ' users...\n');
	
				if (res.body.nextPageToken) {
					listAllUsers(users, res.body.nextPageToken).then((resusers) => {
					resolve(resusers);
					});
				} else {
					resolve(users);
				}
			});
		  });
		  
	}
	
//Compare Google User attributes with current Access User attributes
async function diffGoogleUsers(user, accessUser) {
		const guser = user;
		const auser = accessUser[0];
		
		var isSuspendedStr = guser.suspended
		var isActiveInvertedStr = !auser.active
		const getPhone = async function() {
			return new Promise (resolve => {
				for (var i = 0; i < guser.phones.length; i++) {
					var res;
					if (guser.phones[i]['type'] == 'work') {
					  res = guser.phones[i]['value'];
					}
					
					resolve(res)
				  }
			});
		}
		const gWorkPhone = await getPhone();
		
		const googleUserData = {
			name: {
				givenName: guser.name.givenName || null,
				familyName: guser.name.familyName || null
			},
			emails: guser.primaryEmail,
			suspended: isSuspendedStr,
			title: guser.organizations[0].title || null,
			department: guser.organizations[0].department || null,
			manager: guser.relations[0].value || null,
			phone: gWorkPhone || null
			
		 }
		 
		 // Note: Google uses "suspended" and Access uses "active" for user accounts. Below for access just inverts the response for comparison.
		 const accessUserData = {
			name: {
				givenName: auser.name.givenName || null,
				familyName: auser.name.familyName || null
			},
			emails: auser.emails[0].value,
			suspended: isActiveInvertedStr,
			title: auser.title || null,
			department: auser['urn:scim:schemas:extension:enterprise:1.0'].department || null,
			manager: auser['urn:scim:schemas:extension:enterprise:1.0'].manager.managerId || null,
			phone: gWorkPhone || null
		 }
		 
		
	
		return new Promise (resolve => {
			var diffs = jsondiffpatch.diff(accessUserData, googleUserData)
			if (diffs) {
				let changes = jsondiffpatch.patch(googleUserData, diffs)
				console.log("User Changes: ")
				const newBody = {
					changes,
					userlocation: auser.meta.location
				}
																									   
				resolve(newBody);
			}
			else {
				console.log("No User Attribute Updates Required.")
				resolve('')
			} 
		  });
}

//---Groups---//
function listAllGoogleGroups(groups = [], pageToken) {
		return new Promise (resolve => {
			const headers = {
				'Content-Type': 'application/json',
				'Authorization': `Bearer ` + OAuth2Client.credentials.access_token
		}
		superagent
			.get('https://admin.googleapis.com/admin/directory/v1/groups')
			.set(headers)
			.query({ customer: 'my_customer',
			pageToken: pageToken	
			})
			.then(res => {
				groups = groups.concat(res.body.groups);
				console.log('Found ' + groups.length + ' groups...\n');
	  logger.info(new Date().toUTCString());
	
				logger.info('Found ' + groups.length + ' groups...\n');
	
				if (res.body.nextPageToken) {
					listAllGroups(groups, res.body.nextPageToken).then((resgroups) => {
					resolve(resgroups);
					});
				} else {
					resolve(groups);
				}
			});
		  
		});
}

//---GET Group Members---//
function getGoogleMembers(id, pageToken) {
		return new Promise (resolve => {
			const headers = {
				'Content-Type': 'application/json',
				'Authorization': `Bearer ` + OAuth2Client.credentials.access_token
		}
		superagent
			.get('https://admin.googleapis.com/admin/directory/v1/groups/' + id.groupkey + '/members')
			.set(headers)
			.query({
			pageToken: pageToken	
			})
			.then(res => {
				let members = []
				if(!res.body.members){
					members.push('none')
					resolve(members)
				}
				members = members.concat(res.body.members);
		
				console.log('Found ' + members.length +  ` members in ${id.groupkey}\n`);
	  logger.info(new Date().toUTCString());
	
				logger.info('Found ' + members.length +  ` members in ${id.groupkey}\n`);
	
				if (res.body.nextPageToken) {
					getMembers(id, res.body.nextPageToken).then((memberResult) => {
					resolve(memberResult);
					});
				} else {
					resolve(members);
				}
			});
		  
		});
}
	
//---GET Group by Id---//
function getGoogleGroupById(id) {
		return new Promise (resolve => {
			const headers = {
				'Content-Type': 'application/json',
				'Authorization': `Bearer ` + OAuth2Client.credentials.access_token
			}
		superagent
			.get('https://admin.googleapis.com/admin/directory/v1/groups/' + id)
			.set(headers)
			.then(res => {
	
					resolve(res.body);
				})
	})
		  
}
	
//Compare Google Group attributes with current Access Group attributes
function diffGoogleGroup(group, accessGroup) {
		const ggroup = group;
		const agroup = accessGroup[0];
		const googleGroupData = {
			name: ggroup.name || null,
		 }
		 const accessGroupData = {
			name:  agroup.displayName || null,
		 }
		return new Promise (resolve => {
			var diffs = jsondiffpatch.diff(accessGroupData, googleGroupData)
			if (diffs) {
				let changes = jsondiffpatch.patch(googleGroupData, diffs)
				console.log("Changes: \n" + `${agroup.displayName} will be renamed to ${changes.name}. \n` )
	  
	  synclog.info("Changes: \n" + `${agroup.displayName} will be renamed to ${changes.name}. \n` )
				const newBody = {
					changes,
					access_id: agroup.id,
					grouplocation: agroup.meta.location
				}                                                                                                
				resolve(newBody);
			}
			else {
				console.log('No Group Attribute Updates Required. \n')
				resolve('')
			} 
		  });
}


//Run at Startup
doAll();

if(mode == "azure"){
getGraphStatus();
};


