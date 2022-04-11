//-- 	Setting Configuration 	--//
const config = require('config');
let azure;
let access;
let sync;

async function readConfig () {
	azure = config.get('azure');
	access = config.get('access');
	sync = config.get('sync');
};

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


const cca = new msal.ConfidentialClientApplication(msalConfig);

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