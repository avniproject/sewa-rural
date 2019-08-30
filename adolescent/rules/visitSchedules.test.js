import {ProgramEnrolment, ProgramEncounter, EncounterType} from 'openchs-models';
import {AnnualVisitScheduleSR, CommonSchedule} from './visitSchedules';
import {VisitScheduleBuilder} from "rules-config";

describe('Visit schedules. ', () => {
    describe('Regular visit schedules', () => {
        it('should schedule a quarterly visit after an annual visit', () => {
            const programEncounter = ProgramEncounter.createEmptyInstance();
            programEncounter.earliestVisitDateTime = new Date(2019, 6, 1);
            programEncounter.encounterType = EncounterType.create('Annual Visit');
            const scheduleBuilder = new VisitScheduleBuilder({
                programEncounter: programEncounter,
            });

            CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);

            const schedule = scheduleBuilder.getAll();
            expect(schedule.length).toBe(1);

            const visit = schedule[0];
            expect(visit.encounterType).toBe('Quarterly Visit');
        });

        it('should schedule a quarterly visit after an October Quarterly visit', () => {
            const programEncounter = ProgramEncounter.createEmptyInstance();
            programEncounter.earliestVisitDateTime = new Date(2019, 9, 1);
            programEncounter.encounterType = EncounterType.create('Annual Visit');
            const scheduleBuilder = new VisitScheduleBuilder({
                programEncounter: programEncounter,
            });

            CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);

            const schedule = scheduleBuilder.getAll();
            expect(schedule.length).toBe(1);

            const visit = schedule[0];
            expect(visit.encounterType).toBe('Quarterly Visit');
        });

        it('should schedule annual visit after a May Quarterly visit', () => {
            const programEncounter = ProgramEncounter.createEmptyInstance();
            programEncounter.earliestVisitDateTime = new Date(2019, 4, 1);
            programEncounter.encounterType = EncounterType.create('Quarterly Visit');
            const scheduleBuilder = new VisitScheduleBuilder({
                programEncounter: programEncounter,
            });

            CommonSchedule.scheduleNextRegularVisit({programEncounter}, scheduleBuilder);

            const schedule = scheduleBuilder.getAll();
            expect(schedule.length).toBe(1);

            const visit = schedule[0];
            expect(visit.encounterType).toBe('Annual Visit');
        });
    });

    describe('After an annual visit', () => {
        it('a quarterly visit is scheduled if it happens in July', () => {
            global.ruleServiceLibraryInterfaceForSharingModules = {
                common: {
                    addDays: (date) => new Date(date)
                }
            };
            const programEnrolment = ProgramEnrolment.createEmptyInstance();
            const programEncounter = ProgramEncounter.createEmptyInstance();
            programEncounter.earliestVisitDateTime = new Date(2019, 6, 1);
            programEncounter.encounterType = EncounterType.create('Quarterly Visit');
            programEnrolment.addEncounter(programEncounter);
            programEncounter.programEnrolment = programEnrolment;

            const visitSchedules = AnnualVisitScheduleSR.exec(programEncounter);

            const quarterlyVisitSchedule = visitSchedules.find((schedule) => schedule.encounterType === 'Quarterly Visit');
            expect(quarterlyVisitSchedule).toBeDefined();
        });
        it('another annual visit is scheduled if it happens in June', () => {
            global.ruleServiceLibraryInterfaceForSharingModules = {
                common: {
                    addDays: (date) => new Date(date)
                }
            };
            const programEnrolment = ProgramEnrolment.createEmptyInstance();
            const programEncounter = ProgramEncounter.createEmptyInstance();
            programEncounter.earliestVisitDateTime = new Date(2019, 5, 1);
            programEncounter.encounterType = EncounterType.create('Annual Visit');
            programEnrolment.addEncounter(programEncounter);
            programEncounter.programEnrolment = programEnrolment;

            const visitSchedules = AnnualVisitScheduleSR.exec(programEncounter);

            const quarterlyVisitSchedule = visitSchedules.find((schedule) => schedule.encounterType === 'Annual Visit');
            expect(quarterlyVisitSchedule).toBeDefined();
        });
    });
});