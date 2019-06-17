import {RuleFactory, VisitScheduleBuilder, RuleCondition} from "rules-config";
import moment from "moment";
import _ from "lodash";

const AnnualVisitSchedule = RuleFactory("92cd5f05-eec3-4e70-9537-62119c5e3a16", "VisitSchedule");
const ChronicSicknessFollowup = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "VisitSchedule");
const MenstrualDisorderFollowup = RuleFactory("bb9bf699-92f3-4646-9cf4-f1792fa2c3a6", "VisitSchedule");
const SeverAnemiaFollowup = RuleFactory("12cd243c-851c-4fd1-bc28-ab0b0141c76f", "VisitSchedule");
const ModerateAnemiaFollowup = RuleFactory("038e6819-2a41-44f5-8473-eda5eeb37806", "VisitSchedule");

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Sickle Cell Followup", 100.0)
class AnnualVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        let context = {
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        };
        const scheduleBuilder = new VisitScheduleBuilder(context);

        if (programEncounter.encounterType.name === "Annual Visit") {
            let oneMonthFromNow =
                moment().add(1, "month").startOf("day");

            if (new RuleCondition(context).when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Disease").matches()) {
                scheduleBuilder.add({
                    name: "Sickle Cell Vulnerability Followup",
                    encounterType: "Sickle Cell Vulnerability",
                    earliestDate: oneMonthFromNow.toDate(),
                    maxDate: moment(oneMonthFromNow).add(15, "days").endOf("day").toDate()
                });
            }

            if (new RuleCondition(context).when
                .valueInEncounter("Is there any other condition you want to mention about him/her?")
                .containsAnswerConceptNameOtherThan("No problem")
                .matches()) {
                scheduleBuilder.add({
                    name: "Chronic Sickness Followup",
                    encounterType: "Chronic Sickness",
                    earliestDate: moment().add(1, "month").toDate(),
                    maxDate: moment().add(1, "month").add(15, "days").toDate()
                });
            }

            if (new RuleCondition(context).when
                .valueInEncounter("Hb")
                .is.lessThanOrEqualTo(7)
                .matches()) {
                scheduleBuilder.add({
                    name: "Severe Anemia Followup",
                    encounterType: "Severe Anemia",
                    earliestDate: moment().add(1, "month").toDate(),
                    maxDate: moment().add(1, "month").add(15, "days").toDate()
                });
            }

            if (new RuleCondition(context).when
                .valueInEncounter("Hb").is.greaterThanOrEqualTo(7.1)
                .and.valueInEncounter("Hb").is.lessThanOrEqualTo(10)
                .matches()) {
                scheduleBuilder.add({
                    name: "Moderate Anemia Followup",
                    encounterType: "Moderate Anemia",
                    earliestDate: moment().add(1, "month").toDate(),
                    maxDate: moment().add(1, "month").add(15, "days").toDate()
                });
            }

            let quarterlyVisitEarliestDate =
                moment().date(1).month("October").year(moment().year()).startOf("day");
            scheduleBuilder.add({
                name: "Quarterly Visit",
                encounterType: "Quarterly Visit",
                earliestDate: quarterlyVisitEarliestDate.toDate(),
                maxDate: moment(quarterlyVisitEarliestDate).add(1, "month").toDate()
            });

            this.scheduleMenstualDisorderFollowup(context, scheduleBuilder);
        }

        if (programEncounter.encounterType.name === "Quarterly Visit") {

            const currentMonth = moment().format("MMMM");
            const visitTable = {
                "October": {"nextMonth": "January", "incrementInYear": 1},
                "January": {"nextMonth": "May", "incrementInYear": 0},
                "May": {"nextMonth": "October", "incrementInYear": 0},
            };

            if (visitTable[currentMonth]) {
                let quarterlyVisitEarliestDate = moment()
                    .date(1)
                    .month(visitTable[currentMonth].nextMonth)
                    .year(moment().year() + visitTable[currentMonth].incrementInYear)
                    .startOf("day");

                scheduleBuilder.add({
                    name: "Quarterly Visit",
                    encounterType: "Quarterly Visit",
                    earliestDate: quarterlyVisitEarliestDate.toDate(),
                    maxDate: moment(quarterlyVisitEarliestDate).add(1, "month").toDate()
                });
            }

            this.scheduleMenstualDisorderFollowup(context, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType");
    }

    static scheduleMenstualDisorderFollowup(context, scheduleBuilder) {
        if (new RuleCondition(context).when
            .valueInEncounter("Are you able to do daily routine work during menstruation?").is.yes
            .or
            .valueInEncounter("Does she remain absent during menstruation?").is.yes
            .matches()
        ) {
            scheduleBuilder.add({
                name: "Menstrual Disorder Followup",
                encounterType: "Menstrual Disorder",
                earliestDate: moment().add(1, "month").toDate(),
                maxDate: moment().add(1, "month").add(15, "days").toDate()
            });
        }
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

@MenstrualDisorderFollowup("0dd989d4-027b-4b66-99d8-f91183981965", "Menstrual Disorder Followup", 100.0)
class MenstrualDisorderFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });
        scheduleBuilder.add({
            name: "Menstrual Disorder Followup",
            encounterType: "Menstrual Disorder",
            earliestDate: moment().add(1, "month").toDate(),
            maxDate: moment().add(1, "month").add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@SeverAnemiaFollowup("83098b53-fbfa-4acb-9bc8-7f1e38b9789b", "Sever Anemia Followup", 100.0)
class SeverAnemiaFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });
        scheduleBuilder.add({
            name: "Severe Anemia Followup",
            encounterType: "Severe Anemia",
            earliestDate: moment().add(1, "month").toDate(),
            maxDate: moment().add(1, "month").add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@ModerateAnemiaFollowup("5959b803-b098-44f7-9ca9-cf14fc7c7837", "Moderate Anemia Followup", 100.0)
class ModerateAnemiaFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });
        scheduleBuilder.add({
            name: "Moderate Anemia Followup",
            encounterType: "Moderate Anemia",
            earliestDate: moment().add(1, "month").toDate(),
            maxDate: moment().add(1, "month").add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

export {
    AnnualVisitScheduleSR,
    ChronicSicknessFollowupScheduleSR,
    MenstrualDisorderFollowupSR,
    SeverAnemiaFollowupSR,
    ModerateAnemiaFollowupSR
}
