-- Response body of `POST /services/data/v62.0/composite/batch` with one
-- `GET v62.0/sobjects/<name>/describe` sub-request per sObject: the describe
-- batch the sObject refresh sends.
--
-- SYNTHETIC: not captured from a real org. Shaped after the Batch resource
-- (`hasErrors`, `results[].statusCode`, `results[].result`) and the sObject
-- Describe resource in the Salesforce REST API Developer Guide; describes keep
-- only the fields the plugin reads. The third sub-request failed, to cover
-- partial failures. Replace with a real, scrubbed capture and set
-- `recorded = true`.
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
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
      "statusCode": 404,
      "result": [
        { "errorCode": "NOT_FOUND", "message": "The requested resource does not exist" }
      ]
    }
  ]
}
]==],
}
