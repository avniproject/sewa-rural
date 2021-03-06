const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";

const SickleCellViewFilter = RuleFactory("e728eab9-af8b-46ea-9d5f-f1a9f8727567", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");

@SickleCellViewFilter("39dd9bd1-63ae-44c7-9184-9bdaf261a8da", "Sickle Cell Followup View Filter", 100.0, {})
class SickleCellFollowupViewFilterHandlerSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper.getFormElementsStatusesWithoutDefaults(
            new SickleCellFollowupViewFilterHandlerSR(),
            programEncounter,
            formElementGroup,
            today
        );
    }

    @WithName("Have you visited hospital?")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether referred to hospital").is.yes;
    }

    @WithName("Are you taking it regularly?")
    @WithStatusBuilder
    areYouTakingItRegularly([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Have FA Tablets").is.yes;
    }

    @WithName("What did you do for your problem?")
    @WithStatusBuilder
    whatDidYouDoForYourPain([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Suffered from any pain or problem in last one month").is.yes;
    }

    @WithName("Please specify Other?")
    @WithStatusBuilder
    pl1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Action taken by yourself for your problem")
            .containsAnswerConceptName("Other")
    }

 @WithName("Specify Other Symptoms")
    @WithStatusBuilder
    pl2([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Symptoms of sickle cell disease")
            .containsAnswerConceptName("Other")
    }

    @WithName("Home Visit Done?")
    homeVisitDone(programEncounter, formElement) {
        const registeredAddress = programEncounter.programEnrolment.individual.lowestAddressLevel.type;
        return new FormElementStatus(formElement.uuid, registeredAddress !== 'Boarding');
    }
}

module.exports = {SickleCellFollowupViewFilterHandlerSR};
