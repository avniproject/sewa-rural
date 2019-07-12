const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName,
} from 'rules-config/rules';
import {complicationsBuilder as ComplicationsBuilder} from "rules-config";

const Decision = RuleFactory('35e54f14-3a23-45a3-b90e-5383fa026ffd', 'Decision');


@Decision("ee261afb-73ca-4ea2-8838-90dbd34a541e", "Annual Visit Decisions", 100.0, {})
export class AnnualVisitDecisionHandler {

    static referrals(programEncounter) {
        const referralAdvice = new ComplicationsBuilder({
            programEnrolment: programEncounter.programEnrolment,
            programEncounter: programEncounter,
            complicationsConcept: 'Refer to hospital immediately for'
        });

        if (!programEncounter) return referralAdvice.getComplications();

        referralAdvice.addComplication("Severe Anemia").when.valueInEncounter("Hb").is.lessThanOrEqualTo(7);
        referralAdvice.addComplication("Sickle cell disease").when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Disease");

        referralAdvice.addComplication("Medical Problems").when.valueInEncounter("Is there any physical defect?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("swelling at lower back").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is her nails/tongue pale?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is there any problem in leg bone?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is there a swelling over throat?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Does she have difficulty in breathing while playing?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter(" Are there dental carries?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is there a white patch in her eyes?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Does she have impaired vision?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is there pus coming from ear?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Does she have impaired hearing?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Does she have skin problems?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Has she ever suffered from convulsions?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is her behavior different from others?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is she slower than others in learning and understanding new things?").containsAnswerConceptName("Yes")
        .or.when.valueInEncounter("Is there any developmental delay or disability seen?").containsAnswerConceptName("Yes");

        referralAdvice.addComplication("Menstrual disorders").when.valueInEncounter("Menstrual disorders").containsAnswerConceptNameOtherThan("No problem")
            .or.when.valueInEncounter("able to do daily routine work during menstruation").containsAnswerConceptName("No")
            .or.when.valueInEncounter("Does she remain absent during menstruation?").containsAnswerConceptName("Yes");

        referralAdvice.addComplication("Additional Medical Problems").when.valueInEncounter("Is there any other condition you want to mention about him/her?").containsAnswerConceptNameOtherThan("No problem");
        referralAdvice.addComplication("Addiction (Self)").when.valueInEncounter("Addiction Details").containsAnswerConceptNameOtherThan("No Addiction");

        referralAdvice.addComplication("Sexual Problems").when.valueInEncounter("Burning Micturition").containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Ulcer over genitalia").containsAnswerConceptName("Yes")
            .or.when.valueInEncounter("Yellowish discharge from Vagina / penis").containsAnswerConceptName("Yes");

        return referralAdvice.getComplications();
    }

    static exec(programEncounter, decisions, context, today) {
        const recommendation = AnnualVisitDecisionHandler.referrals(programEncounter);
        decisions['encounterDecisions'] = decisions['encounterDecisions'] || [];
        decisions['encounterDecisions'] = decisions['encounterDecisions'].filter((d) => d.name !== recommendation.name).concat(recommendation);
        return decisions;
    }

}
