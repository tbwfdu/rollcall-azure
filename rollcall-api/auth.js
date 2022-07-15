//-- 	Setting Configuration 	--//
const config = require('config');
const fs = require('fs');
const {google} = require('googleapis');
const readline = require('readline');
const chalk = require('chalk');
const path = require('path');
let azure;
let access;
let sync;
let creds;
let mode;


async function readConfig () {
	azure = config.get('azure');
	access = config.get('access');
	sync = config.get('sync');
    mode = config.get('mode');
};

function checkExistsWithTimeout(filePath, timeout) {
    return new Promise(function (resolve, reject) {
        var timer = setTimeout(function () {
            watcher.close();
            reject(new Error('File did not exist and was not created during the timeout.'));
        }, timeout);
  
        fs.access(filePath, fs.constants.R_OK,  function (err) {
          
            if (!err) {
                clearTimeout(timer);
                watcher.close();
  
                resolve('true');
            }
        });
  
        var dir = path.dirname(filePath);
        var basename = path.basename(filePath);
        var watcher = fs.watch(dir, function (eventType, filename) {
          
            if (eventType === 'rename' && filename === basename) {
                clearTimeout(timer);
                watcher.close();
                resolve('true');
            }
        });
    });
  }

readConfig();

//--							--//


const msal = require('@azure/msal-node');

const msalConfig = {
    auth: {
        clientId: azure.CLIENT_ID,
        authority: azure.AAD_ENDPOINT + '/' + azure.TENANT_ID,
        clientSecret: azure.CLIENT_SECRET,
    }
};

const tokenRequest = {
    scopes: [azure.GRAPH_ENDPOINT + '/.default'],
};

const userAPI = {
    uri: azure.GRAPH_ENDPOINT + '/v1.0/users?$select=displayName,givenName,surname,jobTitle,mail,userPrincipalName,id,department,businessPhones,manager,accountEnabled',
};

const groupAPI = {
    uri: azure.GRAPH_ENDPOINT + '/v1.0/groups',
};

const graphAPI = {
    uri: azure.GRAPH_ENDPOINT + '/v1.0/users',
};

if(mode == "azure"){
const cca = new msal.ConfidentialClientApplication(msalConfig);
}
/**
 * Acquires token with client credentials.
 * @param {object} tokenRequest
 */
async function getToken(tokenRequest) {
    return await cca.acquireTokenByClientCredential(tokenRequest);
}

module.exports = {
    userAPI: userAPI,
    groupAPI: groupAPI,
    graphAPI: graphAPI,
    tokenRequest: tokenRequest,
    getToken: getToken
};