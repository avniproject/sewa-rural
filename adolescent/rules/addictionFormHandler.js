const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName
} from "rules-config/rules";

const AddictionViewFilter = RuleFactory("8aec0b76-79ae-4e47-9375-ed9db3739997", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory("programEncounter", "formElement");

@AddictionViewFilter("af926a15-0068-45a5-be48-c8bf55bde9e2", "AddictionVulnerabilityViewFilter", 100.0, {})
class AddictionVulnerabilityViewFilter {
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper.getFormElementsStatusesWithoutDefaults(
            new AddictionVulnerabilityViewFilter(),
            programEncounter,
            formElementGroup,
            today
        );
    }

    @WithName("If tobacco, what is the type?")
    @WithName("Since how many years are you addicted to tobacco?")
    @WithStatusBuilder
    iftobaccoWhatIsTheType([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInPreviousEncounters("Addiction Details")
            .containsAnyAnswerConceptName("Tobacco", "Both");
    }

    @WithName("How many pouches do you consume per day?")
    @WithStatusBuilder
    howManyPouchesDoYouConsumePerDay([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Type of tobacco")
            .containsAnyAnswerConceptName("Chewable");
    }

    @WithName("How many cigarettes/bidis do you consume per day?")
    @WithStatusBuilder
    howManyCigarettesbidisDoYouConsumePerDay([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Type of tobacco")
            .containsAnyAnswerConceptName("Non Chewable");
    }

    @WithName("How much money you spend daily for tobacco pouches or bidi?")
    @WithStatusBuilder
    howMuchMoneyYouSpendDailyForTobaccoPouchesOrBidi([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInPreviousEncounters("Addiction Details")
            .containsAnyAnswerConceptName("Tobacco", "Both");
    }

    @WithName("If alcohol, frequency of consumption")
    @WithStatusBuilder
    ifAlcoholFrequencyOfConsumption([], statusBuilder) {
        statusBuilder
            .show()
            .when.latestValueInPreviousEncounters("Addiction Details")
            .containsAnyAnswerConceptName("Alcohol", "Both");
    }

    @WithName("Whether visited hospital")
    @WithStatusBuilder
    haveYouVisitedHospital([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Is referred")
            .containsAnyAnswerConceptName("Yes");
    }

    @WithName("If yes quitted then how many days?")
    @WithStatusBuilder
    ifYesQuittedThenHowManyDays([], statusBuilder) {
        statusBuilder
            .show()
            .when.valueInEncounter("Knowing about hazards of tobacco have you quit tobacco/alcohol")
            .containsAnyAnswerConceptName("Yes");
    }
}

module.exports = {AddictionVulnerabilityViewFilter};
