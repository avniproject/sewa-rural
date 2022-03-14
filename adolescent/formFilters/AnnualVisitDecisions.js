const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";
import {complicationsBuilder as ComplicationsBuilder} from "rules-config";

const Decision = RuleFactory("35e54f14-3a23-45a3-b90e-5383fa026ffd", "Decision");

@Decision("ee261afb-73ca-4ea2-8838-90dbd34a541e", "Annual Visit Decisions", 100.0, {})
export class AnnualVisitDecisionHandler {
    static referToHospitalDecisions(programEncounter) {
        const complicationsBuilder = new ComplicationsBuilder({
            programEncounter: programEncounter,
            complicationsConcept: "Refer to hospital immediately for"
        });

        complicationsBuilder
            .addComplication("Severe Anemia")
            .when.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(7);

        complicationsBuilder
            .addComplication("Sickle cell disease")
            .when.valueInEncounter("Sickling Test Result")
            .containsAnswerConceptName("Disease");

        complicationsBuilder
            .addComplication("Medical Problems")
            .when.valueInEncounter("Is there any physical defect?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("swelling at lower back")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is her nails/tongue pale?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is there any problem in leg bone?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is there a swelling over throat?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Does she have difficulty in breathing while playing?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter(" Are there dental carries?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is there a white patch in her eyes?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Does she have impaired vision?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is there pus coming from ear?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Does she have impaired hearing?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Does she have skin problems?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Has she ever suffered from convulsions?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is her behavior different from others?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is she slower than others in learning and understanding new things?")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Is there any developmental delay or disability seen?")
            .containsAnswerConceptName("Yes");

        complicationsBuilder
            .addComplication("Menstrual disorders")
            .when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem")
            .or.when.valueInEncounter("able to do daily routine work during menstruation")
            .containsAnswerConceptName("No")
            .or.when.valueInEncounter("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");

        complicationsBuilder
            .addComplication("Additional Medical Problems")
            .when.valueInEncounter("Is there any other condition you want to mention about him/her?")
            .containsAnswerConceptNameOtherThan("No problem");
        complicationsBuilder
            .addComplication("Addiction (Self)")
            .when.valueInEncounter("Addiction Details")
            .containsAnswerConceptNameOtherThan("No Addiction");

        complicationsBuilder
            .addComplication("Sexual Problems")
            .when.valueInEncounter("Burning Micturition")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Ulcer over genitalia")
            .containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Yellowish discharge from Vagina / penis")
            .containsAnswerConceptName("Yes");

        return complicationsBuilder.getComplications();
    }

    static vulnerabilityDecisions(programEncounter) {
        const complicationsBuilder = new ComplicationsBuilder({
            programEncounter: programEncounter,
            complicationsConcept: "Adolescent Vulnerabilities"
        });

        complicationsBuilder
            .addComplication("Severe Anemia")
            .when.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(7);

        complicationsBuilder
            .addComplication("Moderate Anemia")
            .when.valueInEncounter("Hb")
            .is.greaterThanOrEqualTo(7.1)
            .and.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(10);

        complicationsBuilder
            .addComplication("Severe malnourishment")
            .when.valueInEncounter("BMI")
            .lessThanOrEqualTo(14.5);

        complicationsBuilder
            .addComplication("School dropout")
            .when.valueInEncounter("School going")
            .containsAnyAnswerConceptName("Dropped Out");

        complicationsBuilder
            .addComplication("Chronic Sickness")
            .when.valueInEncounter("Is there any other condition you want to mention about him/her?")
            .containsAnswerConceptNameOtherThan("No problem");

        complicationsBuilder
            .addComplication("Sickle cell disease")
            .when.valueInEncounter("Sickling Test Result")
            .containsAnswerConceptName("Disease");

        complicationsBuilder
            .addComplication("Menstrual disorders")
            .when.valueInEncounter("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem");

        complicationsBuilder
            .addComplication("Addiction (Self)")
            .when.valueInEncounter("Addiction Details")
            .containsAnswerConceptNameOtherThan("No Addiction");

        return complicationsBuilder.getComplications();
    }

    static anemiaStatusDecisions(programEncounter) {
        const complicationsBuilder = new ComplicationsBuilder({
            programEncounter: programEncounter,
            complicationsConcept: "Anemia Status"
        });

        complicationsBuilder
            .addComplication("Severe")
            .when.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(7);

        complicationsBuilder
            .addComplication("Moderate")
            .when.valueInEncounter("Hb")
            .is.greaterThanOrEqualTo(7.1)
            .and.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(10);

        complicationsBuilder
            .addComplication("Mild")
            .when.valueInEncounter("Hb")
            .is.greaterThanOrEqualTo(10.1)
            .and.valueInEncounter("Hb")
            .is.lessThanOrEqualTo(11.9);

        complicationsBuilder
            .addComplication("Normal")
            .when.valueInEncounter("Hb")
            .is.greaterThanOrEqualTo(12);

        return complicationsBuilder.getComplications();
    }

    static latestStandardDecisions(programEncounter) {
       const standard = programEncounter.programEnrolment.findLatestObservationFromEncounters("Standard",programEncounter);

        if(!_.isEmpty(standard)){
            return {
                name:"Latest Standard",
                value: standard.getReadableValue()
            }
        }

    }


    static exec(programEncounter, decisions, context, today) {
        decisions.encounterDecisions.push(AnnualVisitDecisionHandler.referToHospitalDecisions(programEncounter));
        decisions.encounterDecisions.push(AnnualVisitDecisionHandler.vulnerabilityDecisions(programEncounter));
        decisions.encounterDecisions.push(AnnualVisitDecisionHandler.anemiaStatusDecisions(programEncounter));
        decisions.enrolmentDecisions.push(AnnualVisitDecisionHandler.latestStandardDecisions(programEncounter));

        return decisions;

    }
}
