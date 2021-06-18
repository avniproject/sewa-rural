//Active adolescents
'use strict';
({params, imports}) => {
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
};

//Adolescents having severe anemia
'use strict';
({params, imports}) => {
    const isSevereAnemia = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Quarterly Visit", "Endline Visit");
        const hb = latestVisit && latestVisit.getObservationReadableValue('Hb');
        return hb ? hb <= 7 : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => isSevereAnemia(enrolment)))
};

//Adolescents having moderate anemia
'use strict';
({params, imports}) => {
    const isModerateAnemia = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Quarterly Visit", "Endline Visit");
        const hb = latestVisit && latestVisit.getObservationReadableValue('Hb');
        return hb ? (hb >= 7.1 && hb <= 10) : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => isModerateAnemia(enrolment)))
};


//Adolescents having sickle disease
'use strict';
({params, imports}) => {
    const isSickleDisease = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Quarterly Visit", "Endline Visit");
        const result = latestVisit && latestVisit.getObservationReadableValue('Sickling Test Result');
        return result ? result === 'Disease' : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => isSickleDisease(enrolment)))
};

//Adolescents absent due to menstrual disorders
'use strict';
({params, imports}) => {
    const isAbsentDueToMensDisorder = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Quarterly Visit", "Endline Visit");
        const isAbsent = latestVisit && latestVisit.getObservationReadableValue('Does she remain absent during menstruation?');
        return isAbsent ? isAbsent === 'Yes' : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => isAbsentDueToMensDisorder(enrolment)))
};

//Adolescents having chronic sickness
'use strict';
({params, imports}) => {
    const hasChronicSickness = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit");
        const chronicSickness = latestVisit && latestVisit.getObservationReadableValue('Is there any other condition you want to mention about him/her?');
        return chronicSickness ? !_.includes(chronicSickness, 'No problem') : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => hasChronicSickness(enrolment)))
};

//Adolescents having severe malnutrition
'use strict';
({params, imports}) => {
    const hasSevereMalnutrition = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Endline Visit");
        const bmi = latestVisit && latestVisit.getObservationReadableValue('BMI');
        return bmi ? bmi < 18.5 : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => hasSevereMalnutrition(enrolment)))
};

//Adolescents who dropped out of school
'use strict';
({params, imports}) => {
    const isSchoolDropout = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Quarterly Visit", "Endline Visit");
        const schoolGoing = latestVisit && latestVisit.getObservationReadableValue('School going');
        return schoolGoing ? schoolGoing === 'Dropped Out' : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => isSchoolDropout(enrolment)))
};


//Adolescents having addiction
'use strict';
({params, imports}) => {
    const hasAddiction = (enrolment) => {
        const latestVisit = enrolment.lastFulfilledEncounter("Annual Visit", "Quarterly Visit");
        const addiction = latestVisit && latestVisit.getObservationReadableValue('Addiction Details');
        return addiction ? _.includes(["Alcohol", "Tobacco", "Both"], addiction) : false;
    };
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0 and voided = false`)
        .filter((individual) => _.some(individual.enrolments, (enrolment) => hasAddiction(enrolment)))
};

//Adolescents exited
'use strict';
({params, imports}) => {
    const moment = imports.moment;
    return params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Adolescent' and $enrolment.programExitDateTime <> null and $enrolment.voided = false).@count > 0 and voided = false`)
};
