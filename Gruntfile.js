const rulesConfigInfra = require('rules-config/infra');
const IDI = require('openchs-idi');
const secrets = require('../secrets.json');

module.exports = IDI.configure({
    "name": "sewa_rural",
    "chs-admin": "admin",
    "org-name": "Sewa Rural",
    "org-admin": {
        "dev": "adminsr",
        "prod": "adminold@sr",
    },
    "secrets": secrets,
    "files": {
        "adminUsers": {
            "dev": ["./users/admin-user.json"],
        },
        "forms": [
            "./registrationForm.json",
            "./adolescent/sickleCellVulnerabilityForm.json",
        ],
        "formMappings": [
            "./formMappings.json",
        ],
        "formDeletions": [
            "./mother/enrolmentDeletions.json"
        ],
        "formAdditions": [
            "./mother/enrolmentAdditions.json",
        ],
        "catchments": ["./catchments.json"],
        "checklistDetails": [],
        "concepts": [
            "./concepts.json",
            "./adolescent/sickleCellVulnerabilityConcepts.json",
        ],
        "addressLevelTypes": [],
        "locations": ["./locations.json"],
        "programs": [],
        "encounterTypes": ["./encounterTypes.json"],
        "operationalEncounterTypes": ["./operationalModules/operationalEncounterTypes.json"],
        "operationalPrograms": ["./operationalModules/operationalPrograms.json"],
        "operationalSubjectTypes": ["./operationalModules/operationalSubjectTypes.json"],
        "users": {
            "dev": ["./users/dev-users.json"],
        },
        "videos": ["./videos.json"],
        "rules": ["./rules.js"],
        "organisationSql": []
    }
}, rulesConfigInfra);
