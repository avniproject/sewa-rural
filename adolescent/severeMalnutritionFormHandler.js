const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName,
} from 'rules-config/rules';
import lib from '../lib';

const SeverMalnutritionViewFilter = RuleFactory('f7b7d2ff-10eb-47a4-866b-b368969f9a7f', "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');

@SeverMalnutritionViewFilter('4e086dea-1eb9-4dfb-98a3-7eb003eb360e', 'Sever Malnutrition View Filter', 100.0, {})
class SeverMalnutritionViewFilterSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new SeverMalnutritionViewFilterSR(), programEncounter, formElementGroup, today);
    }

    @WithName("Have you visited hospital?")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Have you been referred?").is.yes;
    }


    @WithName("Are you taking more food than previous, as you are malnourished?")
    abc2(programEncounter, formElement) {
        const annualVisitEncounters = programEncounter.programEnrolment.getEncountersOfType("Annual Visit");
        const heightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment('Height', annualVisitEncounters);
        const weightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment('Weight', annualVisitEncounters);
        const isMalnourished = heightObs && weightObs && lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 18.5 || false;
        return new FormElementStatus(formElement.uuid, isMalnourished);
    }
}


module.exports = {SeverMalnutritionViewFilterSR};
