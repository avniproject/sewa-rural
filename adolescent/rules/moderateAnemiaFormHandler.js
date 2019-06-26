const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName,
} from 'rules-config/rules';
import lib from '../../lib';

const ModerateAnemiaViewFilter = RuleFactory("038e6819-2a41-44f5-8473-eda5eeb37806", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');
const ModerateAnemiaValidations = RuleFactory('038e6819-2a41-44f5-8473-eda5eeb37806', 'Validation');

@ModerateAnemiaViewFilter("d4aba1d9-146e-484e-af90-7380e88a4776", "Moderate Anemia View Filter", 100.0, {})
class ModerateAnemiaViewFilterHandlerSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new ModerateAnemiaViewFilterHandlerSR(), programEncounter, formElementGroup, today);
    }

    @WithName("Do you get food from Anganwadi?")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().whenItem(statusBuilder.context.programEncounter.programEnrolment.individual.isFemale()).is.truthy;
    }

    @WithName("Whether taking B12 folic acid tablets")
    abc2(programEncounter, formElement) {
        const annualVisitEncounters = programEncounter.programEnrolment.getEncountersOfType("Annual Visit");
        const sicklingTestResultObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment('Sickling Test Result', annualVisitEncounters);
        return new FormElementStatus(formElement.uuid, sicklingTestResultObs && sicklingTestResultObs.getReadableValue() !== ('Negative' || 'Trait') || true);
    }
}

@ModerateAnemiaValidations("976e614d-a85e-4aa6-829a-fe6fbc29befa", "Moderate Anemia Validations", 100.0)
class ModerateAnemiaValidationsSR {
    validate(programEncounter) {
        const validationResults = [];
        const ifaTabletsConsumed = programEncounter.getObservationReadableValue("Iron tablets consumed in last week");
        if (ifaTabletsConsumed && ifaTabletsConsumed.toString().length > 2) {
            validationResults.push(lib.C.createValidationError('IronTabletsMoreThanTwoDigitNotAllowed'));
        }
        return validationResults;
    }

    static exec(programEncounter, validationErrors) {
        return new ModerateAnemiaValidationsSR().validate(programEncounter);
    }
}

module.exports = {ModerateAnemiaViewFilterHandlerSR, ModerateAnemiaValidationsSR};
