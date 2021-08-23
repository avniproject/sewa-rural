import lib from "../../lib";

const _ = require("lodash");
import {StatusBuilderAnnotationFactory, WithName} from "rules-config/rules";

const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");
export default class QuarterlyVisitHandler {
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
        return statusBuilder.build();
    }

    @WithName("Sickling Test Status")
    @WithStatusBuilder
    abc71([], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Sickling Test Status").is.defined
            .or.when.latestValueInPreviousEncounters("Sickling Test Status").is.notDefined
            .or.when.valueInEntireEnrolment("Sickling Test Result").is.notDefined;
        return statusBuilder.build();
    }

    @WithName("Sickling Test Result")
    @WithStatusBuilder
    sicklingTestResult([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickling Test Status")
            .containsAnswerConceptName("Done");
        return statusBuilder.build();
    }

    @WithName("Hemoglobin")
    @WithStatusBuilder
    abc6([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Hemoglobin Test")
            .containsAnswerConceptName("Done");
        return statusBuilder.build();
    }

    @WithName("From Where?")
    @WithStatusBuilder
    abc8([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }


    @WithName("Iron tablets consumed in last 3 months")
    @WithStatusBuilder
    abc81([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes")
            .and.when.valueInEncounter("Hb")
            .is.greaterThan(10);
        return statusBuilder.build();
    }

    @WithName("How many IFA received in last 3 months?")
    @WithStatusBuilder
    abc811([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes")
            .and.when.valueInEncounter("Hb")
            .is.greaterThan(10);
            return statusBuilder.build();
    }

    @WithName("Menstruation started")
    @WithStatusBuilder
    abc9([], statusBuilder) {
        statusBuilder.show().when.female
            .and.when.latestValueInPreviousEncounters("Menstruation started").not.containsAnswerConceptName("Yes");

        return statusBuilder.build();
    }

    @WithName("MHM Kit received?")
    @WithStatusBuilder
    abc91([], statusBuilder) {
        statusBuilder.show().when.female;
        return statusBuilder.build();
    }

    @WithName("If Yes, Age at Menarche")
    @WithStatusBuilder
    abc10([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Absorbent material used")
    @WithStatusBuilder
    abc11([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
        statusBuilder.skipAnswers("Kit pad");
        return statusBuilder.build();
    }

    @WithName("Menstrual disorders")
    @WithStatusBuilder
    abc12([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Are you able to do daily routine work during menstruation?")
    @WithStatusBuilder
    abc13([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInAllEncounters("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Any treatment taken")
    @WithStatusBuilder
    abc14([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");
        return statusBuilder.build();
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
        return statusBuilder.build();
    }

    @WithName("Reason for remaining absent during mensturation")
    @WithStatusBuilder
    abc16([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("If yes, how many days?")
    @WithStatusBuilder
    abc161([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Other Sickness")
    @WithStatusBuilder
    abc19([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickness in last 3 month")
            .containsAnswerConceptName("Other");
        return statusBuilder.build();
    }

    @WithName("Hospitalized in last 3 months")
    @WithStatusBuilder
    abc222([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickness in last 3 month")
            .containsAnswerConceptNameOtherThan("No sickness");
        return statusBuilder.build();
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
        return statusBuilder.build();
    }

    @WithName("Are you satisfied with the counseling service provided through helpline?")
    @WithStatusBuilder
    abc20([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Used Mitra Helpline")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Counselling checklist for Sickle Cell Anemia(Trait)")
    @WithStatusBuilder
    xyz1([programEncounter], statusBuilder){
        statusBuilder.show().when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Trait");
        return statusBuilder.build();
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
        return statusBuilder.build();
    }


    @WithName("Counselling checklist for Menstrual Disorder")
    @WithStatusBuilder
    menstrualDisorderCounselling([programEncounter], statusBuilder) {
        statusBuilder.show().when
            .valueInEncounter("Are you able to do daily routine work during menstruation?")
            .is.no
            .or
            .valueInEncounter("Does she remain absent during menstruation?")
            .is.yes;
        return statusBuilder.build();
    }

    @WithName("Counselling checklist for Addiction")
    @WithStatusBuilder
    addictionCounselling([programEncounter], statusBuilder) {
        statusBuilder.show().when
            .valueInEncounter("Addiction Details")
            .containsAnyAnswerConceptName("Alcohol", "Tobacco", "Both");
        return statusBuilder.build();
    }

    @WithName("Counselling checklist for Sickle Cell Anemia(Disease)")
    @WithStatusBuilder
    sickleCellDiseaseCounselling([programEncounter], statusBuilder) {
        statusBuilder.show().when
            .valueInEncounter("Sickling Test Result")
            .containsAnswerConceptName("Disease");
        return statusBuilder.build();
    }

    @WithName("Counselling checklist for Severe Anemia")
    @WithStatusBuilder
    severeAnemiaCounselling([programEncounter], statusBuilder) {
        statusBuilder.show().when
            .valueInEncounter("Hb")
            .is.lessThanOrEqualTo(7);
        return statusBuilder.build();
    }

    @WithName("SR ModerateAnemiaCounselling")
    @WithStatusBuilder
    moderateAnemiaCounselling([programEncounter], statusBuilder) {
        statusBuilder.show().when
            .valueInEncounter("Hb")
            .is.greaterThanOrEqualTo(7.1)
            .and.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(10);
        return statusBuilder.build();
    }

    @WithName("Counselling checklist for Malnutrition")
    @WithStatusBuilder
    malnutritionCounselling([programEncounter], statusBuilder) {
        const heightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment(
            "Height",
            programEncounter
        );
        const weightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment(
            "Weight",
            programEncounter
        );
        const isUnderweight =
            (heightObs &&
                weightObs &&
                lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 18.5) ||
            false;
        statusBuilder.show()
            .whenItem(isUnderweight).is
            .truthy;
        return statusBuilder.build();
    }

    @WithName("Counselling checklist for dropout")
    @WithStatusBuilder
    dropoutCounselling([programEncounter], statusBuilder) {
        statusBuilder.show().when
            .valueInEncounter("School going")
            .containsAnswerConceptName("Dropped Out");
        return statusBuilder.build();
    }

    // @WithName("ChronicSicknessCounselling for SR")
    // @WithStatusBuilder
    // chronicSicknessCounselling([programEncounter], statusBuilder) {
    //     statusBuilder.show().when
    //         .valueInEncounter("Is there any other condition you want to mention about him/her?")
    //         .containsAnswerConceptNameOtherThan("No problem");
    //     return statusBuilder.build();
    // }
}
