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
        statusBuilder.show().when.valueInEncounter("Have you been referred?").is.yes;
    }

    @WithName("Are you taking it regularly?")
    @WithStatusBuilder
    areYouTakingItRegularly([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Do you have FA tablets?").is.yes;
    }

    @WithName("What did you do for your problem?")
    @WithStatusBuilder
    whatDidYouDoForYourPain([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("In last one month have you suffered from any pain or problem?").is.yes;
    }
}

module.exports = {SickleCellFollowupViewFilterHandlerSR};

