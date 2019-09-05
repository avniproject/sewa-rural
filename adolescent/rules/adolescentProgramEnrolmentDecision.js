import ExitFormHandler from "../formFilters/ExitFormHandler";
import {FormElementsStatusHelper, RuleFactory, VisitScheduleBuilder} from "rules-config/rules";
import lib from "../../lib";

const ExitFilters = RuleFactory("5f8dc84d-90ff-46ca-9a56-169bd778687f", "ViewFilter");
const AdolscentEnrolmentVisitSchedule = RuleFactory("32b3555a-7fe9-4246-a470-21ab2d2954e2", "VisitSchedule");

@ExitFilters("f0b042a5-4232-46cb-b5c3-b320fc0fce48", "Adolescent exit form filters", 1, {})
class ExitFilterHandler {
    static exec(enrolment, formElementGroup) {
        return FormElementsStatusHelper.getFormElementsStatuses(new ExitFormHandler(), enrolment, formElementGroup);
    }
}

@AdolscentEnrolmentVisitSchedule("9b1d79e4-fa15-406b-8410-1f46dc64613f", "Adolescent Enrolment Visit Schedule", 1.0, {})
class AdolscentEnrolmentVisitScheduleHandler {
    static exec(enrolment, schedule, visitScheduleConfig) {
        console.log('visit schedule invoked')
        const scheduleBuilder = new VisitScheduleBuilder({programEnrolment: enrolment});
        scheduleBuilder
            .add({
                name: "Annual Visit",
                encounterType: "Annual Visit",
                earliestDate: enrolment.enrolmentDateTime,
                maxDate: lib.C.addDays(lib.C.copyDate(enrolment.enrolmentDateTime), 10)
            })
            .whenItem(enrolment.getEncounters(true).length)
            .equals(0);
        return scheduleBuilder.getAll();
    }
}

export {ExitFilterHandler, AdolscentEnrolmentVisitScheduleHandler};
