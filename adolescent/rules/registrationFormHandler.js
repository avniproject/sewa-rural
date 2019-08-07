import {
    RuleFactory,
    FormElementsStatusHelper,
    StatusBuilderAnnotationFactory,
    WithName
} from 'rules-config/rules';


const WithRegistrationStatusBuilder = StatusBuilderAnnotationFactory('individual', 'formElement');
const RegistrationViewFilter = RuleFactory("6fd2d292-c5bc-4e2d-b4d5-9de1e7026916", "ViewFilter");


@RegistrationViewFilter("c8813bbf-a8b5-450e-bd1c-e62f23867ee0", "Sewa Rural Registration View Filter", 100.0, {})
class RegistrationViewHandlerSR {
    static exec(individual, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new RegistrationViewHandlerSR(), individual, formElementGroup);
    }

    @WithName("Specify Other")
    @WithRegistrationStatusBuilder
    abc1([], statusBuilder) {
        statusBuilder.show().when.valueInRegistration("Block").containsAnswerConceptName("Other");
    }
}

module.exports = {RegistrationViewHandlerSR};
