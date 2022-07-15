//-- 	Setting Configuration 	--//
const config = require('config');
const fs = require('fs');
let groupList;


const SCOPES = ['https://www.googleapis.com/auth/admin.directory.user', 'https://www.googleapis.com/auth/admin.directory.group', 'https://www.googleapis.com/auth/admin.directory.orgunit'];
const TOKEN_PATH = './config/token.json'
const CREDENTIALS_PATH = './config/credentials.json'

async function writeConfig(data, type) {
	return new Promise (resolve => {
	var configFile = fs.readFileSync("./config/default.json");
	var configJSON = JSON.parse(configFile)
	
		if(type == 'azure'){
		}
		if(type == 'access'){
		configJSON.access.URL = data.url
		configJSON.access.CLIENT_ID = data.client_id
		configJSON.access.CLIENT_SECRET = data.client_secret
		configJSON.access.DOMAIN = data.domain
		var configContent = JSON.stringify(configJSON);
		}

		if(type == 'sync'){
		configJSON.sync.synctype = data.synctype
		configJSON.sync.syncvalues = data.syncvalues
		configJSON.sync.frequency = data.frequency
		configJSON.sync.day = data.day
		configJSON.sync.time = data.time
		var configContent = JSON.stringify(configJSON);
		}

		if(type == 'group'){
		configJSON.group.synctype = 'grouppartial'
		// configJSON.group.syncvalues = data.syncvalues
		// configJSON.group.frequency = data.frequency
		// configJSON.group.day = data.day
		// configJSON.group.time = data.time
		var configContent = JSON.stringify(configJSON);

		let groups = data.syncvalues;
		let grpArr = groups.replace(/^\[|\]$/g, "").split(", ");
		console.log('grpArr')
		console.log(grpArr)
		console.log('grpArr.length')
		console.log(grpArr.length)

		//let groups = JSON.parse(groupStrings)
		for (let i = 0; i < grpArr.length; i++) {
			if (groupList.indexOf(grpArr[i]) === -1) {
				groupList.push(grpArr[i])
			  }			
		}
		writeGroupFile();
		}

		if(type == 'clearGroup'){
			configJSON.group.synctype = ''
			configJSON.group.syncvalues = ''
			configJSON.group.frequency = ''
			configJSON.group.day = ''
			configJSON.group.time = ''
			groupList = []
			writeGroupFile();
			var configContent = JSON.stringify(configJSON);
			}
		
			if(type == 'clearSync'){
				configJSON.sync.synctype = ''
				configJSON.sync.syncvalues = ''
				configJSON.sync.frequency = ''
				configJSON.sync.day = ''
				configJSON.sync.time = ''
				var configContent = JSON.stringify(configJSON);
				}
				if(type == 'clearTenant'){
					configJSON.access.URL = ''
					configJSON.access.CLIENT_ID = ''
					configJSON.access.CLIENT_SECRET = ''
					configJSON.access.DOMAIN = ''
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

async function writeGroupFile() {
	
	var jsonContent = JSON.stringify(groupList)
	fs.writeFile("groups.json", jsonContent, 'utf8', function (err) {
		if (err) {
			console.log("An error occured while writing JSON Object to File.");
			return console.log(err);
		}
	})
};
	
async function readGroupFile(){
		return new Promise (resolve => {
		var groupFile = fs.readFileSync("groups.json");
		var configJSON = JSON.parse(groupFile)
		groupList = configJSON;
		console.log(groupList);
	}
)};

function sleep(ms) {
	return new Promise((resolve) => {
	  setTimeout(resolve, ms);
	});
  }




//--							--//

const Koa = require('koa')
const cors = require('@koa/cors');
const Router = require('koa-router')
const bodyParser = require('koa-bodyparser')
const mount = require('koa-mount');
const basicAuth = require('koa-basic-auth');
const {google} = require('googleapis');
const schedule = require('node-schedule');

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

const api_cred_user = config.rollcall.apiUser;
const api_cred_pass = config.rollcall.apiPassword;


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
//console.log(api_cred_pass)
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
const { Console } = require('console');
const { inspect } = require('util');

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
    chalk`{white \nMode: ${config.mode} }`+
    chalk`{white \n====================================================================}`
	
    
        )
});
logger.info(new Date().toUTCString());

logger.info(`Rollcall Server API is listening on http://localhost:${PORT}}`)
//==================================================================================================================






//==========================================================
// Inbound Request API paths
//==========================================================

//OAuth Route
router.get('/oauth', async function (ctx, next) {	
	let code = (ctx.query.code);
 
	ctx.set('Access-Control-Allow-Origin', '*')
  //console.log(code)
	ctx.body = code
});

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
	console.log('Google Users Found: ' + result.length + '\n');
	logger.info(new Date().toUTCString());

	logger.info('Google Users Found: ' + result.length + '\n');
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
		google: `${gstatus}`,
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
	//console.log(request);
	let result = await saveSyncGroups(request)
	ctx.body = result
	});

//Clear Sync Schedule Config
router.post('/cleargroupconfig', async function (ctx) {

	
	let result = await clearGroupConfig()
	await config.get('group');
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

//==========================================================
// Access SCIM API functions
//==========================================================

//--Create User in Access--//
function createUserfromAzure(users) {
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

function createUserfromGoogle(users) {
	const user = users;
	if((user.primaryEmail.includes(config.access.DOMAIN)) == false){
	console.log('Skipping User - Email Address Not In Domain')
	return 'notindomain'
}
	return new Promise (resolve => {
	const schemas = [
	  "urn:scim:schemas:core:1.0", "urn:scim:schemas:extension:workspace:tenant:sva:1.0", "urn:scim:schemas:extension:workspace:1.0", "urn:scim:schemas:extension:enterprise:1.0"
	]
	const isActive = !user.suspended
	// Set body to be sent
	let title;
	let department
	let phoneNumbers
	let manager

	if(user.organizations){
	title = user.organizations[0].title
	department = user.organizations[0].department
	}
	if(user.phones){
	phoneNumbers = user.phones[0].value
	}
	if(user.relations){
	manager = user.relations[0].value
	}

	const createUserBody = {
	   schemas: schemas,
	   userName: user.primaryEmail,
	   active: isActive,
	   externalId: user.id,
	   //title: user.organizations[0].title ?? '',
	   title: title,
	   name: {
		   givenName: user.name.givenName || null,
		   familyName: user.name.familyName || null
	   },
	   emails: user.primaryEmail,
	  // phoneNumbers: user.phones[0].value ?? null,
	   phoneNumbers: phoneNumbers,
	   //Custom Workspace ONE Access Schema required for the attributes sent below. Hard code internalUserType to 'Provisioned'
	   'urn:scim:schemas:extension:workspace:1.0': {
		  internalUserType: 'PROVISIONED' || null,
		  domain: domain || null,
		  userPrincipalName: user.primaryEmail || null
	  	},
		'urn:scim:schemas:extension:enterprise:1.0': {
			manager: 
				{
					//managerId: user.relations[0].value || null,
					managerId: manager,
				},
			
				//department: user.organizations[0].department || null
				department: department
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
				resolve('err line 672')
			}
			console.log('Processed: ' + user.primaryEmail + ` (result: ${res.status})`)

	
  synclog.info('Processed: ' + user.primaryEmail + ` (result: ${res.status})`)

			if (res.status < 200 || res.status > 299) {
				const response = {
					username: user.primaryEmail,
					statuscode: res.status,
					result: 'notadded'
				}
				resolve (response)
				
			}
			else {

				const response = {
					username: user.primaryEmail,
					statuscode: res.status,
					access_id: res.body.id
				}
				//Get current date and time then regex to a useable format.
				let timedate = new Date().toISOString().
				  replace(/T/, ' ').      // replace T with a space
				  replace(/\..+/, '')     // delete the dot and everything after
				  resolve (response)
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
	console.log(group)
	return new Promise (resolve => {
	const schemas = [
	  "urn:scim:schemas:core:1.0", "urn:scim:schemas:extension:workspace:1.0", "urn:scim:schemas:extension:enterprise:1.0"
	]
	// Set body to be sent
	let createGroupBody;
	if(config.mode == 'azure') {
	createGroupBody = {
	   schemas: schemas,
	   displayName: group.displayName,
	   externalId: group.id,
	   //Custom Workspace ONE Access Schema required for the attributes sent below. Hard code internalGroupType to 'INTERNAL'
	   'urn:scim:schemas:extension:workspace:1.0': {
		  internalGroupType: 'INTERNAL' || null,
		  domain: domain || null
	  	}
	}
	}
	if(config.mode == 'google') {
		createGroupBody = {
		   schemas: schemas,
		   displayName: group.name,
		   externalId: group.id,
		   //Custom Workspace ONE Access Schema required for the attributes sent below. Hard code internalGroupType to 'INTERNAL'
		   'urn:scim:schemas:extension:workspace:1.0': {
			  internalGroupType: 'INTERNAL' || null,
			  domain: domain || null
			  }
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
				let response
				if(config.mode == 'google') {
				response = {
					name: group.name,
					statuscode: res.status,
					accessid: res.body.id,
					groupkey: group.id
				}
				}
				if(config.mode == 'azure') {
					response = {
						name: group.displayName,
						statuscode: res.status,
						accessid: res.body.id,
						groupkey: group.id
					}
					}

				resolve (response)
			}
			else {
				let response
				if(config.mode == 'google') {
				response = {
					name: group.name,
					statuscode: res.status,
					accessid: res.body.id,
					groupkey: group.id
				}
				}
				if(config.mode == 'azure') {
					response = {
						name: group.displayName,
						statuscode: res.status,
						accessid: res.body.id,
						groupkey: group.id
					}
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

async function convertGoogleMembers(members) {

	console.log('Converting Google Group Members (by username) to Access Group Members (by externalID')
	logger.info(new Date().toUTCString());
	const membersArray = async function() {
		var promises = [];
		for (let i = 0; i < members.length; i++) {
		
			
			if(members[i].email.includes(config.access.DOMAIN)){
			const res = await getAccessUserId(members[i]);
		
			if(res.length == []) {
				console.log(`User doesn't exist. Needs to be created.`)
				if(members[i].email) {
					
				const gUser = await listGoogleUser(members[i].email)
				const aUser = await createUserfromGoogle(gUser)
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
			console.log()
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
		.query(`filter=Username co "${members.email}"`)
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
async function syncPartialUserListAzure(userNameArray) {
	console.log()
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
	
		const res = createUserfromAzure(azureUserData);
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

//--Add Users to Access according to Partial Sync Users list from Rollcall--//
async function syncPartialUserListGoogle(userNameArray) {
	console.log()
	console.log(chalk`Processing {blueBright.bold Partial User Sync}`)
	synclog.info(new Date().toUTCString());

	synclog.info(`Processing Partial User Sync`)
	
	
	const usersArray = async function() {
		var promises = [];
		for (let i = 0; i < userNameArray.length; i++) {

			const user = await getAccessUser(userNameArray[i]);		
			function createCheck() { return new Promise (resolve => {
				if(user == undefined){
					console.log(userNameArray[i] + ' Needs to be created')
				resolve(true)
				}
				else {
				resolve(false)
				}
			})
			}
		const create = await createCheck()
		if (create) {
		let googleUserDetails = await listGoogleUser(userNameArray[i]);
		const user = googleUserDetails;
	
		const res = createUserfromGoogle(user);
		if(res != 'notindomain'){
		console.log('Added ' + user.primaryEmail)
		synclog.info(new Date().toUTCString());

		synclog.info('Added ' + user.primaryEmail)
		}
		promises.push( await res )
		console.log('Processed ' + promises.length + ' users...\n');
		synclog.info(new Date().toUTCString());

		synclog.info('Processed ' + promises.length + ' users...\n');

		}
		if (!create) {
			
			let googleUserDetails = await listGoogleUser(userNameArray[i]);
			const accessUser = await getAccessUser(user.userName);
			const changedUser = await diffGoogleUsers(googleUserDetails, accessUser);
			if (changedUser) {

				 const result = await updateUser(changedUser)
				 const response = {
					
					username: user.primaryEmail,
					statuscode: 204
					
				}
				promises.push( response )
			}
			else {
			const response = {
					
				username: user.primaryEmail,
				statuscode: 409
				
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
	let type = 'access';
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
	let type = 'sync';
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		doAll();
		console.log(chalk.blueBright("Updated Sync Schedule."))
		
		resolve('done')
      
    });
}

//Save Group Sync Values
function saveSyncGroups(request) {
	//changed 11/07/22 - group is not defined error for Google?
	let type = 'group';
	return new Promise (resolve => {

		writeConfig(request, type);

		getSecrets();

		callOauthEndpoint();
		
		console.log(chalk.blueBright("Updated Sync Groups."))
		
		resolve('added group')
    });
}

//Delete sync schedule from database
function clearSyncConfig() {
	let type = 'clearSync';
	let request = '';
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
	let type = 'clearTenant';
	let request = '';
	return new Promise (resolve => {
		writeConfig(request, type);
		getSecrets();
		console.log(chalk.blueBright("Cleared Tenant Info."))
		console.log(chalk.yellowBright("Deleting Bearer Token"))
		accessBearer = ''
		resolve('done')  
    });
}

async function clearGroupConfig() {
	let type = 'clearGroup';
	let request = '';
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
	await config.get('sync');
	return new Promise(resolve => {
			
			const response = {
				synctype: config.sync.synctype, 
				syncvalues: config.sync.syncvalues,
				frequency: config.sync.frequency,
				day: config.sync.day,
				time: config.sync.time,
				numberTime: config.sync.time
				}
			resolve (response);

		
})
}

//Get Group Sync values
async function getGroupSyncSettings() {

	return new Promise(resolve => {

		const response = {
			synctype: config.group.synctype, 
			//syncvalues: config.group.syncvalues,
			syncvalues: groupList,
			frequency: config.group.frequency,
			day: config.group.day,
			time: config.group.time,
			numberTime: config.group.time
		}
		
		resolve(response)
	
	})
}

//Parse the "partial group" list values
function parseGroupIDArray() {
	return new Promise(resolve => {	
		// let groupIDArray;
		// //groupIDArray = config.group.syncvalues.split(',');
		// groupIDArray = groupList.split(',');

		resolve(groupList);
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

		 access_url = config.access.URL;
		 client_id = config.access.CLIENT_ID;
		 client_secret = config.access.CLIENT_SECRET;
		 domain = config.access.DOMAIN;

		const response = {
			url: config.access.URL,
			client_id: config.access.CLIENT_ID,
			client_secret: config.access.CLIENT_SECRET,
			domain : config.access.DOMAIN
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
			if (config.access.URL) {
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

	console.log(chalk `Sync Process Starting... {greenBright.bold SUCCESS }`)	
		// if (group == 'groupall') {

		// 	await processAllGroupSync();
		// }
		if (group == 'grouppartial') {
			if(config.mode == 'azure')
			processSequenceSyncAzure();
			if(config.mode == 'google')
			processSequenceSyncGoogle();
		}
		if (!group ) {
		console.log('no groups.')
		}
}

//Function to put all Config and Settings together and decides what to schedule.
// async function doAll() {
// 	const prom = async function() {
// 		const sched = await getSchedule()
// 		//const user = await getUserSyncSettings()
// 		const group = await getGroupSyncSettings() 
// 		if(sched.length) {
			
// 				let hUser
// 				let hGroup
// 				let hFrequency
// 				if (group[0].synctype == 'groupall'){hGroup = `All Groups`}
// 				if (group[0].synctype == 'grouppartial'){hGroup = `Selected Groups`}
// 				if (!group[0].synctype){hGroup = `No groups`}
// 				if (sched[0].frequency == 'hour'){hFrequency = `Hourly (on the hour)`}
// 				if (sched[0].frequency == 'day'){hFrequency = `Daily at ${sched[0].time}`}
// 				if (sched[0].frequency == 'week'){hFrequency = `Weekly on ${sched[0].day} at ${sched[0].time}`}
		
// 				const buildSched = {
// 					grouptype: group[0].synctype,
// 					groupvalues: group[0].syncvalues,
// 					synctype: sched[0].frequency,
// 					day: sched[0].day,
// 					time: sched[0].time,
// 					hourNumber: sched[0].hourNumber,
// 					hGroup: hGroup,
// 					hFrequency: hFrequency
// 				}

// 				return (buildSched)
// 			}
	
// 			else {
// 			let noSched = []
// 			return noSched
// 			}
// 		}
// 		const parsedVals = await prom()
// 		const doSched = async function(){

			
// 			if (parsedVals.synctype == 'hour') {
				
// 			let rule = new schedule.RecurrenceRule()
// 			rule.minute = 0

// 				schedule.scheduleJob(rule, async function() { runSync(parsedVals.grouptype) }
// 			//	schedule.scheduleJob('0 0 0/1 1/1 * ? *', async function() { runSync(parsedVals.grouptype) }
// 				);

// 				return 'ok'
// 			}
// 			if (parsedVals.synctype == 'day') {

// 				let rule = new schedule.RecurrenceRule()
// 				rule.hour = parsedVals.hourNumber

// 				schedule.scheduleJob(rule, function(){
// 					runSync(parsedVals.grouptype)
// 				});	
// 				return 'ok'
// 			}
// 			if (parsedVals.synctype == 'week') {
// 				let dayNumber
// 				if(parsedVals.day == 'Sunday'){dayNumber = 0}
// 				if(parsedVals.day == 'Monday'){dayNumber = 1}
// 				if(parsedVals.day == 'Tuesday'){dayNumber = 2}
// 				if(parsedVals.day == 'Wednesday'){dayNumber = 3}
// 				if(parsedVals.day == 'Thursday'){dayNumber = 4}
// 				if(parsedVals.day == 'Friday'){dayNumber = 5}
// 				if(parsedVals.day == 'Saturday'){dayNumber = 6}

// 				let rule = new schedule.RecurrenceRule()
// 				rule.hour = parsedVals.hourNumber
// 				rule.dayOfWeek = dayNumber
// 				schedule.scheduleJob(rule, function(){
// 					runSync(parsedVals.usertype, parsedVals.grouptype)
// 				});
// 				return 'ok'
// 			}
// 			else {return 'notok'}
// 		}
// 	const result = await doSched() 
// 	if (result == 'ok') {
		
// 		const prettySchedule = chalk`Rollcall Access-Sync Scheduled {whiteBright.bold ${parsedVals.hFrequency}}`
// 			console.log( prettySchedule )
// 			return 'scheduledone'
// 	}
// 	else {
// 	return parsedVals
// 	}
// }

//Function to put all Config and Settings together and decides what to schedule.
async function doAll() {
	
		const prom = async function() {
			const sched = await getSchedule()
			//console.log(sched)
			
			const group = await getGroupSyncSettings() 
			//console.log(group)

			if(sched.synctype != '') {
				
					let hGroup
					let hFrequency
					
					if (group.synctype == 'grouppartial'){hGroup = `Selected Groups`}
					if (!group.synctype){hGroup = `No groups`}
					if (sched.frequency == 'hour'){hFrequency = `Hourly (on the hour)`}
					if (sched.frequency == 'day'){hFrequency = `Daily at ${sched[0].time}`}
					if (sched.frequency == 'week'){hFrequency = `Weekly on ${sched[0].day} at ${sched[0].time}`}
			
					const buildSched = {
						grouptype: group.synctype,
						groupvalues: group.syncvalues,
						synctype: sched.frequency,
						day: sched.day,
						time: sched.time,
						hourNumber: sched.numberTime,
						hGroup: hGroup,
						hFrequency: hFrequency
					}
					//console.log(buildSched);
					return (buildSched)
				}
		
				else {
				let noSched = []
				console.log('No Schedule Set')
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
	if(config.mode == 'google'){
		runSync('grouppartial')
		return 'ok'
	}
	else{
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
			

					grouptype: config.group.synctype,
					//groupvalues: config.group.syncvalues,
					groupvalues: groupList,
					
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

async function processSequenceSyncAzure() {
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
		let userResult = await syncPartialUserListAzure(emailArray);



		//All users added to Access, now need to do memberships
	
		const prom3 = async function() {
			console.log()
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

//###############
//
//
//GOOOOOOOOOGLE
//
//
//
//###############

//====================
//--Let the initial Google Request do the auth and then re-use it below.
let OAuth2Client;
//====================

//######################################################################################################
//
// Google Authentication (from their quickstart)
//
//######################################################################################################




let creds;
fs.readFile(CREDENTIALS_PATH, (err, content) => {
  if (err) return console.error('Error loading client secret file', err);
    authorize(JSON.parse(content), checkApi);
});

/**
 * @param {Object} credentials The authorization client credentials.
 * @param {function} callback The callback to call with the authorized client.
 */
async function authorize(credentials, callback) {
  const {client_secret, client_id, redirect_uris} = credentials.installed;
  const oauth2Client = new google.auth.OAuth2(
	client_id, client_secret, 'http://localhost:8080/oauth/');
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

//Duplicate function to read Google credentials
function readCreds() {
	return new Promise(resolve => {
	fs.readFile(CREDENTIALS_PATH, (err, content) => {
		const parsed = JSON.parse(content)
	resolve(parsed)
})
})
}

//Call Google API to keep the Access Token alive (expires every hour unless used)
async function keepAlive() {
	console.log('====================================================================')
	logger.info(new Date().toUTCString());
	logger.info('Calling API to keep Google access_token alive.')
	console.log('Calling API to keep Google access_token alive.')
	const gcreds = await readCreds()
	
	authorize(gcreds, checkApi), (err, res) => {
		if(err) {
  logger.info(new Date().toUTCString());

			logger.info(err)

			console.log("err")
			resolve(err)
		}

		return 'ok'
	}
}


//Run a scheduled job to keep token alive
schedule.scheduleJob('0/15 * 1/1 * *', function () { keepAlive()});



//---Users---//

let gstatus

async function getGoogleStatus() {

	return new Promise (resolve => {
		const headers = {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ` + OAuth2Client.credentials.access_token
	}
	superagent
		//see line 393!!!
		.get('https://admin.googleapis.com/admin/directory/v1/users')
		.set(headers)
		.query({ customer: 'my_customer', maxResults: 1})
		.then(res => {
			const users = res.body;
			if(res.status = 200){
				gstatus = true;
				console.log('====================================================================')
				console.log(chalk.greenBright.bold('Successfully queried Google Directory.'));
			}
			resolve(users);
	  })
	  
	});
	  
	 

}

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
					listAllGoogleUsers(users, res.body.nextPageToken).then((resusers) => {
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
		const auser = accessUser;

		



		

		
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
				console.log(googleUserData.emails +": No User Attribute Updates Required.")
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
					getGoogleMembers(id, res.body.nextPageToken).then((memberResult) => {
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

async function processSequenceSyncGoogle() {
	console.log()
	console.log(chalk`Processing {cyanBright.bold Partial Group Sync}`)
	//Step One: Get Group Object Info to sync.
	const ids = await parseGroupIDArray()
	const prom = async function() {
		let promises = []
				for (let i = 0; i < ids.length; i++) {
				
					async function getGroup() { return new Promise (resolve => {
					
						getGoogleGroupById(ids[i]).then(data =>{
					
							resolve (data)})
			
					})
					}
					const group = await getGroup()
					promises.push( await group)
					console.log()
					console.log('Processed ' + promises.length + ' groups...\n');
				}
			return Promise.all(promises)
		}
		const groups = await prom()
	
	//Step Two: Do the Sync.
		const prom2 = async function() {
		console.log(chalk`{cyan.bold Getting Group details and members.}`)
		
			var promises = [];
			var groupResults = [];
			for (let i = 0; i < groups.length; i++) {
				async function createCheck() { return new Promise (resolve => {
	
						
					const res = getAccessGroup(groups[i]);
				
	
					resolve(res);
						})
					}
				//Checks for each Group by ID to see if its been added to DB and therefore exists in Access.	
			const check = await createCheck()
			if(check[0]) {
				console.log()
				console.log(groups[i].name + ` (id/externalId: ${groups[i].id})` + ' previously created, skipping creation. \n')
				//resolving false means it doesn't need to be created (create = false)
				create = false;
				}
			else {
				//group doesn't exist in Access
				create = true;
				}
			//CREATE TRUE
			if (create) {
				
			const createGroupResult = await createGroup(groups[i]); 
			console.log('Added ' + groups[i].name)
			const members = await getGoogleMembers(createGroupResult);
			
			// this is where it changes!
			let memberEmail = []

			if(members !== undefined){
				for (let i = 0; i < members.length; i++) {
					memberEmail.push(members[i].email)
				}
			promises.push( memberEmail )
			}
			}
			//CREATE FALSE
			if (!create) {
				const groupKey = {
					groupkey: groups[i].id
				}
				const members = await getGoogleMembers(groupKey);
				let memberEmail = []

				if(members !== undefined){
				for (let i = 0; i < members.length; i++) {
					memberEmail.push(members[i].email)
				}
			}
				const accessGroup = await getAccessGroup(groups[i]);
				const group = groups[i]
	
				const changedGroup = await diffGoogleGroup(group, accessGroup);
				if (changedGroup) {
	
					const res = await updateGroup(changedGroup)

				}
				
				promises.push( memberEmail )
		
			}
			}
			return Promise.all(promises)
		}
		const emails = await prom2()
		
		let emailArray = []
		for (let i = 0; i < emails.length; i++) {
			const vals = emails[i].values()
			for (const value of vals){
				
				emailArray.push(value)
			}
		}
		console.log(chalk`{cyan.bold Getting list of unique users to sync.}`)
		//let userEmails = await parseEmailArray();
	
		// for (let i = 0; i < userEmails.length; i++) {
		// 		emailArray.push(userEmails[i])
		// 	}
		
	
		await sleep(3000);
		let userResult = await syncPartialUserListGoogle(emailArray);
		//All users added to Access, now need to do memberships
	
		const prom3 = async function() {
			console.log()
		console.log(chalk`{cyan.bold Comparing and updating Group Memberships.}`)
			var promises = [];
			for (let i = 0; i < groups.length; i++) {
	
				const accessGroup = await getAccessGroup(groups[i]);


				const group = groups[i]
				const groupKey = {
					groupkey: groups[i].id
				}
			
				const members = await getGoogleMembers(groupKey);

					const convertedMembers = await convertGoogleMembers(members);

			
	
				const addDetails = {
					name: groups[i].name,
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
	}


	function testGetGroup() {

	
		return new Promise (resolve => {
		superagent
			.get(access_url + '/SAAS/jersey/manager/api/scim/Groups')
			.auth(accessBearer, { type: 'bearer'})
			.query(`filter=id co "2e9bc79c-71b3-4a30-9c5d-4011f7a4034f"`)
			  .then(res => {
				  
				const rtn = res.body.Resources
				console.log(rtn)
				//console.log(rtn[0]['members'])
				resolve(rtn);
		  });
		  
		});
	}


//Run at Startup
readGroupFile();
doAll();


//sleep(2000).then((data) => runSync('grouppartial'));
//sleep(2000).then((data) => getAllAccessGroups());
//sleep(2000).then((data) => testGetGroup());
//console.log(config.google.access_token);
//getGoogleStatus();

if(config.mode == "azure"){
getGraphStatus();
};





