const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";
import lib from "../../lib";

const SevereAnemiaViewFilter = RuleFactory("12cd243c-851c-4fd1-bc28-ab0b0141c76f", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");
const SevereAnemiaValidations = RuleFactory("12cd243c-851c-4fd1-bc28-ab0b0141c76f", "Validation");

@SevereAnemiaViewFilter("f1d1583f-f603-4614-9348-fe309bb8c750", "Severe Anemia View Filter", 100.0, {})
class SevereAnemiaViewFilterHandlerSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper.getFormElementsStatusesWithoutDefaults(
            new SevereAnemiaViewFilterHandlerSR(),
            programEncounter,
            formElementGroup,
            today
        );
    }

    @WithName("Whether visited hospital")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Have been referred to hospital and referral slip given").is.yes;
    }

    @WithName("Which treatment have been given?")
    @WithStatusBuilder
    abc2([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether visited hospital").is.yes;
    }

    @WithName("Do you get food from Anganwadi?")
    @WithStatusBuilder
    abc3([programEncounter], statusBuilder) {
        statusBuilder.show().whenItem(statusBuilder.context.programEncounter.programEnrolment.individual.isFemale()).is
            .truthy;
    }

    @WithName("Any other medicine if given, have you taken that?")
    @WithStatusBuilder
    abc4([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Have difficulty in breathing").is.yes;
    }

    @WithName("Whether taking B12 folic acid tablets")
    abc5(programEncounter, formElement) {
        const annualVisitEncounters = programEncounter.programEnrolment.getEncountersOfType("Annual Visit");
        const sicklingTestResultObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment(
            "Sickling Test Result",
            annualVisitEncounters
        );
        return new FormElementStatus(
            formElement.uuid,
            (sicklingTestResultObs && sicklingTestResultObs.getReadableValue() !== ("Negative" || "Trait")) || true
        );
    }

    @WithName("How many tablets consumed in last month?")
    @WithStatusBuilder
    abc12([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Whether taking B12 folic acid tablets").is.yes;
    }
    @WithName("Specify Other Treatment")
    @WithStatusBuilder
    abc13([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Treatment given")
            .containsAnswerConceptName("Other")
    }

    @WithName("Home Visit Done?")
    homeVisitDone(programEncounter, formElement) {
        const registeredAddress = programEncounter.programEnrolment.individual.lowestAddressLevel.type;
        return new FormElementStatus(formElement.uuid, registeredAddress !== 'Boarding');
    }


}

@SevereAnemiaValidations("2e7149da-220d-4fa7-8dba-e7ce66f3240b", "Severe Anemia Validations", 100.0)
class SevereAnemiaValidationsSR {
    validate(programEncounter) {
        const validationResults = [];
        const ifaTabletsConsumed = programEncounter.getObservationReadableValue("Iron tablets consumed in the last month");
        if (ifaTabletsConsumed && ifaTabletsConsumed.toString().length > 2) {
            validationResults.push(lib.C.createValidationError("IronTabletsMoreThanTwoDigitNotAllowed"));
        }
        return validationResults;
    }

    static exec(programEncounter, validationErrors) {
        return new SevereAnemiaValidationsSR().validate(programEncounter);
    }
}

module.exports = {SevereAnemiaViewFilterHandlerSR, SevereAnemiaValidationsSR};
