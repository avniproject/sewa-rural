const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName,
} from 'rules-config/rules';

const SickleCellViewFilter = RuleFactory("e728eab9-af8b-46ea-9d5f-f1a9f8727567", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');

@SickleCellViewFilter("0485b65e-772b-4d1f-8906-c7203510639b", "Sickle Cell Followup View Filter", 100.0, {})
class SickleCellFollowupViewFilterHandlerSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new SickleCellFollowupViewFilterHandlerSR(), programEncounter, formElementGroup, today);
    }

    @WithName("Have you visited hospital?")
    @WithStatusBuilder
    haveYouVisitedHospital([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Do you know that you have a sickle cell disease?").is.yes;
    }

    @WithName("What did you do for your problem?")
    @WithStatusBuilder
    whatDidYouDoForYourPain([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("In last one month have  you sufferred  from any pain or problem?").is.yes;
    }
}

module.exports = {SickleCellFollowupViewFilterHandlerSR};

