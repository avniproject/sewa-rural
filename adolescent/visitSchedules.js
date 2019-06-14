import {RuleFactory, VisitScheduleBuilder, RuleCondition} from "rules-config";
import moment from "moment";
import _ from "lodash";

const AnnualVisitSchedule = RuleFactory("92cd5f05-eec3-4e70-9537-62119c5e3a16", "VisitSchedule");
const ChronicSicknessFollowup = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "VisitSchedule");

@AnnualVisitSchedule("02c00bfd-2190-4d0a-8c1d-5d4596badc29", "Sickle Cell Followup", 100.0)
class AnnualVisitScheduleSR {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const programEnrolment = programEncounter.programEnrolment;
        let context = {
            programEncounter: programEncounter,
            programEnrolment: programEnrolment,
        };
        const scheduleBuilder = new VisitScheduleBuilder(context);

        if(programEncounter.encounterType.name === "Annual Visit") {
            let oneMonthFromNow =
                moment().add(1, "month").startOf("day");

            if(new RuleCondition(context).when.valueInEncounter("Sickling Test Result").containsAnswerConceptName("Disease").matches()) {
                scheduleBuilder.add({
                    name: "Sickle Cell Vulnerability Followup",
                    encounterType: "Sickle Cell Vulnerability",
                    earliestDate: oneMonthFromNow.toDate(),
                    maxDate: moment(oneMonthFromNow).add(15, "days").endOf("day").toDate()
                });
            }

            if(new RuleCondition(context).when
                .valueInEncounter("Is there any other condition you want to mention about him/her?")
                .containsAnswerConceptNameOtherThan("No problem")
                .or
                .valueInEncounter("Sickness in last 1 months")
                .containsAnswerConceptNameOtherThan("No sickness")
                .matches()
            ) {
                scheduleBuilder.add({
                    name: "Chronic Sickness Followup",
                    encounterType: "Chronic Sickness",
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
        }

        if(programEncounter.encounterType.name === "Quarterly Visit") {

            const currentMonth = moment().format("MMMM");
            const visitTable = {
                "October": {"nextMonth": "January", "incrementInYear": 1},
                "January": {"nextMonth": "May", "incrementInYear": 0},
                "May": {"nextMonth": "October", "incrementInYear": 0},
            };

            if(visitTable[currentMonth]) {
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
