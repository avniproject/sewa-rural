const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";

const ChronicSicknessViewFilter = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");

@ChronicSicknessViewFilter("9802b91b-1d1c-4717-ba7c-7c7bb84d100e", "Chronic Sickness View Filter", 100.0, {})
class ChronicSicknessViewFilterSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper.getFormElementsStatusesWithoutDefaults(
            new ChronicSicknessViewFilterSR(),
            programEncounter,
            formElementGroup,
            today
        );
    }

    @WithName("Whether visited hospital")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether referred to hospital").is.yes;
    }

    @WithName("Are you taking treatment regularly?")
    @WithStatusBuilder
    abc2([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether visited hospital").is.yes;
    }

    @WithName("If not cured refer to hospital again")
    @WithStatusBuilder
    abc3([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether condition cured").is.no;
    }

    @WithName("If not cured, what is the reason?")
    @WithStatusBuilder
    abc3551([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Cured").is.no;
    }

    @WithName("Home Visit Done?")
    homeVisitDone(programEncounter, formElement) {
        const registeredAddress = programEncounter.programEnrolment.individual.lowestAddressLevel.type;
        return new FormElementStatus(formElement.uuid, registeredAddress !== 'Boarding');
    }


}

module.exports = {ChronicSicknessViewFilterSR};
