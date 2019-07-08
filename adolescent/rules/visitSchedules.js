import {RuleFactory, VisitScheduleBuilder, RuleCondition} from "rules-config";
import moment from "moment";
import lib from "../../lib";
import _ from "lodash";

const AnnualVisitSchedule = RuleFactory("35e54f14-3a23-45a3-b90e-5383fa026ffd", "VisitSchedule");
const QuarterlyVisitSchedule = RuleFactory("a8c1f2a0-f4e0-4190-b0c3-bd81f21bef6c", "VisitSchedule");
const ChronicSicknessFollowup = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "VisitSchedule");
const MenstrualDisorderFollowup = RuleFactory("bb9bf699-92f3-4646-9cf4-f1792fa2c3a6", "VisitSchedule");
const SeverAnemiaFollowup = RuleFactory("12cd243c-851c-4fd1-bc28-ab0b0141c76f", "VisitSchedule");
const ModerateAnemiaFollowup = RuleFactory("038e6819-2a41-44f5-8473-eda5eeb37806", "VisitSchedule");
const SeverMalnutritionFollowup = RuleFactory("f7b7d2ff-10eb-47a4-866b-b368969f9a7f", "VisitSchedule");
const AddictionVulnerabilityFollowup = RuleFactory("8aec0b76-79ae-4e47-9375-ed9db3739997", "VisitSchedule");
const SickleCellVulnerabilityFollowup = RuleFactory("e728eab9-af8b-46ea-9d5f-f1a9f8727567", "VisitSchedule");

const getEarliestDate = programEncounter => moment().startOf("day").toDate();

const getMaxDate = programEncounter =>
    moment(getEarliestDate(programEncounter))
        .add(15, "days")
        .endOf("day")
        .toDate();

const addDropoutHomeVisits = (programEncounter, scheduleBuilder) => {
    const dateTimeToUse = programEncounter.encounterDateTime;
    const enrolment = programEncounter.programEnrolment;
    const scheduledDropoutVisit = enrolment.scheduledEncountersOfType("Dropout Home Visit");
    if (!_.isEmpty(scheduledDropoutVisit)) return;
    scheduleBuilder
        .add({
            name: "Dropout Home Visit",
            encounterType: "Dropout Home Visit",
            earliestDate: dateTimeToUse,
            maxDate: lib.C.addDays(dateTimeToUse, 15)
        })
        .when.valueInEncounter("School going")
        .containsAnswerConceptName("Dropped Out");
};

const addDropoutFollowUpVisits = (programEncounter, scheduleBuilder) => {
    const dateTimeToUse = programEncounter.encounterDateTime;

    scheduleBuilder
        .add({
            name: "Dropout Followup Visit",
            encounterType: "Dropout Followup Visit",
            earliestDate: lib.C.addDays(dateTimeToUse, 7),
            maxDate: lib.C.addDays(dateTimeToUse, 17)
        })
        .whenItem(programEncounter.encounterType.name)
        .equals("Dropout Home Visit")
        .and.whenItem(
            programEncounter.programEnrolment
                .getEncounters(true)
                .filter(encounter => encounter.encounterType.name === "Dropout Followup Visit").length
        )
        .lessThanOrEqualTo(5);

    scheduleBuilder
        .add({
            name: "Dropout Followup Visit",
            encounterType: "Dropout Followup Visit",
            earliestDate: lib.C.addDays(dateTimeToUse, 7),
            maxDate: lib.C.addDays(dateTimeToUse, 17)
        })
        .when.valueInEncounter("Have you started going to school once again")
        .containsAnswerConceptName("No")
        .and.whenItem(
            programEncounter.programEnrolment
                .getEncounters(true)
                .filter(encounter => encounter.encounterType.name === "Dropout Followup Visit").length
        )
        .lessThanOrEqualTo(5);

    let schoolRestartDate = moment(programEncounter.encounterDateTime)
        .month(5)
        .date(1)
        .hour(0)
        .minute(0)
        .second(0);
    schoolRestartDate =
        schoolRestartDate < moment(programEncounter.encounterDateTime)
            ? schoolRestartDate.add(12, "months").toDate()
            : schoolRestartDate.toDate();
    scheduleBuilder
        .add({
            name: "Dropout Followup Visit",
            encounterType: "Dropout Followup Visit",
            earliestDate: schoolRestartDate,
            maxDate: lib.C.addDays(schoolRestartDate, 15)
        })
        .when.valueInEncounter("Have you started going to school once again")
        .containsAnswerConceptName("Yes, but could not attend");
};

const getNextScheduledVisits = function(programEncounter) {
    const scheduleBuilder = new VisitScheduleBuilder({
        programEnrolment: programEncounter.programEnrolment,
        programEncounter: programEncounter
    });

    addDropoutHomeVisits(programEncounter, scheduleBuilder);
    addDropoutFollowUpVisits(programEncounter, scheduleBuilder);

    return scheduleBuilder.getAllUnique("encounterType");
};

const DropoutVisitSchedule = RuleFactory("54636d6b-33bf-4faf-9397-eb3b1d9b1792", "VisitSchedule");
const DropoutFollowupVisitSchedule = RuleFactory("0c444bf3-54c3-41e4-8ca9-f0deb8760831", "VisitSchedule");

@DropoutVisitSchedule("08cdd999-47bb-4205-917b-efb2a819121f", "Dropout Visit Schedule Not Default", 1.0, {})
class DropoutVisitScheduleHandler {
    static exec(programEncounter, schedule, visitScheduleConfig) {
        return getNextScheduledVisits(programEncounter);
    }
}

@DropoutFollowupVisitSchedule(
    "64ae053e-97f4-4fc3-878d-81c3545136a7",
    "Dropout Followup Visit Schedule Not Default",
    1.0,
    {}
)
class DropoutFollowupVisitScheduleHandler {
    static exec(programEncounter, schedule, visitScheduleConfig) {
        console.log(`DropoutFollowupVisitScheduleHandler is invoked`);
        return getNextScheduledVisits(programEncounter);
    }
}

class CommonSchedule {
    static scheduleMalnutritionFollowup(programEncounter, scheduleBuilder) {
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
                lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 14.5) ||
            false;

        if (isUnderweight) {
            let earliestDate = getEarliestDate(programEncounter);
            let maxDate = getMaxDate(programEncounter);
            scheduleBuilder.add({
                name: "Severe Malnutrition Followup",
                encounterType: "Severe Malnutrition Followup",
                earliestDate: earliestDate,
                maxDate: maxDate
            });
        }
    }

    static scheduleMenstualDisorderFollowup(context, scheduleBuilder) {
        if (
            new RuleCondition(context).when
                .valueInEncounter("Are you able to do daily routine work during menstruation?")
                .is.no.or.valueInEncounter("Does she remain absent during menstruation?")
                .is.yes.matches()
        ) {
            scheduleBuilder.add({
                name: "Menstrual Disorder Followup",
                encounterType: "Menstrual Disorder Followup",
                earliestDate: getEarliestDate(context.programEncounter),
                maxDate: getMaxDate(context.programEncounter)
            });
        }
    }

    static scheduleAnnualVisit(scheduleBuilder) {
        let earliestDate = moment()
            .date(1)
            .month("July")
            .year(moment().year() + 1)
            .startOf("day");
        scheduleBuilder.add({
            name: "Annual Visit",
            encounterType: "Annual Visit",
            earliestDate: earliestDate.toDate(),
            maxDate: moment(earliestDate)
                .add(1, "month")
                .endOf("day")
                .toDate()
        });
    }

    static scheduleQuarterlyVisit(scheduleBuilder) {
        let quarterlyVisitEarliestDate = moment()
            .date(1)
            .month("October")
            .year(moment().year())
            .startOf("day");
        scheduleBuilder.add({
            name: "Quarterly Visit",
            encounterType: "Quarterly Visit",
            earliestDate: quarterlyVisitEarliestDate.toDate(),
            maxDate: moment(quarterlyVisitEarliestDate)
                .add(1, "month")
                .toDate()
        });
    }

    static scheduleChronicSicknessFollowup(context, scheduleBuilder) {
        if (
            new RuleCondition(context).when
                .valueInEncounter("Is there any other condition you want to mention about him/her?")
                .containsAnswerConceptNameOtherThan("No problem")
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Chronic Sickness Followup",
                encounterType: "Chronic Sickness Followup",
                earliestDate: getEarliestDate(context.programEncounter),
                maxDate: getMaxDate(context.programEncounter)
            });
        }
    }

    static scheduleSevereAnemiaFollowup(context, scheduleBuilder) {
        if (
            new RuleCondition(context).when
                .valueInEncounter("Hb")
                .is.lessThanOrEqualTo(7)
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Severe Anemia Followup",
                encounterType: "Severe Anemia Followup",
                earliestDate: getEarliestDate(context.programEncounter),
                maxDate: getMaxDate(context.programEncounter)
            });
        }
    }

    static scheduleModerateAnemiaFollowup(context, scheduleBuilder) {
        if (
            new RuleCondition(context).when
                .valueInEncounter("Hb")
                .is.greaterThanOrEqualTo(7.1)
                .and.valueInEncounter("Hb")
                .is.lessThanOrEqualTo(10)
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Moderate Anemia Followup",
                encounterType: "Moderate Anemia Followup",
                earliestDate: getEarliestDate(context.programEncounter),
                maxDate: getMaxDate(context.programEncounter)
            });
        }
    }

    static scheduleAddictionFollowup(context, scheduleBuilder) {
        if (
            new RuleCondition(context).when
                .valueInEncounter("Addiction Details")
                .containsAnyAnswerConceptName("Alcohol", "Tobacco", "Both")
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Addiction Followup",
                encounterType: "Addiction Followup",
                earliestDate: getEarliestDate(context.programEncounter),
                maxDate: getMaxDate(context.programEncounter)
            });
        }
    }

    static scheduleSickleCellFollowup(context, scheduleBuilder) {
        if (
            new RuleCondition(context).when
                .valueInEncounter("Sickling Test Result")
                .containsAnswerConceptName("Disease")
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Sickle Cell Followup",
                encounterType: "Sickle Cell Followup",
                earliestDate: getEarliestDate(context.programEncounter),
                maxDate: getMaxDate(context.programEncounter)
            });
        }
    }
}

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Annual Visit Schedule", 100.0)
class AnnualVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        let context = {
            programEncounter: programEncounter,
            programEnrolment: programEnrolment
        };
        const scheduleBuilder = new VisitScheduleBuilder(context);

        CommonSchedule.scheduleSickleCellFollowup(context, scheduleBuilder);

        CommonSchedule.scheduleChronicSicknessFollowup(context, scheduleBuilder);

        CommonSchedule.scheduleSevereAnemiaFollowup(context, scheduleBuilder);

        CommonSchedule.scheduleModerateAnemiaFollowup(context, scheduleBuilder);

        CommonSchedule.scheduleAddictionFollowup(context, scheduleBuilder);

        CommonSchedule.scheduleMalnutritionFollowup(programEncounter, scheduleBuilder);

        CommonSchedule.scheduleMenstualDisorderFollowup(context, scheduleBuilder);

        CommonSchedule.scheduleQuarterlyVisit(scheduleBuilder);

        addDropoutHomeVisits(programEncounter, scheduleBuilder);
        addDropoutFollowUpVisits(programEncounter, scheduleBuilder);

        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@QuarterlyVisitSchedule("ac928c59-d26d-4f74-9b5e-db506a44b4e0", "Quarterly Visit Schedule", 100.0)
class QuarterlyVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        let context = {
            programEncounter: programEncounter,
            programEnrolment: programEnrolment
        };
        const scheduleBuilder = new VisitScheduleBuilder(context);
        const currentMonth = moment().format("MMMM");
        const visitTable = {
            October: {nextMonth: "January", incrementInYear: 1},
            January: {nextMonth: "May", incrementInYear: 0},
            May: {nextMonth: "October", incrementInYear: 0}
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
                maxDate: moment(quarterlyVisitEarliestDate)
                    .add(1, "month")
                    .toDate()
            });
        }
        CommonSchedule.scheduleSickleCellFollowup(context, scheduleBuilder);
        CommonSchedule.scheduleMenstualDisorderFollowup(context, scheduleBuilder);
        CommonSchedule.scheduleAddictionFollowup(context, scheduleBuilder);
        addDropoutHomeVisits(programEncounter, scheduleBuilder);
        addDropoutFollowUpVisits(programEncounter, scheduleBuilder);

        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@ChronicSicknessFollowup("625a709f-90b9-40f9-8483-b0c9790a4eba", "Chronic Sickness Followup", 100.0)
class ChronicSicknessFollowupScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment
        });
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        scheduleBuilder.add({
            name: "Chronic Sickness Followup",
            encounterType: "Chronic Sickness Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
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
            programEnrolment: programEnrolment
        });
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        scheduleBuilder.add({
            name: "Menstrual Disorder Followup",
            encounterType: "Menstrual Disorder Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@SeverAnemiaFollowup("83098b53-fbfa-4acb-9bc8-7f1e38b9789b", "Sever Anemia Followup", 100.0)
class SeverAnemiaFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        let context = {
            programEncounter: programEncounter,
            programEnrolment: programEncounter.programEnrolment
        };
        const scheduleBuilder = new VisitScheduleBuilder(context);
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        if (
            new RuleCondition(context).when
                .valueInEncounter("HB after 3 months of treatment")
                .is.lessThanOrEqualTo(7)
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Severe Anemia Followup",
                encounterType: "Severe Anemia Followup",
                earliestDate: nextVisitDate.toDate(),
                maxDate: nextVisitDate.add(15, "days").toDate()
            });
        }
        if (
            new RuleCondition(context).when
                .valueInEncounter("HB after 3 months of treatment")
                .is.greaterThanOrEqualTo(7.1)
                .and.valueInEncounter("HB after 3 months of treatment")
                .is.lessThanOrEqualTo(10)
                .matches()
        ) {
            scheduleBuilder.add({
                name: "Moderate Anemia Followup",
                encounterType: "Moderate Anemia Followup",
                earliestDate: nextVisitDate.toDate(),
                maxDate: nextVisitDate.add(15, "days").toDate()
            });
        }

        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@ModerateAnemiaFollowup("5959b803-b098-44f7-9ca9-cf14fc7c7837", "Moderate Anemia Followup", 100.0)
class ModerateAnemiaFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment
        });
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        scheduleBuilder.add({
            name: "Moderate Anemia Followup",
            encounterType: "Moderate Anemia Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
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
            programEnrolment: programEnrolment
        });
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        scheduleBuilder.add({
            name: "Severe Malnutrition Followup",
            encounterType: "Severe Malnutrition Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
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
            programEnrolment: programEnrolment
        });
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        scheduleBuilder.add({
            name: "Addiction Followup",
            encounterType: "Addiction Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

@SickleCellVulnerabilityFollowup("d85c8fd0-a5bf-49f3-9eb2-b67ef7af9f5c", "Sickle Cell Vulnerability Followup", 100.0)
class SickleCellVulnerabilityFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        const scheduleBuilder = new VisitScheduleBuilder({
            programEncounter: programEncounter,
            programEnrolment: programEnrolment
        });
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(1, "month");
        scheduleBuilder.add({
            name: "Sickle Cell Followup",
            encounterType: "Sickle Cell Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
        return scheduleBuilder.getAllUnique("encounterType");
    }
}

export {
    AnnualVisitScheduleSR,
    QuarterlyVisitScheduleSR,
    ChronicSicknessFollowupScheduleSR,
    MenstrualDisorderFollowupSR,
    SeverAnemiaFollowupSR,
    ModerateAnemiaFollowupSR,
    SeverMalnutritionFollowupSR,
    AddictionVulnerabilityFollowupSR,
    SickleCellVulnerabilityFollowupSR,
    DropoutFollowupVisitScheduleHandler,
    DropoutVisitScheduleHandler
};
