import {complicationsBuilder as ComplicationsBuilder, ProgramRule} from "rules-config/rules";
import moment from 'moment';
import _ from 'lodash';

const has = "containsAnyAnswerConceptName",
    latest = "latestValueInAllEncounters";

@ProgramRule({
    name: "Adolescent program summary",
    uuid: "ad472cca-f454-4222-8aee-c1b0addf8651",
    programUUID: "215f4795-7d46-4617-95dd-52343f945a0f",
    executionOrder: 100.0,
    metadata: {}
})
class AdolescentProgramSummary {
    static getNutritionalStatus(programEnrolment) {
        const builder = new ComplicationsBuilder({
            programEnrolment: programEnrolment,
            individual: programEnrolment.individual,
            complicationsConcept: "Nutritional Status"
        });

        const add = builder.addComplication.bind(builder);

        add("332a435b-069c-4283-a4f7-4310d7e458d7")
            .when[latest]("BMI")
            .lessThan(14.5);
        add("41b2db08-99a4-428c-a908-641330858b8a")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(14.5)
            .and.when[latest]("BMI")
            .lessThanOrEqualTo(18.5);
        add("ba43b326-18a1-4f8d-ad04-29b0371461e0")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(18.6)
            .and.when[latest]("BMI")
            .lessThanOrEqualTo(24.9);
        add("74481c32-e400-4103-b656-b4f52e517fdd")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(25)
            .and.when[latest]("BMI")
            .lessThanOrEqualTo(29.9);
        add("c7512031-62fb-4bbc-b793-7fde56d45883")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(30);

        const complications = builder.getComplications();
        complications.abnormal = true;
        return complications;
    }

    static getAnemiaStatus(programEnrolment) {
        const builder = new ComplicationsBuilder({
            programEnrolment: programEnrolment,
            individual: programEnrolment.individual,
            complicationsConcept: "Anemia Status"
        });

        const add = builder.addComplication.bind(builder);
        add("8d9b69e1-9efe-410f-8063-71767b6482f6")
            .when[latest]("Hb")
            .lessThanOrEqualTo(7);
        add("5d04a0e1-548e-418b-bad3-3cb4ae184fdd")
            .when[latest]("Hb")
            .greaterThanOrEqualTo(7.1)
            .and.when[latest]("Hb")
            .lessThanOrEqualTo(10);

        const complications = builder.getComplications();
        complications.abnormal = true;
        return complications;
    }

    static getOtherComplications(programEnrolment) {
        const builder = new ComplicationsBuilder({
            programEnrolment: programEnrolment,
            individual: programEnrolment.individual,
            complicationsConcept: "Other Vulnerabilities"
        });
        const add = builder.addComplication.bind(builder);

        add("b5e3310a-7628-40d9-8bb3-961a6c302c84")
            .when[latest]("School going")
            [has]("Dropped Out");
        add("b13eb71b-f117-41c6-b8a0-88743ed64175")
            .when[latest]("Are you able to do daily routine work during menstruation?")
            [has]("Yes")
            .or.when[latest]("Does she remain absent during menstruation?")
            [has]("Yes");
        add("f03ac7c5-b520-4f59-8de7-add48d05d68e")
            .when[latest]("Addiction Details")
            [has]("Alcohol", "Tobacco", "Both");
        add("67a48afe-2706-4c22-a7ba-5c27371c5542")
            .when[latest]("Is there any other condition you want to mention about him/her?")
            [has]("Heart problem", "Kidney problem", "Sickle cell disease", "Epilepsy", "Other");

        const complications = builder.getComplications();
        complications.abnormal = true;
        return complications;
    }

    static exec(programEnrolment, summaries, context, today) {
        this.pushToSummaries(AdolescentProgramSummary.getNutritionalStatus(programEnrolment), summaries);
        const sickleTestResult = programEnrolment.findObservationInEntireEnrolment("Sickling Test Result");
        if (sickleTestResult && !_.isNil(sickleTestResult.getReadableValue())) {
            summaries.push({name: "Sickle Cell", value: sickleTestResult.getReadableValue()});
        }
        this.pushToSummaries(AdolescentProgramSummary.getAnemiaStatus(programEnrolment), summaries);
        this.pushToSummaries(AdolescentProgramSummary.getOtherComplications(programEnrolment), summaries);
        const hbValues = programEnrolment.getObservationsForConceptName('Hb');
        if (!_.isEmpty(hbValues)) {
            const value = hbValues.map(({encounterDateTime, obs}) => (`${moment(encounterDateTime).format("DD-MM-YYYY")}: ${obs}g/dL`))
                .join(", ");
            summaries.push({name: "HB values", value: value})
        }
        const bmiValues = programEnrolment.getObservationsForConceptName('BMI');

        if (!_.isEmpty(bmiValues)) {
            const value = bmiValues.map(({encounterDateTime, obs}) => (`${moment(encounterDateTime).format("DD-MM-YYYY")}: ${obs}kg/m²`))
                .join(", ");
            summaries.push({name: "BMI values", value: value})
        }
        return summaries;
    }

    static pushToSummaries(vulnerability, summaries) {
        if (vulnerability.value.length) {
            summaries.push(vulnerability);
        }
    }
}

export {AdolescentProgramSummary};
