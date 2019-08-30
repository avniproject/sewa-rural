//Note that this is just for tests. Babel and webpack config required to
// deploy are provided by openchs-idi.
module.exports = {
    presets: [
        [
            '@babel/preset-env',
            {
                targets: {
                    node: 'current',
                },
            },
        ],
    ],
    plugins: [
        ["@babel/plugin-proposal-decorators", { "legacy": true }],
        ["@babel/plugin-proposal-class-properties", { "loose" : true }]
    ]
    // plugins: [
    //     "transform-class-properties",
    //     "transform-export-extensions",
    //     "transform-es2015-destructuring",
    //     ["@babel/plugin-proposal-decorators", {"legacy": true}],
    // ]
};