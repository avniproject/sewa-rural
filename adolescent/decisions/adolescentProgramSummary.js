import {complicationsBuilder as ComplicationsBuilder, ProgramRule} from "rules-config/rules";

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

        add("Severely malnourished")
            .when[latest]("BMI")
            .lessThan(14.5);
        add("Underweight")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(14.5)
            .and.when[latest]("BMI")
            .lessThanOrEqualTo(18.5);
        add("Normal")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(18.6)
            .and.when[latest]("BMI")
            .lessThanOrEqualTo(24.9);
        add("Overweight")
            .when[latest]("BMI")
            .greaterThanOrEqualTo(25)
            .and.when[latest]("BMI")
            .lessThanOrEqualTo(29.9);
        add("Obese")
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
        add("Severe")
            .when[latest]("Hb")
            .lessThanOrEqualTo(7);
        add("Moderate")
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

        add("School dropout")
            .when[latest]("School going")
            [has]("Dropped Out");
        add("Menstrual absenteeism")
            .when[latest]("Are you able to do daily routine work during menstruation?")
            [has]("Yes")
            .or.when[latest]("Does she remain absent during menstruation?")
            [has]("Yes");
        add("Addiction (Self)")
            .when[latest]("Addiction Details")
            [has]("Alcohol", "Tobacco", "Both");
        add("Chronic Sickness")
            .when[latest]("Is there any other condition you want to mention about him/her?")
            [has]("Heart problem", "Kidney problem", "Sickle cell disease", "Epilepsy", "Other");

        const complications = builder.getComplications();
        complications.abnormal = true;
        return complications;
    }

    static exec(programEnrolment, summaries, context, today) {
        this.pushToSummaries(AdolescentProgramSummary.getNutritionalStatus(programEnrolment), summaries, context);
        const sickleTestResult = programEnrolment.findObservationInEntireEnrolment("Sickling Test Result");
        if (sickleTestResult && !_.isNil(sickleTestResult.getReadableValue())) {
            summaries.push({name: "Sickle Cell", value: sickleTestResult.getReadableValue()});
        }
        this.pushToSummaries(AdolescentProgramSummary.getAnemiaStatus(programEnrolment), summaries, context);
        this.pushToSummaries(AdolescentProgramSummary.getOtherComplications(programEnrolment), summaries, context);
        return summaries;
    }

    static pushToSummaries(vulnerability, summaries, context) {
        const conceptService = context.get("conceptService");
        vulnerability.value = vulnerability.value.map(name => conceptService.conceptFor(name).uuid);
        if (vulnerability.value.length) {
            summaries.push(vulnerability);
        }
    }
}

export {AdolescentProgramSummary};
