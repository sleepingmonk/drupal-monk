# Visual Regression Testing

This toolset allows us to test all servers as we push feature branches to higher servers. Images are currently saved to our _data_ folder and not commited to repos.

## Usage

After running `npm install` in a _tests/vrt/_, you can run several commands that all follow a similar pattern. The core difference in the commands is the server you're referencing.

### Servers

There are four default servers.

* `local`
* `dev`
* `staging`
* `prod`

### Commands

All commands are run from the VRT folder and use NPM scripts.

`npm run <server>:ref` will generate initial reference images. Do this before making changes to the site and running tests.

`npm run <server>` will run tests on selected server.

## General workflow

Create your feature branch and generate reference images.

Do some work.

Test to see what has changed. Should just be the elements you wanted, but tests will show all areas of the site that are affected.

Push and PR. At this point, you might want to generate references for the next server. Once the PR is merged, you can test and see changes quickly.

## Making new tests

Start by reading up on [BackstopJS](https://github.com/garris/BackstopJS). This is the backbone of our VRT tools. In there, you'll find a section on making scenarios. These are your tests.

Make a new file in _scenarios_ named _<test-name>.json_. Add only your scenario data in JSON format. It will be automatically added to the test suite at run time. **Don't forget to generate references for your new test.**
