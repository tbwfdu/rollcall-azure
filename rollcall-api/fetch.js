const axios = require('axios');
const superagent = require('superagent');

/**
 * Calls the endpoint with authorization bearer token.
 * @param {string} endpoint
 * @param {string} groupendpoint
 * @param {string} accessToken
 */
async function callApi(endpoint, accessToken) {
 
    const options = {
        headers: {
            Authorization: `Bearer ${accessToken}`
        }
    };
    try {
        const response = await axios.default.get(endpoint, options);
        return response.data;
    } catch (error) {
        return error;
    }
};

async function graphStatus(endpoint, accessToken) {

    const options = {
        headers: {
            Authorization: `Bearer ${accessToken}`
        },
       
    };

    try {
        const response = await axios.default.get(endpoint, options);
        
        
        return response.data;
    } catch (error) {
       // console.log(error)
        return error;
    }
};

async function getGroup(groupID, accessToken) {
    // when updating user, it seems to be sending ONLY the email address as user. Creating users sends as sub-attribute.
        return new Promise (resolve => {
            const headers = {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ` + accessToken
        }
        superagent
            .get('https://graph.microsoft.com/v1.0/groups/' + groupID)
            .set(headers)
              .then(res => {
                const group = res.body;
                resolve(group);
          });
          
        });
};

async function getGroupMembers(groupID, accessToken) {
            return new Promise (resolve => {
                const headers = {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ` + accessToken
            }
            superagent
                .get('https://graph.microsoft.com/v1.0/groups/' + groupID + '/members')
                .set(headers)
                  .then(res => {
                    const members = res.body["value"];
                    resolve(members);
              });
              
            });
};

async function getUser(mail, accessToken) {
                return new Promise (resolve => {
                    const headers = {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ` + accessToken
                }
                superagent
                    .get('https://graph.microsoft.com/v1.0/users/' + mail +'?$select=displayName,givenName,surname,jobTitle,mail,userPrincipalName,id,department,businessPhones,manager,accountEnabled')
                    .set(headers)
                      .then(res => {
                        const user = res.body;
                       
                        resolve(user);
                  });
                  
                });
};

module.exports = {
    callApi: callApi,
    graphStatus: graphStatus,
    getGroup: getGroup,
    getGroupMembers: getGroupMembers,
    getUser: getUser

};