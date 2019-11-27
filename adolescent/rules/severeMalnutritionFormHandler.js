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

const SeverMalnutritionViewFilter = RuleFactory("f7b7d2ff-10eb-47a4-866b-b368969f9a7f", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");

@SeverMalnutritionViewFilter("4e086dea-1eb9-4dfb-98a3-7eb003eb360e", "Sever Malnutrition View Filter", 100.0, {})
class SeverMalnutritionViewFilterSR {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper.getFormElementsStatusesWithoutDefaults(
            new SeverMalnutritionViewFilterSR(),
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

    @WithName("Specify Other?")
    @WithStatusBuilder
    abc17([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Suffering from any other medical problem")
        .containsAnyAnswerConceptName("Other")
    }
    @WithName("please specify other")
    @WithStatusBuilder
    abc18([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Problems if your weight is less")
        .containsAnyAnswerConceptName("Other")
    }


    @WithName("Are you taking more food than previous, as you are malnourished?")
    abc2(programEncounter, formElement) {
        const annualVisitEncounters = programEncounter.programEnrolment.getEncountersOfType("Annual Visit");
        const heightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment(
            "Height",
            annualVisitEncounters
        );
        const weightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment(
            "Weight",
            annualVisitEncounters
        );
        const isMalnourished =
            (heightObs &&
                weightObs &&
                lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 18.5) ||
            false;
        return new FormElementStatus(formElement.uuid, isMalnourished);
    }

    @WithName("Home Visit Done?")
    homeVisitDone(programEncounter, formElement) {
        const registeredAddress = programEncounter.programEnrolment.individual.lowestAddressLevel.type;
        return new FormElementStatus(formElement.uuid, registeredAddress !== 'Boarding');
    }

}

module.exports = {SeverMalnutritionViewFilterSR};
