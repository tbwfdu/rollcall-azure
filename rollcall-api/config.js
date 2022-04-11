const prompt = require('prompt-sync')({sigint: true});
const config = require('config');
const chalk = require('chalk');
const fs = require('fs');
const { inspect } = require('util');

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
let access;
let rollcall;

azure = config.get('azure');
access = config.get('access');
rollcall = config.get('rollcall');


function readConfig () {
	azure = config.get('azure');
	access = config.get('access');
	rollcall = config.get('rollcall');
};

readConfig();
async function confirmWriteConfig() {
	return new Promise (resolve => {
   
        let confirmation;
        var configFile = fs.readFileSync("./config/default.json");
        var configJSON = JSON.parse(configFile)
        
    console.log("##############################");
	console.log("Configuration Details:");
    console.log()
    console.log(chalk`{blueBright.bold Azure Tenant ID: }` + azureTenantID)
    console.log(chalk`{blueBright.bold Azure Client ID: }` + azureClientID)
    console.log(chalk`{blueBright.bold Azure Client Secret: }` + azureClientSecret)
    console.log(chalk`{blueBright.bold Azure AD Endpoint: }` + azureADEndpoint)
    console.log(chalk`{blueBright.bold Azure Graph Endpoint: }` + azureGraphEndpoint)
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



var azureTenantID = prompt('Enter Azure Tenant: (eg. company.onmicrosoft.com)  ');
var azureClientID = prompt('Enter Azure ClientID:  ');
var azureClientSecret = prompt('Enter Azure Client Secret:  ');
var azureADEndpoint = prompt('Enter AAD Endpoint: [Press Enter to add default (https://login.microsoftonline.com)]  ');
var azureGraphEndpoint = prompt('Enter AAD Graph Endpoint: [Press Enter to add default (https://graph.microsoft.com)]  ');

var accessTenant = prompt('Enter Access Tenant: (https://company.vmwareidentity.com)  ');
var accessClientID = prompt('Enter Access ClientID:  ');
var accessClientSecret = prompt('Enter Access Client Secret:  ');
var accessDomain = prompt('Enter Domain: (eg. mydomain.com)  ');

var apiUser = makeid(16)
var apiPassword = makeid(16)

if (!azureADEndpoint){azureADEndpoint = 'https://login.microsoftonline.com'}
if (!azureGraphEndpoint){azureGraphEndpoint = 'https://graph.microsoft.com'}

confirmWriteConfig();





