const _ = require("lodash");
import {StatusBuilderAnnotationFactory, WithName} from "rules-config/rules";

const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");
export default class QuarterlyVisitHandler {
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
        statusBuilder
            .show()
            .when.valueInEntireEnrolment("Sickling Test Status")
            .not.defined.or.when.valueInEntireEnrolment("Sickling Test Status")
            .containsAnswerConceptName("Not Done");
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

    @WithName("From Where?")
    @WithStatusBuilder
    abc8([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Iron tablets received")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Menstrutation started")
    @WithStatusBuilder
    abc9([], statusBuilder) {
        statusBuilder.show().whenItem(statusBuilder.context.programEncounter.programEnrolment.individual.isFemale()).is
            .truthy;
        return statusBuilder.build();
    }

    @WithName("MHM Kit received?")
    @WithStatusBuilder
    abc91([], statusBuilder) {
        statusBuilder.show().whenItem(statusBuilder.context.programEncounter.programEnrolment.individual.isFemale()).is
            .truthy;
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
            .when.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Menstrual disorders")
    @WithStatusBuilder
    abc12([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Menstruation started")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    @WithName("Are you able to do daily routine work during menstruation?")
    @WithStatusBuilder
    abc13([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Menstruation started")
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

    @WithName("MHM Kit used?")
    @WithStatusBuilder
    abc17([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("MHM Kit received")
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
}
