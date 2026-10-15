-- `sf api request rest services/data/v62.0/composite/batch --method POST
-- --body @<file> -o devhub --json`, where the body holds one
-- `GET v62.0/sobjects/<name>/describe` sub-request per sObject: the describe
-- batch the sObject refresh sends for the names in sobject_list.lua.
--
-- SYNTHETIC: not captured from a real org. The envelope is shaped after
-- salesforcecli/plugin-api src/commands/api/request/rest.ts and
-- src/shared/shared.ts (`result` is `{ statusCode, headers, body }`, `status`
-- is the exit code). The body is shaped after the Batch resource (`hasErrors`,
-- `results[].statusCode`, `results[].result`) and the sObject Describe resource
-- in the Salesforce REST API Developer Guide; describes keep only the fields
-- the plugin reads. The Contact sub-request failed, to cover partial failures.
-- Replace with a real, scrubbed capture and set `recorded = true`.
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
  "status": 0,
  "result": {
    "statusCode": 200,
    "headers": { "content-type": "application/json;charset=UTF-8" },
    "body": {
      "hasErrors": true,
      "results": [
        {
          "statusCode": 200,
          "result": {
            "name": "Account",
            "label": "Account",
            "custom": false,
            "fields": [
              { "name": "Id", "type": "id", "referenceTo": [], "relationshipName": null, "inlineHelpText": null },
              { "name": "Name", "type": "string", "referenceTo": [], "relationshipName": null, "inlineHelpText": null },
              { "name": "AnnualRevenue", "type": "currency", "referenceTo": [], "relationshipName": null, "inlineHelpText": null },
              { "name": "NumberOfEmployees", "type": "int", "referenceTo": [], "relationshipName": null, "inlineHelpText": null },
              { "name": "OwnerId", "type": "reference", "referenceTo": ["User"], "relationshipName": "Owner", "inlineHelpText": null },
              { "name": "ParentId", "type": "reference", "referenceTo": ["Account"], "relationshipName": "Parent", "inlineHelpText": null }
            ],
            "childRelationships": [
              { "childSObject": "Contact", "field": "AccountId", "relationshipName": "Contacts" },
              { "childSObject": "Invoice__c", "field": "Account__c", "relationshipName": "Invoices__r" }
            ]
          }
        },
        {
          "statusCode": 404,
          "result": [
            { "errorCode": "NOT_FOUND", "message": "The requested resource does not exist" }
          ]
        },
        {
          "statusCode": 200,
          "result": {
            "name": "Invoice__c",
            "label": "Invoice",
            "custom": true,
            "fields": [
              { "name": "Id", "type": "id", "referenceTo": [], "relationshipName": null, "inlineHelpText": null },
              { "name": "Name", "type": "string", "referenceTo": [], "relationshipName": null, "inlineHelpText": null },
              { "name": "Amount__c", "type": "currency", "referenceTo": [], "relationshipName": null, "inlineHelpText": "Total incl. tax" },
              { "name": "Account__c", "type": "reference", "referenceTo": ["Account"], "relationshipName": "Account__r", "inlineHelpText": null }
            ],
            "childRelationships": []
          }
        },
        {
          "statusCode": 200,
          "result": {
            "name": "MyPlatform__e",
            "label": "My Platform Event",
            "custom": true,
            "fields": [
              { "name": "ReplayId", "type": "string", "referenceTo": [], "relationshipName": null, "inlineHelpText": null }
            ],
            "childRelationships": []
          }
        }
      ]
    }
  },
  "warnings": []
}
]==],
}
