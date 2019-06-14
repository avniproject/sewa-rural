const _ = require('lodash');

module.exports = _.merge({},
    require('./adolescent/sickleCellFormHandler'),
    require('./adolescent/visitSchedules'),
    require('./adolescent/chronicSicknessFormHandler'),
    require('./adolescent/menstrualDisorderHandler'),
);
