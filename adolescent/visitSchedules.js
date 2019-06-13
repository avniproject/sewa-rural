import {RuleFactory, VisitScheduleBuilder} from "rules-config";

const GMVisitSchedule = RuleFactory("", "VisitSchedule");

@GMVisitSchedule("5daad80c-80c5-4471-b972-80aaab3e9592", "JSS Growth Monitoring Recurring Visit", 100.0)
class GMVisitScheduleJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {

        //not scheduling next visit when recording unplanned visit
        if(_.isNil(programEncounter.earliestVisitDateTime)){
            return [];
        }

        const scheduleBuilder = new VisitScheduleBuilder({
            programEnrolment: programEncounter.programEnrolment
        });
        // const scheduledDateTime = programEncounter.earliestVisitDateTime;
        // const scheduledDate = moment(scheduledDateTime).date();
        // const encounterDateTime = programEncounter.encounterDateTime;
        // const dayOfMonth = programEncounter.programEnrolment.findObservation("Day of month for growth monitoring visit").getValue();
        // var monthForNextVisit = moment(scheduledDateTime).month() + 1;
        // var earliestDate = moment(scheduledDateTime).month(monthForNextVisit).date(dayOfMonth).toDate();
        // if(moment(earliestDate).month() !== monthForNextVisit){
        //     earliestDate = moment(scheduledDateTime).add(1, 'M').endOf('month').toDate();
        // }
        // const maxDate = moment(earliestDate).add(3, 'days').toDate();
        // visitSchedule.forEach((vs) => scheduleBuilder.add(vs));
        // scheduleBuilder.add({
        //         name: "Growth Monitoring Visit",
        //         encounterType: "Anthropometry Assessment",
        //         earliestDate: earliestDate,
        //         maxDate: maxDate
        //     }
        // );
        return scheduleBuilder.getAllUnique("encounterType");

    }
}



export {
    GMVisitScheduleJSS,
}
