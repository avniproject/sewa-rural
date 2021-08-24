import {RuleCondition, RuleFactory, VisitScheduleBuilder} from "rules-config";
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
const VisitRescheduleOnCancel = RuleFactory("c294aadf-94a6-4908-8d04-9cc4ce2b901c", "VisitSchedule");
const EndlineVisitSchedule = RuleFactory("b9d58493-7d08-49c9-bdc7-f1864cb97819", "VisitSchedule");
const hasExitedProgram = (programEncounter) => programEncounter.programEnrolment.programExitDateTime;

const getEarliestDate = programEncounter => {
    const currentDateTime = moment(programEncounter.earliestVisitDateTime || programEncounter.encounterDateTime);
    const month = currentDateTime.month();
    //if month is Nov
    if (month === 10) {
        return currentDateTime.toDate();
    } else if (month < 10) {
        return moment(currentDateTime).month(10).startOf('M').toDate()
    } else if (month > 10) {
        const year = currentDateTime.year();
        return moment(currentDateTime).month(10).year(year + 1).startOf('M').toDate()
    }
};

const getMaxDate = programEncounter =>
    moment(getEarliestDate(programEncounter))
        .add(15, "days")
        .endOf("day")
        .toDate();

const getNextNovDate = programEncounter => {
    return moment(programEncounter.earliestVisitDateTime || programEncounter.encounterDateTime)
            .add(1, 'y')
            .month(10).startOf('M');
};

const getNextCancelDate = programEncounter => {
    return _.isNil(programEncounter.earliestVisitDateTime)
        ? moment().add(1, "month")
        : moment(programEncounter.earliestVisitDateTime).add(1, "month")
};

const addDropoutHomeVisits = (programEncounter, scheduleBuilder, cancelSchedule) => {
    const dateTimeToUse = programEncounter.encounterDateTime || programEncounter.earliestVisitDateTime;
    const enrolment = programEncounter.programEnrolment;
    const scheduledDropoutVisit = enrolment.scheduledEncountersOfType("Dropout Home Visit");
    if (!_.isEmpty(scheduledDropoutVisit)) return;
    if (cancelSchedule) {
        scheduleBuilder
            .add({
                name: "Dropout Home Visit",
                encounterType: "Dropout Home Visit",
                earliestDate: dateTimeToUse,
                maxDate: lib.C.addDays(dateTimeToUse, 15)
            });
        return;
    }

    const droppedOutCondition = new RuleCondition({programEncounter})
        .when.valueInEncounter("School going")
        .containsAnswerConceptName("Dropped Out");

    const droppedOutDate = programEncounter.getObservationReadableValue("In which year he/she has left the school");
    var c2 = 0;
    if (!_.isNil(droppedOutDate)) {
        c2 = moment().diff(droppedOutDate, 'year');
    }

    if (droppedOutCondition.matches() && c2 < 1) {
        scheduleBuilder
            .add({
                name: "Dropout Home Visit",
                encounterType: "Dropout Home Visit",
                earliestDate: dateTimeToUse,
                maxDate: lib.C.addDays(dateTimeToUse, 15)
            });
    }
};


const addDropoutFollowUpVisits = (programEncounter, scheduleBuilder, cancelSchedule) => {
    const dateTimeToUse = programEncounter.encounterDateTime || programEncounter.earliestVisitDateTime;

    if (cancelSchedule) {
        scheduleBuilder
            .add({
                name: "Dropout Followup Visit",
                encounterType: "Dropout Followup Visit",
                earliestDate: lib.C.addDays(dateTimeToUse, 7),
                maxDate: lib.C.addDays(dateTimeToUse, 17)
            });
        return;
    }

    const dropoutHomeVisitCondition = new RuleCondition({programEncounter}).whenItem(programEncounter.encounterType.name)
        .equals("Dropout Home Visit")
        .and.whenItem(
            programEncounter.programEnrolment
                .getEncounters(true)
                .filter(encounter => encounter.encounterType.name === "Dropout Followup Visit").length
        )
        .lessThanOrEqualTo(5);

    if (dropoutHomeVisitCondition.matches()) {
        scheduleBuilder
            .add({
                name: "Dropout Followup Visit",
                encounterType: "Dropout Followup Visit",
                earliestDate: lib.C.addDays(dateTimeToUse, 7),
                maxDate: lib.C.addDays(dateTimeToUse, 17)
            });
    }

    const notYetAttendedSchoolCondition = new RuleCondition({programEncounter})
        .when.valueInEncounter("Have you started going to school once again")
        .containsAnswerConceptName("No")
        .and.whenItem(
            programEncounter.programEnrolment
                .getEncounters(true)
                .filter(encounter => encounter.encounterType.name === "Dropout Followup Visit").length
        )
        .lessThanOrEqualTo(5);

    if (notYetAttendedSchoolCondition.matches()) {
        scheduleBuilder
            .add({
                name: "Dropout Followup Visit",
                encounterType: "Dropout Followup Visit",
                earliestDate: lib.C.addDays(dateTimeToUse, 7),
                maxDate: lib.C.addDays(dateTimeToUse, 17)
            });
    }


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

    const couldNotYetAttendSchoolCondition = new RuleCondition({programEncounter})
        .when.valueInEncounter("Have you started going to school once again")
        .containsAnswerConceptName("Yes, but could not attend");

    if (couldNotYetAttendSchoolCondition.matches()) {
        scheduleBuilder
            .add({
                name: "Dropout Followup Visit",
                encounterType: "Dropout Followup Visit",
                earliestDate: schoolRestartDate,
                maxDate: lib.C.addDays(schoolRestartDate, 15)
            });
    }

};

const getNextScheduledVisits = function (programEncounter) {
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
                lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 18.5) ||
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

    static scheduleMenstrualDisorderFollowup(context, scheduleBuilder) {
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

    static scheduleNextRegularVisit({programEncounter}, scheduleBuilder) {
        const visitTable = {
            April: {nextMonth: "May", incrementInYear: 0, visitType: "Quarterly Visit"},
            May: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            June: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            July: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            August: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            September: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            October: {nextMonth: "January", incrementInYear: 1, visitType: "Quarterly Visit"},
            November: {nextMonth: "January", incrementInYear: 1, visitType: "Quarterly Visit"},
            December: {nextMonth: "January", incrementInYear: 1, visitType: "Quarterly Visit"},

        };
        const earliestVisitDateTime = CommonSchedule.getISTDateTime(programEncounter.earliestVisitDateTime);
        const currentMonth = moment(earliestVisitDateTime).format("MMMM");
        const nextVisit = visitTable[currentMonth];

        if (nextVisit) {
            let quarterlyVisitEarliestDate = moment()
                .date(1)
                .month(nextVisit.nextMonth)
                .year(moment(earliestVisitDateTime).year() + nextVisit.incrementInYear)
                .startOf("day");

            scheduleBuilder.add({
                name: nextVisit.visitType,
                encounterType: nextVisit.visitType,
                earliestDate: quarterlyVisitEarliestDate.toDate(),
                maxDate: moment(quarterlyVisitEarliestDate)
                    .add(1, "month")
                    .toDate()
            });
        }
    }

    static scheduleNextRegularVisitFromEndline({programEncounter}, scheduleBuilder) {
        const visitTable = {
            February: {nextMonth: "April", incrementInYear: 0, visitType: "Annual Visit"},
            March: {nextMonth: "April", incrementInYear: 0, visitType: "Annual Visit"},
            April: {nextMonth: "May", incrementInYear: 0, visitType: "Annual Visit"},
            May: {nextMonth: "June", incrementInYear: 0, visitType: "Annual Visit"},
            June: {nextMonth: "July", incrementInYear: 0, visitType: "Annual Visit"},
            July: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            August: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            September: {nextMonth: "October", incrementInYear: 0, visitType: "Quarterly Visit"},
            October: {nextMonth: "January", incrementInYear: 1, visitType: "Quarterly Visit"},
            November: {nextMonth: "January", incrementInYear: 1, visitType: "Quarterly Visit"},
            December: {nextMonth: "January", incrementInYear: 1, visitType: "Quarterly Visit"},
            January: {nextMonth: "April", incrementInYear: 0, visitType: "Annual Visit"},
        };
        const earliestVisitDateTime = CommonSchedule.getISTDateTime(programEncounter.earliestVisitDateTime);
        const currentMonth = moment(earliestVisitDateTime).format("MMMM");
        const nextVisit = visitTable[currentMonth];

        if (nextVisit) {
            let quarterlyVisitEarliestDate = moment()
                .date(1)
                .month(nextVisit.nextMonth)
                .year(moment(earliestVisitDateTime).year() + nextVisit.incrementInYear)
                .startOf("day");

            scheduleBuilder.add({
                name: nextVisit.visitType,
                encounterType: nextVisit.visitType,
                earliestDate: quarterlyVisitEarliestDate.toDate(),
                maxDate: moment(quarterlyVisitEarliestDate)
                    .add(1, "month")
                    .toDate()
            });
        }
    }


    static getISTDateTime = (date = new Date()) => {
        if (date.getTimezoneOffset() === 0) {
            const ISTDate = date;
            ISTDate.setHours(date.getHours() + 5);
            ISTDate.setMinutes(date.getMinutes() + 30);
            return ISTDate;
        }
        return date
    };

    static  addEndlineVisitAnnual = (programEncounter, scheduleBuilder, cancelSchedule) => {
        //visit scheduled for 2020-12-31 18:30:00.00000Z when computed in UTC returns 11 as month() and
        //since rule server has timezone set to UTC so hardcoding timezone in the rule.
        const ISTDateTime = CommonSchedule.getISTDateTime(programEncounter.earliestVisitDateTime);
        const earliestVisitDateTime = moment(ISTDateTime);
        const scheduledVisitYear = earliestVisitDateTime.year();
        const scheduledVisitMonth = earliestVisitDateTime.month();
        const earliest = moment()
            .date(1)
            .month(1)
            .year(scheduledVisitYear)
            .startOf("months");

        const maxDateOfVisit = moment(earliest).add(1, 'month');
        //Schedule Endline visit from Jan Quarterly visit or from the annual visit when child is enrolled on Jan, Feb or March.
        if (scheduledVisitMonth < 3) {
            scheduleBuilder
                .add({
                    name: `Endline Visit ${scheduledVisitYear}`,
                    encounterType: "Endline Visit",
                    earliestDate: earliest.toDate(),
                    maxDate: maxDateOfVisit.toDate()

                });
        }


    };
}

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Annual Visit Schedule", 100.0)
class AnnualVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            CommonSchedule.scheduleSickleCellFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleChronicSicknessFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleSevereAnemiaFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleModerateAnemiaFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleAddictionFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleMalnutritionFollowup(programEncounter, scheduleBuilder);
            CommonSchedule.scheduleMenstrualDisorderFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);
            addDropoutHomeVisits(programEncounter, scheduleBuilder);
            addDropoutFollowUpVisits(programEncounter, scheduleBuilder);
            CommonSchedule.addEndlineVisitAnnual(programEncounter, scheduleBuilder);
        }
        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

@QuarterlyVisitSchedule("ac928c59-d26d-4f74-9b5e-db506a44b4e0", "Quarterly Visit Schedule", 100.0)
class QuarterlyVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleSickleCellFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleMenstrualDisorderFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleAddictionFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleSevereAnemiaFollowup({programEncounter}, scheduleBuilder);
            CommonSchedule.scheduleModerateAnemiaFollowup({programEncounter}, scheduleBuilder);
            addDropoutHomeVisits(programEncounter, scheduleBuilder);
            addDropoutFollowUpVisits(programEncounter, scheduleBuilder);
            CommonSchedule.addEndlineVisitAnnual(programEncounter, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const scheduleChronicSicknessFollowupSchedule = ({programEncounter}, scheduleBuilder, cancelSchedule) => {

    const schedulingEncounter = programEncounter.programEnrolment.getEncounters(true).filter(encounter => {
        const sicknessValue = encounter.getObservationReadableValue('Is there any other condition you want to mention about him/her?');
        return sicknessValue && !_.includes(sicknessValue, 'No problem');
    })[0];

    const chronicSicknessCondition = new RuleCondition({programEncounter}).whenItem(
            programEncounter.programEnrolment
                .getEncounters(true)
                .filter(encounter => encounter.encounterType.name === "Chronic Sickness Followup" &&
                    (schedulingEncounter && encounter.encounterDateTime >= schedulingEncounter.encounterDateTime)
                ).length
        )
        .lessThan(2);

    if (schedulingEncounter && chronicSicknessCondition.matches()) {
        if (cancelSchedule) {
            const nextVisitDate = getNextCancelDate(programEncounter);
            scheduleBuilder.add({
                name: "Chronic Sickness Followup",
                encounterType: "Chronic Sickness Followup",
                earliestDate: nextVisitDate.toDate(),
                maxDate: nextVisitDate.add(15, "days").toDate()
            });
        } else {
            const nextNovDate = getNextNovDate(programEncounter);
            scheduleBuilder.add({
                name: "Chronic Sickness Followup",
                encounterType: "Chronic Sickness Followup",
                earliestDate: nextNovDate.toDate(),
                maxDate: nextNovDate.add(15, "days").toDate()
            });
        }

    }
};

@ChronicSicknessFollowup("625a709f-90b9-40f9-8483-b0c9790a4eba", "Chronic Sickness Followup", 100.0)
class ChronicSicknessFollowupScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});
        if (!hasExitedProgram(programEncounter) &&
            new RuleCondition({programEncounter})
                .when.valueInEncounter('Whether condition cured')
                .is.no.matches()) {
            scheduleChronicSicknessFollowupSchedule({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const scheduleMenstrualDisorderFollowup = ({programEncounter}, scheduleBuilder, cancelSchedule) => {
    if (cancelSchedule) {
        const nextVisitDate = getNextCancelDate(programEncounter);
        scheduleBuilder.add({
            name: "Menstrual Disorder Followup",
            encounterType: "Menstrual Disorder Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
    } else {
        const nextNovDate = getNextNovDate(programEncounter);
        scheduleBuilder.add({
            name: "Menstrual Disorder Followup",
            encounterType: "Menstrual Disorder Followup",
            earliestDate: nextNovDate.toDate(),
            maxDate: nextNovDate.add(15, "days").toDate()
        });
    }
};

@MenstrualDisorderFollowup("0dd989d4-027b-4b66-99d8-f91183981965", "Menstrual Disorder Followup", 100.0)
class MenstrualDisorderFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter) &&
            new RuleCondition({programEncounter})
                .when.valueInEncounter("Remains absent due to menstrual problem")
                .is.yes.matches()) {
            scheduleMenstrualDisorderFollowup({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const severeAnemiaFollowup = ({programEncounter}, scheduleBuilder, cancelSchedule) => {
    const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
        ? moment().add(1, "month")
        : moment(programEncounter.earliestVisitDateTime).add(1, "month");

    if (cancelSchedule) {
        scheduleBuilder.add({
            name: "Severe Anemia Followup",
            encounterType: "Severe Anemia Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
        return;
    }

    if (
        new RuleCondition({programEncounter}).when
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
        new RuleCondition({programEncounter}).when
            .valueInEncounter("HB after 3 months of treatment")
            .is.greaterThanOrEqualTo(7.1)
            .and.valueInEncounter("HB after 3 months of treatment")
            .is.lessThanOrEqualTo(10)
            .matches()
    ) {
        const nextNovDate = getNextNovDate(programEncounter);
        scheduleBuilder.add({
            name: "Moderate Anemia Followup",
            encounterType: "Moderate Anemia Followup",
            earliestDate: nextNovDate.toDate(),
            maxDate: nextNovDate.add(15, "days").toDate()
        });
    }
};

@SeverAnemiaFollowup("83098b53-fbfa-4acb-9bc8-7f1e38b9789b", "Sever Anemia Followup", 100.0)
class SeverAnemiaFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            severeAnemiaFollowup({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const moderateAnemiaFollowup = ({programEncounter}, scheduleBuilder, cancelSchedule) => {
    if (cancelSchedule) {
        const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
            ? moment().add(1, "month")
            : moment(programEncounter.earliestVisitDateTime).add(3, "month");
        scheduleBuilder.add({
            name: "Moderate Anemia Followup",
            encounterType: "Moderate Anemia Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
    } else {
        const nextNovDate = getNextNovDate(programEncounter);
        scheduleBuilder.add({
            name: "Moderate Anemia Followup",
            encounterType: "Moderate Anemia Followup",
            earliestDate: nextNovDate.toDate(),
            maxDate: nextNovDate.add(15, "days").toDate()
        });
    }


};

@ModerateAnemiaFollowup("5959b803-b098-44f7-9ca9-cf14fc7c7837", "Moderate Anemia Followup", 100.0)
class ModerateAnemiaFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter) &&
            new RuleCondition({programEncounter}).when
                .valueInEncounter("HB after 3 months of treatment")
                .is.lessThanOrEqualTo(10).matches()) {
            moderateAnemiaFollowup({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const severeMalnutritionFollowup = ({programEncounter}, scheduleBuilder, cancelSchedule) => {
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
            lib.C.calculateBMI(weightObs.getReadableValue(), heightObs.getReadableValue()) < 18.5) ||
        false;

    if (isUnderweight) {
        if (cancelSchedule) {
            const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
                ? moment().add(1, "month")
                : moment(programEncounter.earliestVisitDateTime).add(3, "month");
            scheduleBuilder.add({
                name: "Severe Malnutrition Followup",
                encounterType: "Severe Malnutrition Followup",
                earliestDate: nextVisitDate.toDate(),
                maxDate: nextVisitDate.add(15, "days").toDate()
            });
        } else {
            const nextNovDate = getNextNovDate(programEncounter);
            scheduleBuilder.add({
                name: "Severe Malnutrition Followup",
                encounterType: "Severe Malnutrition Followup",
                earliestDate: nextNovDate.toDate(),
                maxDate: nextNovDate.add(15, "days").toDate()
            });
        }
    }

};

@SeverMalnutritionFollowup("2bf7b5fd-adfe-49f1-b249-48482ef6e6e8", "Sever Malnutrition Followup", 100.0)
class SeverMalnutritionFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            severeMalnutritionFollowup({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const addictionVulnerabilityFollowup = ({programEncounter}, scheduleBuilder, cancelSchedule) => {
    if (cancelSchedule) {
        const nextVisitDate = getNextCancelDate(programEncounter);
        scheduleBuilder.add({
            name: "Addiction Followup",
            encounterType: "Addiction Followup",
            earliestDate: nextVisitDate.toDate(),
            maxDate: nextVisitDate.add(15, "days").toDate()
        });
    } else {
        const nextNovDate = getNextNovDate(programEncounter);
        scheduleBuilder.add({
            name: "Addiction Followup",
            encounterType: "Addiction Followup",
            earliestDate: nextNovDate.toDate(),
            maxDate: nextNovDate.add(15, "days").toDate()
        });
    }
};

@AddictionVulnerabilityFollowup("beca45b9-f037-4d3f-906d-5970018ce5bb", "Addiction Vulnerability Followup", 100.0)
class AddictionVulnerabilityFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter) &&
            new RuleCondition({programEncounter})
                .when.valueInEncounter('Knowing about hazards of tobacco have you quit tobacco/alcohol')
                .is.no.matches()) {
            addictionVulnerabilityFollowup({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

const sickleCellVulnerabilityFollowup = ({programEncounter}, scheduleBuilder) => {
    const nextVisitDate = _.isNil(programEncounter.earliestVisitDateTime)
        ? moment().add(1, "month")
        : moment(programEncounter.earliestVisitDateTime).add(1, "month");
    scheduleBuilder.add({
        name: "Sickle Cell Followup",
        encounterType: "Sickle Cell Followup",
        earliestDate: nextVisitDate.toDate(),
        maxDate: nextVisitDate.add(15, "days").toDate()
    });
};

@SickleCellVulnerabilityFollowup("d85c8fd0-a5bf-49f3-9eb2-b67ef7af9f5c", "Sickle Cell Vulnerability Followup", 100.0)
class SickleCellVulnerabilityFollowupSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            sickleCellVulnerabilityFollowup({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

@EndlineVisitSchedule("e3178743-b08c-46b1-a166-b3c70e315dd8", "Endline Visit ", 100.0)
class EndlineVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            CommonSchedule.scheduleNextRegularVisitFromEndline({programEncounter}, scheduleBuilder);
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
    }
}

@VisitRescheduleOnCancel("90fc6da7-af26-45cc-b48f-6daf9e73c918", "Visit Reschedule on cancellation", 100.0)
class VisitRescheduleOnCancelSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({programEncounter});

        if (!hasExitedProgram(programEncounter)) {
            switch (programEncounter.encounterType.name) {
                case 'Addiction Followup':
                    addictionVulnerabilityFollowup({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Severe Malnutrition Followup':
                    severeMalnutritionFollowup({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Moderate Anemia Followup':
                    moderateAnemiaFollowup({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Severe Anemia Followup':
                    severeAnemiaFollowup({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Menstrual Disorder Followup':
                    scheduleMenstrualDisorderFollowup({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Chronic Sickness Followup':
                    scheduleChronicSicknessFollowupSchedule({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Sickle Cell Followup':
                    sickleCellVulnerabilityFollowup({programEncounter}, scheduleBuilder, true);
                    break;
                case 'Dropout Followup Visit':
                    addDropoutFollowUpVisits(programEncounter, scheduleBuilder, true);
                    break;
                case 'Dropout Home Visit':
                    addDropoutHomeVisits(programEncounter, scheduleBuilder, true);
                    break;
                case 'Quarterly Visit':
                    CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);
                    break;
                case 'Annual Visit':
                    CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);
                    CommonSchedule.addEndlineVisitAnnual({programEncounter}, scheduleBuilder);
                    break;
                case 'Endline Visit':
                    CommonSchedule.scheduleNextRegularVisitFromEndline({programEncounter}, scheduleBuilder);
                    break
            }
        }

        return scheduleBuilder.getAllUnique("encounterType", true);
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
    DropoutVisitScheduleHandler,
    CommonSchedule,
    VisitRescheduleOnCancelSR,
    EndlineVisitScheduleSR,
};
