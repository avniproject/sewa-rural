const rulesConfigInfra = require('rules-config/infra');
const IDI = require('openchs-idi');

module.exports = IDI.configure({
    "name": "sewa_rural",
    "chs-admin": "admin",
    "org-name": "Sewa Rural",
    "org-admin": {
        "dev": "adminsr",
        "prod": "adminold@sr",
        "staging": "adminsr"
    },
    "secrets": "../secrets.json",
    "files": {
        "adminUsers": {
            "dev": ["./users/admin-user.json"],
        },
        "forms": [
            "./adolescent/metadata/adolescentEnrolment.json",
            "./adolescent/metadata/adolescentProgramExitForm.json",
            "./adolescent/metadata/adolescentDropoutForm.json",
            "./adolescent/metadata/adolescentDropoutFollowupForm.json",
            "./adolescent/metadata/adolescentProgramEncounterCancellationForm.json",
            "./adolescent/metadata/annualVisit.json",
            "./registrationForm.json",
            "./adolescent/followups/sickleCellVulnerabilityForm.json",
            "./adolescent/followups/chronicSickness.json",
            "./adolescent/followups/menstrualDisorder.json",
            "./adolescent/followups/severeAnemia.json",
            "./adolescent/followups/moderateAnemia.json",
            "./adolescent/followups/severeMalnutrition.json",
            "./adolescent/followups/addiction.json",
            "./adolescent/metadata/quarterlyVisit.json"
        ],
        "formMappings": [
            "./formMappings.json"
        ],
        "formDeletions": [
            "./mother/enrolmentDeletions.json",
            "./adolescent/metadata/enrolmentDeletions.json"
        ],
        "formAdditions": [
            "./mother/enrolmentAdditions.json",
        ],
        "catchments": ["./catchments.json"],
        "checklistDetails": [],
        "concepts": [
            "./concepts.json",
            "./adolescent/metadata/commonConcepts.json",
            "./adolescent/followups/sickleCellVulnerabilityConcepts.json",
            "./adolescent/followups/chronicSicknessConcepts.json",
            "./adolescent/followups/menstrualDisorderConcepts.json",
            "./adolescent/followups/severeAnemiaConcepts.json",
            "./adolescent/followups/severeMalnutritionConcepts.json",
            "./adolescent/followups/addictionConcepts.json"
        ],
        "adolescentConfig": [],
        "addressLevelTypes": [],
        "locations": ["./locations.json"],
        "programs": [],
        "encounterTypes": [
            "./encounterTypes.json"
        ],
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
