const prompt = require('prompt-sync')({sigint: true});
const config = require('config');
const gauth = require('./google-auth');
const chalk = require('chalk');
const fs = require('fs');

const Koa = require('koa')
const cors = require('@koa/cors');
const Router = require('koa-router')
const bodyParser = require('koa-bodyparser')



const router = new Router()  
const app = new Koa();
app.use(bodyParser())
app.use(router.routes())


// Adding CORS to remove Angular proxy dependency
app.use(cors())

router.get('/oauth', async function (ctx, next) {	
	let code = (ctx.query.code);
 
	ctx.set('Access-Control-Allow-Origin', '*')
  //console.log(code)
	ctx.body = code
});


const PORT = process.env.PORT || 8080;


function makeid(length) {
    var result           = '';
    var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * 
 charactersLength));
   }
   return result;
}

//-- 	Setting Configuration 	--//
let azure;
let google;
let access;
let rollcall;
let mode;

let accessTenant
let accessClientID
let accessClientSecret
let accessDomain

let googleAccessToken
let googleRefreshToken
let googleScope

let azureTenantID
let azureClientID
let azureClientSecret

let azureADEndpoint
let azureGraphEndpoint

let apiUser
let apiPassword

// azure = config.get('azure');
// google = config.get('google');
// access = config.get('access');
// rollcall = config.get('rollcall');
// mode = config.get('mode');


function readConfig () {
	azure = config.get('azure');
	google = config.get('google');
	access = config.get('access');
	rollcall = config.get('rollcall');
	mode = config.get('mode');

    accessTenant = access.accessTenant;
    accessClientID = access.accessClientID;
    accessClientSecret = access.accessClientSecret;
    accessDomain = access.accessDomain;

    azureTenantID = azure.azureTenantID;
    azureClientID = azure.azureClientID;
    azureClientSecret = azure.azureClientSecret;

    azureADEndpoint = 'https://login.microsoftonline.com';
    azureGraphEndpoint = 'https://graph.microsoft.com';
   
    googleAccessToken = google.access_token;
    googleRefreshToken = google.refresh_token;
    googleScope = google.scope;
};

function printConfig () {
	console.log('mode:');
	console.log(mode);
    console.log('azure:');
	console.log(azure);
	console.log('google:');
	console.log(google);
	console.log('access:');
	console.log(access);
	console.log('rollcall:');
	console.log(rollcall);
    
};


async function awaitGoogle() {

    app.listen(PORT, () => {
	  
        console.log(chalk
            `{white ====================================================================}  `+
            chalk`\nNow configuring Google OAuth Credentials`+
            chalk`{white \n====================================================================}`)
        });
    
    const g = await gauth.getGoogleToken();
  
    
    
};


async function confirmWriteConfig() {
	return new Promise (resolve => {
   
    let confirmation;
    var configFile = fs.readFileSync("./config/default.json");
    var configJSON = JSON.parse(configFile)

    console.log("##############################");
	console.log("Configuration Details:");
    console.log(chalk`{blueBright.bold Mode: }` + mode)
    console.log()
    if(mode == azure) {
    console.log(chalk`{blueBright.bold Azure Tenant ID: }` + azureTenantID)
    console.log(chalk`{blueBright.bold Azure Client ID: }` + azureClientID)
    console.log(chalk`{blueBright.bold Azure Client Secret: }` + azureClientSecret)
    console.log(chalk`{blueBright.bold Azure AD Endpoint: }` + azureADEndpoint)
    console.log(chalk`{blueBright.bold Azure Graph Endpoint: }` + azureGraphEndpoint)
    }
    console.log()
    
    console.log(chalk`{greenBright.bold Access Tenant: }` + accessTenant)
    console.log(chalk`{greenBright.bold Access Client ID: }` + accessClientID)
    console.log(chalk`{greenBright.bold Access Client Secret: }` + accessClientSecret)
    console.log(chalk`{greenBright.bold Access Domain: }` + accessDomain)
    
    console.log()
    console.log(chalk`{yellowBright.bold API User: }` + apiUser)
    console.log(chalk`{yellowBright.bold API Password: }` + apiPassword)
    console.log()
    console.log()
    console.log("##############################");

    confirmation = prompt('Save Configuration (Y/N)?');

    if (confirmation == 'Y' || confirmation == 'y'){
      
        configJSON.azure.TENANT_ID = azureTenantID
		configJSON.azure.CLIENT_ID = azureClientID
		configJSON.azure.CLIENT_SECRET = azureClientSecret
		configJSON.azure.AAD_ENDPOINT = azureADEndpoint
		configJSON.azure.GRAPH_ENDPOINT = azureGraphEndpoint
        
	
		configJSON.access.URL = accessTenant
		configJSON.access.CLIENT_ID = accessClientID
		configJSON.access.CLIENT_SECRET = accessClientSecret
		configJSON.access.DOMAIN = accessDomain

		configJSON.rollcall.apiUser = apiUser
		configJSON.rollcall.apiPassword = apiPassword

        configJSON.mode = mode

		
        var configContent = JSON.stringify(configJSON);
		
	
	fs.writeFile("./config/default.json", configContent, 'utf8', function (err) {
		if (err) {
			console.log("An error occured while writing JSON Object to File.");
			return console.log(err);
		}
		console.log("Saved Rollcall Configuration File.");

	});
    
	
    }
    else{
    
    }
    resolve('done')
})

};

// Create some time for sleep
function sleep(ms) {
	return new Promise((resolve) => {
	  setTimeout(resolve, ms);
	});
  }

async function getConfig() {
console.log()
console.log()
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
    chalk`\nRollcall Server API Configuration...`+
    chalk`{white \n====================================================================}`
    
        )
console.log()
console.log()

mode = prompt('Are you configuring for Azure AD or Google Directory? (Type azure or google)   ');

accessTenant = prompt('Enter Access Tenant: (https://company.vmwareidentity.com)  ');
accessClientID = prompt('Enter Access ClientID:  ');
accessClientSecret = prompt('Enter Access Client Secret:  ');
accessDomain = prompt('Enter Domain: (eg. mydomain.com)  ');


apiUser = makeid(16)
apiPassword = makeid(16)


if(mode == 'azure') {
azureTenantID = prompt('Enter Azure Tenant: (eg. company.onmicrosoft.com)  ');
azureClientID = prompt('Enter Azure ClientID:  ');
azureClientSecret = prompt('Enter Azure Client Secret:  ');
azureADEndpoint = prompt('Enter AAD Endpoint: [Press Enter to add default (https://login.microsoftonline.com)]  ');
azureGraphEndpoint = prompt('Enter AAD Graph Endpoint: [Press Enter to add default (https://graph.microsoft.com)]  ');
if (!azureADEndpoint){azureADEndpoint = 'https://login.microsoftonline.com'}
if (!azureGraphEndpoint){azureGraphEndpoint = 'https://graph.microsoft.com'}
confirmWriteConfig();
}
confirmWriteConfig();
await sleep(1000);
if(mode == 'google') {
//note: confirmWriteConfig function for Google is part of awaitGoogle function

await awaitGoogle();

}

}


readConfig();


if(mode == ''){
    getConfig();
}
else{
    console.log('Rollcall Configured.')
    printConfig();
}

module.exports = {
    mode,
    azure,
    access,
    google,
    rollcall,
   
  };
//awaitGoogle();