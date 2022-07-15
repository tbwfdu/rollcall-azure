const fs = require('fs');
const {google} = require('googleapis');
const readline = require('readline');
const chalk = require('chalk');
const path = require('path');
const Koa = require('koa')
const cors = require('@koa/cors');
const Router = require('koa-router')
const bodyParser = require('koa-bodyparser')
const prompt = require('prompt-sync')({sigint: true});



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

function sleep(ms) {
	return new Promise((resolve) => {
	  setTimeout(resolve, ms);
	});
  }


//######################################################################################################
//
// Google Authentication and Functions
//
//######################################################################################################

const SCOPES = ['https://www.googleapis.com/auth/admin.directory.user', 'https://www.googleapis.com/auth/admin.directory.group', 'https://www.googleapis.com/auth/admin.directory.orgunit'];
const TOKEN_PATH = './config/token.json'
const CREDENTIALS_PATH = './config/credentials.json'

let creds;

async function writeToken(token) {
	return new Promise (resolve => {
   
   
    let confirmation
    var configFile = fs.readFileSync("./config/default.json");
    var configJSON = JSON.parse(configFile)

    console.log("##############################");
	  console.log("Google Configuration Details:");
   
    console.log()
    console.log(chalk`{yellowBright.bold Access Token: }`)
    console.log(token.access_token)
    console.log(chalk`{yellowBright.bold Refresh Token: }`)
    console.log(token.refresh_token)
    console.log(chalk`{yellowBright.bold Scope: }`)
    console.log(token.scope)
    console.log()
    console.log("##############################");

    confirmation = prompt('Save Google Configuration (Y/N)?');

    if (confirmation == 'Y' || confirmation == 'y'){
      
    configJSON.google.access_token = token.access_token
		configJSON.google.refresh_token = token.refresh_token
		configJSON.google.scope = token.scope

		
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

async function getGoogleToken() {

  fs.readFile(CREDENTIALS_PATH, (err, content) => {
  if (err) return console.error('Error loading client secret file', err);

  authorize(JSON.parse(content), checkApi);
  
  });
 

};


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
      
	    //writeToken(token);
      storeToken(token);
      callback(oauth2Client);
      
    });
  });
}

/**
 * @param {Object} token The token to store to disk.
 */
async function storeToken(token) {
  fs.writeFile(TOKEN_PATH, JSON.stringify(token), (err) => {
    if (err) return console.warn(`Token not stored to ${TOKEN_PATH}`, err);
    console.log(`Token stored to ${TOKEN_PATH}`);
    sleep(3000).then((res) =>
    process.exit());
  });
}
let gstatus
/**
 * @param {google.auth.OAuth2} auth An authorized OAuth2 client.
 * 
 */
//changed below to only list a single user as we are now calling it in the other script

async function checkApi(auth) {
  return new Promise (resolve => {
  const service = google.admin({version: 'directory_v1', auth}); 
  
  service.users.list({
    customer: 'my_customer',
    maxResults: 1,
    orderBy: 'email',
   
  }, (err, res) => {
    if (err) {
      
      return console.error('The API returned an error:', err.message);
    }
	const users = res.data.users;
	gstatus = true
    if (users.length) {
	  console.log('====================================================================')
      console.log(chalk.greenBright('Successfully queried Google Directory.'));
      console.log();
      console.log(chalk.greenBright('Google OAuth Configuration Complete. Now Exiting.'));
      console.log('====================================================================')

      gauth = auth;
    } else {
      console.log('No users found.');
    }
  });
  sleep(5000).then((res) => process.exit());
   resolve('ok')

});
}


module.exports = {
  getGoogleToken,
  gstatus,
  creds
};
