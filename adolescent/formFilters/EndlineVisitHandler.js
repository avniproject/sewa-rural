import {
    StatusBuilderAnnotationFactory,
    RuleFactory,
    FormElementsStatusHelper,
    WithName
} from 'rules-config/rules';
import lib from "../../lib";

const _ = require("lodash");

const EndlineVisitViewFilters = RuleFactory("b9d58493-7d08-49c9-bdc7-f1864cb97819", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");

@EndlineVisitViewFilters("9799ab25-47b5-420d-8812-5bcbdde1e844", "Endline Visit Filter", 100, {})
class EndlineVisitHandler {

    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new EndlineVisitHandler(), programEncounter, formElementGroup, today);
    }


    @WithName("Are you present in the school?")
    @WithStatusBuilder
    abc0([], statusBuilder) {
        statusBuilder.show().when.addressType.not.equals("Village");
    }

    @WithName("If No, from how many days?")
    @WithStatusBuilder
    abc1([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Present in school")
            .containsAnswerConceptName("No");
    }

    @WithName("Sickling Test Status")
    @WithStatusBuilder
    abc71([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Sickling Test Status").is.defined
            .or.when.latestValueInPreviousEncounters("Sickling Test Status").is.notDefined
            .or.when.valueInEntireEnrolment("Sickling Test Result").is.notDefined;
    }

    @WithName("Sickling Test Result")
    @WithStatusBuilder
    sicklingTestResult([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickling Test Status")
            .containsAnswerConceptName("Done");
    }

    @WithName("Hemoglobin")
    @WithStatusBuilder
    abc6([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Hemoglobin Test")
            .containsAnswerConceptName("Done");
    }

    @WithName("From Where?")
    @WithStatusBuilder
    abc8([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes");
    }


    @WithName("Iron tablets consumed in last 3 months")
    @WithStatusBuilder
    abc81([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Menstruation started")
    @WithStatusBuilder
    abc9([], statusBuilder) {
        statusBuilder.show().when.female
            .and.when.latestValueInPreviousEncounters("Menstruation started").not.containsAnswerConceptName("Yes");
    }

    @WithName("MHM Kit received?")
    @WithStatusBuilder
    abc91([], statusBuilder) {
        statusBuilder.show().when.female;
    }

    @WithName("If Yes, Age at Menarche")
    @WithStatusBuilder
    abc10([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Absorbent material used")
    @WithStatusBuilder
    abc11([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Menstrual disorders")
    @WithStatusBuilder
    abc12([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Are you able to do daily routine work during menstruation?")
    @WithStatusBuilder
    abc13([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Any treatment taken")
    @WithStatusBuilder
    abc14([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");
    }

    @WithName("Does she remain absent during menstruation?")
    @WithStatusBuilder
    abc15([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("School going")
            .containsAnswerConceptName("Yes")
            .and.whenItem(statusBuilder.context.programEncounter.programEnrolment.individual.isFemale()).is.truthy;
        statusBuilder
            .show()
            .when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");
    }

    @WithName("Reason for remaining absent during mensturation")
    @WithStatusBuilder
    abc16([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");
    }

    @WithName("If yes, how many days?")
    @WithStatusBuilder
    abc161([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Other Sickness")
    @WithStatusBuilder
    abc19([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickness in last 3 month")
            .containsAnswerConceptName("Other");
    }

    @WithName("MHM Kit used?")
    @WithStatusBuilder
    abc17([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("MHM Kit received")
            .containsAnswerConceptName("Yes")
            .and.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Are you satisfied with the counseling service provided through helpline?")
    @WithStatusBuilder
    abc20([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Used Mitra Helpline")
            .containsAnswerConceptName("Yes");
    }

    @WithName("Counselling checklist for Sickle Cell Anemia(Trait)")
    @WithStatusBuilder
    xyz1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Trait");
    }

    @WithName("MenstrualDisorderCounselling for SR")
    @WithStatusBuilder
    xyz2([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when
            .female
            .and.when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");
    }
    @WithName("BMI")
    @WithStatusBuilder
    bmi([programEncounter], statusBuilder) {
        let weight = programEncounter.getObservationValue("Weight");
        let height = programEncounter.getObservationValue("Height");

        let bmi = "";
        if (_.isNumber(height) && _.isNumber(weight)) {
            bmi = lib.C.calculateBMI(weight, height);
        }

        let formElmentStatus = statusBuilder.build();
        formElmentStatus.value = bmi;
        return formElmentStatus;
    }
}

module.exports = {EndlineVisitHandler};