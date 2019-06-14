import {RuleFactory, VisitScheduleBuilder, RuleCondition} from "rules-config";
import moment from "moment";

const AnnualVisitSchedule = RuleFactory("92cd5f05-eec3-4e70-9537-62119c5e3a16", "VisitSchedule");
const ChronicSicknessFollowup = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "VisitSchedule");

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Sickle Cell Followup", 100.0)
class AnnualVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });

        if (programEncounter.encounterType.name === "Annual Visit") {
            scheduleBuilder.add({
                name: "Sickle Cell Vulnerability Followup",
                encounterType: "Sickle Cell Vulnerability",
                earliestDate: moment().add(1, "month"),
                maxDate: moment().add(1, "month").add(15, "days")
            }).when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Disease");
        }

        if (programEncounter.encounterType.name === "Annual Visit") {
            scheduleBuilder.add({
                name: "Chronic Sickness Followup",
                encounterType: "Chronic Sickness",
                earliestDate: moment().add(1, "month").toDate(),
                maxDate: moment().add(1, "month").add(15, "days").toDate()
            }).when
                .valueInEncounter("Is there any other condition you want to mention about him/her?").containsAnswerConceptNameOtherThan("No problem")
                .or.valueInEncounter("Sickness in last 1 months").containsAnswerConceptNameOtherThan("No sickness");
        }

        return scheduleBuilder.getAllUnique("encounterType");

    }
}

@ChronicSicknessFollowup("625a709f-90b9-40f9-8483-b0c9790a4eba", "Chronic Sickness Followup", 100.0)
class ChronicSicknessFollowupScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });
        scheduleBuilder.add({
            name: "Chronic Sickness Followup",
            encounterType: "Chronic Sickness",
            earliestDate: moment().add(1, "month").toDate(),
            maxDate: moment().add(1, "month").add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

export {
    AnnualVisitScheduleSR,
    ChronicSicknessFollowupScheduleSR,
}
