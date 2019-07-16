import {FormElementsStatusHelper} from "rules-config/rules";
import DropoutEncounterFormHandler from "../formFilters/DropoutEncounterFormHandler";
import {RuleFactory} from "rules-config/rules";
import AnnualVisitHandler from "../formFilters/AnnualVisitHandler";
import QuarterlyVisitHandler from "../formFilters/QuarterlyVisitHandler";

const RoutineVisitViewFilters = RuleFactory("35e54f14-3a23-45a3-b90e-5383fa026ffd", "ViewFilter");
const QuarterlyRoutineVisitViewFilters = RuleFactory("a8c1f2a0-f4e0-4190-b0c3-bd81f21bef6c", "ViewFilter");
const DropoutHomeViewFilters = RuleFactory("54636d6b-33bf-4faf-9397-eb3b1d9b1792", "ViewFilter");
const DropoutFollowUpViewFilters = RuleFactory("0c444bf3-54c3-41e4-8ca9-f0deb8760831", "ViewFilter");

const encounterTypeHandlerMap = new Map([
    ["Annual Visit", new AnnualVisitHandler()],
    ["Quarterly Visit", new QuarterlyVisitHandler()],
    ["Dropout Home Visit", new DropoutEncounterFormHandler()]
]);

const getFormElementsStatuses = (programEncounter, formElementGroup) => {
    let handler = encounterTypeHandlerMap.get(programEncounter.encounterType.name);
    return FormElementsStatusHelper.getFormElementsStatuses(handler, programEncounter, formElementGroup);
};

@QuarterlyRoutineVisitViewFilters("ff0482b5-82e6-4675-a9df-245043859a94", "Quarterly Routine Visit Filter", 1.0)
class QuarterlyRoutineFilterHandler {
    static exec(programEncounter, formElementGroup) {
        return getFormElementsStatuses(programEncounter, formElementGroup);
    }
}

@RoutineVisitViewFilters("36954eff-0eab-446a-a955-f2690c2aadeb", "All Routine Visit Filter", 1.0)
class RoutineFilterHandler {
    static exec(programEncounter, formElementGroup) {
        return getFormElementsStatuses(programEncounter, formElementGroup);
    }
}

@DropoutHomeViewFilters("fa135fc8-4f85-43af-bcf1-39c954a70d8e", "All Dropout Home Visit Filter", 1.0)
class DHFilterHandler {
    static exec(programEncounter, formElementGroup) {
        return getFormElementsStatuses(programEncounter, formElementGroup);
    }
}

@DropoutFollowUpViewFilters("bb6839e8-93a0-4444-8031-268ae410ed09", "All Dropout Followup Visit Filter", 1.0)
class DFFilterHandler {
    static exec(programEncounter, formElementGroup) {
        return getFormElementsStatuses(programEncounter, formElementGroup);
    }
}

export {RoutineFilterHandler, QuarterlyRoutineFilterHandler, DHFilterHandler, DFFilterHandler};
