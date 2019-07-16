const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";

const MenstrualDisorderViewFilter = RuleFactory("bb9bf699-92f3-4646-9cf4-f1792fa2c3a6", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");

@MenstrualDisorderViewFilter("9c6212ac-c81a-4153-94a1-70f58e86a70b", "Menstrual Disorder View Filter", 100.0, {})
class MenstrualDisorderHandlerSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper.getFormElementsStatusesWithoutDefaults(
            new MenstrualDisorderHandlerSR(),
            programEncounter,
            formElementGroup,
            today
        );
    }

    @WithName("Whether visited hospital")
    @WithStatusBuilder
    xyz1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether referred to hospital").is.yes;
    }

    @WithName("Have you taken treatment?")
    @WithStatusBuilder
    xyz2([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether visited hospital").is.yes;
    }

    @WithName("SR Is your complaint resolved counselling")
    @WithStatusBuilder
    xyz3([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Complaint resolved").is.no;
    }
}

module.exports = {MenstrualDisorderHandlerSR};
