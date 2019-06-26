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

@SickleCellViewFilter("39dd9bd1-63ae-44c7-9184-9bdaf261a8da", "Sickle Cell Followup View Filter", 100.0, {})
class SickleCellFollowupViewFilterHandlerSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new SickleCellFollowupViewFilterHandlerSR(), programEncounter, formElementGroup, today);
    }

    @WithName("Have you visited hospital?")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether referred to hospital").is.yes;
    }

    @WithName("Do you have FA tablets?")
    @WithStatusBuilder
    areYouTakingItRegularly([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Have FA Tablets").is.yes;
    }

    @WithName("What did you do for your problem?")
    @WithStatusBuilder
    whatDidYouDoForYourPain([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Suffered from any pain or problem in last one month").is.yes;
    }
}

module.exports = {SickleCellFollowupViewFilterHandlerSR};

