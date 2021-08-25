//Active adolescents
'use strict';
({params, imports}) => {
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
};

//Adolescents having severe anemia
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit' OR encounterType.name = 'Quarterly Visit' OR encounterType.name = 'Endline Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => enc.getObservationReadableValue('Hb') <= 7)
        .map(enc => enc.programEnrolment.individual)
};

//Adolescents having moderate anemia
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit' OR encounterType.name = 'Quarterly Visit' OR encounterType.name = 'Endline Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => {
            const hb = enc.getObservationReadableValue('Hb');
            return hb >= 7.1 && hb <= 10;
        })
        .map(enc => enc.programEnrolment.individual)
};


//Adolescents having sickle disease
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEnrolment')
        .filtered(`individual.voided = false AND voided = false AND program.name = 'Adolescent' AND programExitDateTime = null`)
        .filtered('TRUEPREDICATE sort(individual.uuid asc , enrolmentDateTime desc) Distinct(individual.uuid)')
        .filtered(`SUBQUERY(encounters, $encounter, $encounter.voided = false and SUBQUERY($encounter.observations, $observation, $observation.concept.uuid = 'b5daf90d-5b71-4b53-827f-edd4f6539d15' and ($observation.valueJSON contains '2c343c7a-db14-4531-902a-d7b169300073')).@count > 0).@count > 0`)
        .map(enl => enl.individual)
};

//Adolescents absent due to menstrual disorders
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit' OR encounterType.name = 'Quarterly Visit' OR encounterType.name = 'Endline Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => enc.getObservationReadableValue('Does she remain absent during menstruation?') === 'Yes')
        .map(enc => enc.programEnrolment.individual)
};

//Adolescents having chronic sickness
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => !_.includes(enc.getObservationReadableValue('Is there any other condition you want to mention about him/her?'), 'No problem'))
        .map(enc => enc.programEnrolment.individual)
};

//Adolescents having severe malnutrition
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit' OR encounterType.name = 'Endline Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => enc.getObservationReadableValue('BMI') < 18.5)
        .map(enc => enc.programEnrolment.individual)
};

//Adolescents who dropped out of school
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit' OR encounterType.name = 'Quarterly Visit' OR encounterType.name = 'Endline Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => enc.getObservationReadableValue('School going') === 'Dropped Out')
        .map(enc => enc.programEnrolment.individual)
};


//Adolescents having addiction
'use strict';
({params, imports}) => {
    return params.db.objects('ProgramEncounter')
        .filtered(`programEnrolment.individual.voided = false AND programEnrolment.voided = false AND programEnrolment.program.name = 'Adolescent' AND programEnrolment.programExitDateTime = null AND voided = false AND encounterDateTime <> null AND (encounterType.name = 'Annual Visit' OR encounterType.name = 'Quarterly Visit')`)
        .filtered('TRUEPREDICATE sort(programEnrolment.individual.uuid asc , encounterDateTime desc) Distinct(programEnrolment.individual.uuid)')
        .filter(enc => _.includes(["Alcohol", "Tobacco", "Both"],enc.getObservationReadableValue('Addiction Details')))
        .map(enc => enc.programEnrolment.individual)
};

//Adolescents exited
'use strict';
({params, imports}) => {
    const moment = imports.moment;
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime <> null and $enrolment.voided = false).@count > 0 and voided = false`)
};
