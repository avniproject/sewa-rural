const _ = require('lodash');

module.exports = _.merge({},
    require('./adolescent/rules/visitSchedules'),
    require('./adolescent/rules/adolescentProgramEncounterDecision'),
    require('./adolescent/rules/adolescentProgramEnrolmentDecision'),
    require('./adolescent/rules/sickleCellFormHandler'),
    require('./adolescent/rules/chronicSicknessFormHandler'),
    require('./adolescent/rules/menstrualDisorderHandler'),
    require('./adolescent/rules/severeAnemiaFormHandler'),
    require('./adolescent/rules/moderateAnemiaFormHandler'),
    require('./adolescent/rules/severeMalnutritionFormHandler'),
    require('./adolescent/rules/addictionFormHandler'),
    require('./adolescent/decisions/adolescentProgramSummary'),
    require('./adolescent/formFilters/AnnualVisitDecisions')
);
