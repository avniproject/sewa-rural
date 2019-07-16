import lib from "../../lib";

const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";

const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");
export default class AnnualVisitHandler {
    @WithName("Father's occupation")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Parents' life status")
            .containsAnyAnswerConceptName("Both Alive", "Only Father Alive");
        return statusBuilder.build();
    }

    @WithName("Mother's occupation")
    @WithStatusBuilder
    abc2([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Parents' life status")
            .containsAnyAnswerConceptName("Both Alive", "Only Mother Alive");
        return statusBuilder.build();
    }

    @WithName("If school dropped out, After which standard left the school")
    @WithStatusBuilder
    abc3([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("School going")
            .containsAnswerConceptName("Dropped Out");
        return statusBuilder.build();
    }

    @WithName("In which standard he/she is studying?")
    @WithStatusBuilder
    abc4([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("School going")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Name of school")
    @WithStatusBuilder
    abc5([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("School going")
            .containsAnswerConceptName("Yes");
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

    @WithName("Sickling Test Status")
    @WithStatusBuilder
    abc71([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEntireEnrolment("Sickling Test Status")
            .not.defined.or.when.valueInEntireEnrolment("Sickling Test Status")
            .containsAnswerConceptName("Not Done");
        return statusBuilder.build();
    }

    @WithName("Sickling Test Result")
    @WithStatusBuilder
    abc7([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickling Test Status")
            .containsAnswerConceptName("Done");
        return statusBuilder.build();
    }

    @WithName("From Where?")
    @WithStatusBuilder
    abc8([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Menstruation started")
    @WithStatusBuilder
    abc9([programEncounter], statusBuilder) {
        statusBuilder.show().when.female;
        return statusBuilder.build();
    }

    @WithName("MHM Kit received?")
    @WithStatusBuilder
    abc91([programEncounter], statusBuilder) {
        statusBuilder.show().when.female;
        return statusBuilder.build();
    }

    @WithName("If Yes, Age at Menarche")
    @WithStatusBuilder
    abc10([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Absorbent material used")
    @WithStatusBuilder
    abc11([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Menstrual disorders")
    @WithStatusBuilder
    abc12([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Are you able to do daily routine work during menstruation?")
    @WithStatusBuilder
    abc13([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Any treatment taken")
    @WithStatusBuilder
    abc14([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");
        return statusBuilder.build();
    }

    @WithName("Does she remain absent during menstruation?")
    @WithStatusBuilder
    abc15([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("School going")
            .containsAnswerConceptName("Yes")
            .and.when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");
        return statusBuilder.build();
    }

    @WithName("Reason for remaining absent during menstruation")
    @WithStatusBuilder
    abc16([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("If yes, how many days?")
    @WithStatusBuilder
    abc161([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("MHM Kit used?")
    @WithStatusBuilder
    abc17([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.female.and.valueInEncounter("MHM Kit received")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Do you perform unprotected sexual intercourse?")
    @WithStatusBuilder
    abc18([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sexually active")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Do you have multiple sexual partners?")
    @WithStatusBuilder
    abc19([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sexually active")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Are you satisfied with the counseling service provided through helpline?")
    @WithStatusBuilder
    abc20([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Used Mitra Helpline")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Other conditions (please specify)")
    @WithStatusBuilder
    abc21([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Is there any other condition you want to mention about him/her?")
            .containsAnswerConceptName("Other");

        return statusBuilder.build();
    }

    @WithName("Other sickness (please specify)")
    @WithStatusBuilder
    abc22([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Sickness in last 1 month")
            .containsAnswerConceptName("Other");

        return statusBuilder.build();
    }

    @WithName("Iron tablets consumed in last month")
    @WithStatusBuilder
    abc33([programEncounter], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }
}
