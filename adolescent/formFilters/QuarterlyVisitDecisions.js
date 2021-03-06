import {AnnualVisitDecisionHandler} from "./AnnualVisitDecisions";

const _ = require("lodash");
import {RuleFactory} from "rules-config/rules";
import {complicationsBuilder as ComplicationsBuilder} from "rules-config";

const Decision = RuleFactory("a8c1f2a0-f4e0-4190-b0c3-bd81f21bef6c", "Decision");

@Decision("e0190eb2-df3c-48ed-8f47-4604da4ec9c2", "Quarterly Visit Decisions", 100.0, {})
export class QuarterlyVisitDecisionHandler {
    static referrals(programEncounter) {
        const referralAdvice = new ComplicationsBuilder({
            programEnrolment: programEncounter.programEnrolment,
            programEncounter: programEncounter,
            complicationsConcept: "Refer to hospital for"
        });

        referralAdvice
            .addComplication("Sickle cell disease")
            .when.latestValueInAllEncounters("Sickling Test Result")
            .containsAnswerConceptName("Disease");

        referralAdvice
            .addComplication("Menstrual disorders")
            .when.latestValueInAllEncounters("Menstrual disorders")
            .containsAnswerConceptNameOtherThan("No problem")
            .or.when.latestValueInAllEncounters("able to do daily routine work during menstruation")
            .containsAnswerConceptName("No")
            .or.when.latestValueInAllEncounters("Does she remain absent during menstruation?")
            .containsAnswerConceptName("Yes");

        referralAdvice
            .addComplication("Addiction (Self)")
            .when.latestValueInAllEncounters("Addiction Details")
            .containsAnyAnswerConceptName("Alcohol", "Tobacco", "Both");

        return referralAdvice.getComplications();
    }

    static exec(programEncounter, decisions, context, today) {
        const recommendation = QuarterlyVisitDecisionHandler.referrals(programEncounter);
        // decisions['encounterDecisions'] = decisions['encounterDecisions'] || [];
        // decisions['encounterDecisions'] = decisions['encounterDecisions'].filter((d) => d.name !== recommendation.name).concat(recommendation);
        decisions.encounterDecisions.push(AnnualVisitDecisionHandler.anemiaStatusDecisions(programEncounter));
        decisions.encounterDecisions.push(recommendation);
        return decisions;
    }
}
