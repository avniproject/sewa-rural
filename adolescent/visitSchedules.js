import {RuleFactory, VisitScheduleBuilder, RuleCondition} from "rules-config";
import moment from "moment";

const AnnualVisitSchedule = RuleFactory("92cd5f05-eec3-4e70-9537-62119c5e3a16", "VisitSchedule");

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Sickle Cell Followup", 100.0)
class AnnualVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });

        if(programEncounter.encounterType.name === "Annual Visit") {
            scheduleBuilder.add({
                name: "Sickle Cell Vulnerability Followup",
                encounterType: "Sickle Cell Vulnerability",
                earliestDate: moment().add(1, "month"),
                maxDate: moment().add(1, "month").add(15, "days")
            }).when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Disease");
        }

        return scheduleBuilder.getAllUnique("encounterType");

    }
}

export {
    AnnualVisitScheduleSR,
}
