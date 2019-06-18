const _ = require("lodash");
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    StatusBuilderAnnotationFactory,
    WithName,
} from 'rules-config/rules';


const ChronicSicknessViewFilter = RuleFactory("dac9f78d-c0d5-48ff-ba0e-cb48106437b9", "ViewFilter");
const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');


@ChronicSicknessViewFilter('9802b91b-1d1c-4717-ba7c-7c7bb84d100e', 'Chronic Sickness View Filter', 100.0, {})
class ChronicSicknessViewFilterSR{
    static exec(programEncounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new ChronicSicknessViewFilterSR(), programEncounter, formElementGroup, today);
    }

    @WithName("Have you visited hospital?")
    @WithStatusBuilder
    abc1([programEncounter], statusBuilder) {
        statusBuilder.show().when.valueInEncounter("Do you know what problem do you have?").is.yes;
    }

    @WithName("Are you taking treatment regularly?")
    @WithStatusBuilder
    abc2([programEncounter], statusBuilder){
        statusBuilder.show().when.valueInEncounter("Have you visited hospital?").is.no;
    }

    @WithName("If not cured reffer to hospital again")
    @WithStatusBuilder
    abc3([programEncounter], statusBuilder){
        statusBuilder.show().when.valueInEncounter("Is your condition cured?").is.no;
    }

    @WithName("Counseling done?")
    @WithStatusBuilder
    abc4([programEncounter], statusBuilder){
        statusBuilder.show().when.valueInEncounter("Is your condition cured?").is.no;
    }

    @WithName("Home visit done?")
    @WithStatusBuilder
    abc5([programEncounter], statusBuilder){
        statusBuilder.show().when.valueInEncounter("Is your condition cured?").is.no;
    }

    @WithName("cured ?")
    @WithStatusBuilder
    abc6([programEncounter], statusBuilder){
        statusBuilder.show().when.valueInEncounter("Is your condition cured?").is.no;
    }
}

module.exports = {ChronicSicknessViewFilterSR};
