-- `sf org list metadata -m ApexClass -o devhub --json`
--
-- SYNTHETIC: not captured from a real org. Shaped after
-- salesforcecli/plugin-org src/commands/org/list/metadata.ts, whose result is
-- the Metadata API `FileProperties[]` from `listMetadata`. The plugin skips
-- entries with `manageableState` "installed", so one is included. Replace
-- with a real, scrubbed capture and set `recorded = true`.
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
  "status": 0,
  "result": [
    {
      "createdById": "005000000000001AAA",
      "createdByName": "Fake Admin",
      "createdDate": "2026-01-01T08:00:00.000Z",
      "fileName": "classes/SfProject.cls",
      "fullName": "SfProject",
      "id": "01p000000000001AAA",
      "lastModifiedById": "005000000000001AAA",
      "lastModifiedByName": "Fake Admin",
      "lastModifiedDate": "2026-01-01T08:30:00.000Z",
      "manageableState": "unmanaged",
      "type": "ApexClass"
    },
    {
      "createdById": "005000000000001AAA",
      "createdByName": "Fake Admin",
      "createdDate": "2026-01-01T08:00:00.000Z",
      "fileName": "classes/SfProjectTest.cls",
      "fullName": "SfProjectTest",
      "id": "01p000000000002AAA",
      "lastModifiedById": "005000000000001AAA",
      "lastModifiedByName": "Fake Admin",
      "lastModifiedDate": "2026-01-01T08:30:00.000Z",
      "manageableState": "unmanaged",
      "type": "ApexClass"
    },
    {
      "createdById": "005000000000002AAA",
      "createdByName": "Package Installer",
      "createdDate": "2025-06-01T08:00:00.000Z",
      "fileName": "classes/fakens__Installed.cls",
      "fullName": "fakens__Installed",
      "id": "01p000000000003AAA",
      "lastModifiedById": "005000000000002AAA",
      "lastModifiedByName": "Package Installer",
      "lastModifiedDate": "2025-06-01T08:00:00.000Z",
      "manageableState": "installed",
      "namespacePrefix": "fakens",
      "type": "ApexClass"
    }
  ],
  "warnings": []
}
]==],
}
