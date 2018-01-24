/* Quick guide to BackstopJS commands (these commands assume global install)

  backstop reference --configPath=backstop.js --env=local --refHost=http://site.dev
  backstop test --configPath=backstop.js --env=local --testHost=http://site.dev

*/

var args = require('minimist')(process.argv.slice(2)); // grabs the process arguments
var dotenv = require('dotenv').config(); // handles basic auth
var glob = require('glob-fs')({ gitignore: true }); // handles globbing scenarios
var fs = require('fs'); // reads scenario files
var defaultPaths = ['/']; // default path just checks the homepage as a quick smoke test
var scenarios = []; // The array that'll have the URL paths to check
var localhost = 'http://localhost:8000';
var projName = '';

fs.readFile('/app/.lando.yml', (err, data) => {
  if (!err) {
    lando = data.toString().split("\n");
    for(i in lando) {
      if (lando[i].indexOf('name:') > -1) {
        projName = lando[i].replace('name: ', '');
        localhost = 'http://' + projName + '.lndo.site';
      }
    }
  }
});

// env argument will capture the environment URL
// if you use one of the options below to pass in, e.g. --env=dev
//
// If you need basic_auth, create a file called `.env` and add
// auth credentials in uname:upass format.
// See .env-example for an example.
var environments = {
  'local': localhost,
  'dev': 'http://develop-' + projName + '.pantheonsite.io',
  'staging': 'http://stage-' + projName + '.pantheonsite.io',
  'prod': ''
};

var default_environment = 'local';

// Environments that are being compared
if (!args.env) {
  args.env = default_environment;
}
// if you pass in a bogus environment, it’ll still use the default environment
else if (!environments.hasOwnProperty(args.env)) {
  args.env = default_environment;
}

// Site for reference screenshots
if (!args.refHost) {
  args.refHost = environments[args.env];
}

// Site for test screenshots
if (!args.testHost) {
  args.testHost = environments[args.env];
}

// Directories to save screenshots
var saveDirectories = {
  "bitmaps_reference": "../../data/backstop_data/"+args.env+"_reference",
  "bitmaps_test": "../../data/backstop_data/"+args.env+"_test",
  "html_report": "../../data/backstop_data/"+args.env+"_html_report",
  "ci_report": "../../data/backstop_data/"+args.env+"_ci_report"
};


// Scenarios are a default part of config for BackstopJS
// Explanations for the sections below are at https://www.npmjs.com/package/backstopjs
var files = glob.readdirSync('scenarios/*.json');
scenarios = [];
files.forEach(function(file) {
    var data = JSON.parse(fs.readFileSync(file, 'utf8'));
    data.referenceUrl = args.refHost + data.referenceUrl;
    data.url = args.testHost + data.url;
    scenarios.push(data);
});


// BackstopJS configuration
module.exports =
{
  "id": "project_"+args.env+"_config",
  "viewports": [
    {
      "label": "iPhone 6",
      "width": 375,
      "height": 667
    },
    {
      "label": "iPad Portrait",
      "width": 768,
      "height": 1024
    },
    {
      "label": "Desktop",
      "width": 1200,
      "height": 768
    }
  ],
  "scenarios":
    scenarios,
  "paths":
    saveDirectories,
  "casperFlags": ["--ignore-ssl-errors=true", "--ssl-protocol=any"],
  "engine": "phantomjs", // alternate can be slimerjs
  "report": [],
  "debug": false
};
