import {RuleFactory, VisitScheduleBuilder, RuleCondition} from "rules-config";
import moment from "moment";
import lib from "../../lib";

const AnnualVisitSchedule = RuleFactory("35e54f14-3a23-45a3-b90e-5383fa026ffd", "VisitSchedule");
const ChronicSicknessFollowup = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "VisitSchedule");
const MenstrualDisorderFollowup = RuleFactory("bb9bf699-92f3-4646-9cf4-f1792fa2c3a6", "VisitSchedule");
const SeverAnemiaFollowup = RuleFactory("12cd243c-851c-4fd1-bc28-ab0b0141c76f", "VisitSchedule");
const ModerateAnemiaFollowup = RuleFactory("038e6819-2a41-44f5-8473-eda5eeb37806", "VisitSchedule");
const SeverMalnutritionFollowup = RuleFactory("f7b7d2ff-10eb-47a4-866b-b368969f9a7f", "VisitSchedule");
const AddictionVulnerabilityFollowup = RuleFactory("8aec0b76-79ae-4e47-9375-ed9db3739997", "VisitSchedule");

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Annual Visit Schedule", 100.0)
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

            if (new RuleCondition(context).when
                .valueInEncounter("Addiction Details").containsAnyAnswerConceptName("Alcohol", "Tobacco", "Both")
                .matches()) {
                scheduleBuilder.add({
                    name: "Addiction Vulnerability Followup",
                    encounterType: "Addiction Vulnerability",
                    earliestDate: moment().add(1, "month").toDate(),
                    maxDate: moment().add(1, "month").add(15, "days").toDate()
                });
            }

            AnnualVisitScheduleSR.scheduleMenstualDisorderFollowup(context, scheduleBuilder);
            AnnualVisitScheduleSR.scheduleAnnualVisit(scheduleBuilder);

            // let quarterlyVisitEarliestDate =
            //     moment().date(1).month("October").year(moment().year()).startOf("day");
            // scheduleBuilder.add({
            //     name: "Quarterly Visit",
            //     encounterType: "Quarterly Visit",
            //     earliestDate: quarterlyVisitEarliestDate.toDate(),
            //     maxDate: moment(quarterlyVisitEarliestDate).add(1, "month").toDate()
            // });

        }

        if (programEncounter.encounterType.name === "Quarterly Visit") {

            AnnualVisitScheduleSR.scheduleMenstualDisorderFollowup(context, scheduleBuilder);

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
        }

        //Visit not getting scheduled when keeping this block in the first if of Annual Visit, hence kept separately
        const heightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment('Height', programEncounter);
        const weightObs = programEncounter.programEnrolment.findLatestObservationInEntireEnrolment('Weight', programEncounter);
        const isUnderweight = heightObs && weightObs && lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 14.5 || false;
         if (programEncounter.encounterType.name === "Annual Visit" && isUnderweight) {
            scheduleBuilder.add({
                name: "Severe Malnutrition Followup",
                encounterType: "Severe Malnutrition Followup",
                earliestDate: moment().add(1, "month").toDate(),
                maxDate: moment().add(1, "month").add(15, "days").toDate()
            });
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

    static scheduleAnnualVisit(scheduleBuilder) {
        let earliestDate = moment()
            .date(1)
            .month("July")
            .year(moment().year()+1)
            .startOf("day");
        scheduleBuilder.add({
            name: "Annual Visit",
            encounterType: "Annual Visit",
            earliestDate: earliestDate.toDate(),
            maxDate: moment(earliestDate).add(1, "month").endOf("day").toDate()
        });
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

@SeverMalnutritionFollowup("2bf7b5fd-adfe-49f1-b249-48482ef6e6e8", "Sever Malnutrition Followup", 100.0)
class SeverMalnutritionFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });
        scheduleBuilder.add({
            name: "Severe Malnutrition Followup",
            encounterType: "Severe Malnutrition Followup",
            earliestDate: moment().add(1, "month").toDate(),
            maxDate: moment().add(1, "month").add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@AddictionVulnerabilityFollowup("beca45b9-f037-4d3f-906d-5970018ce5bb", "Addiction Vulnerability Followup", 100.0)
class AddictionVulnerabilityFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        });
        scheduleBuilder.add({
            name: "Addiction Vulnerability Followup",
            encounterType: "Addiction Vulnerability",
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
    ModerateAnemiaFollowupSR,
    SeverMalnutritionFollowupSR,
    AddictionVulnerabilityFollowupSR
}
