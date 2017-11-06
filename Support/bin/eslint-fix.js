#!/usr/bin/env node

// Given a file, prints to STDOUT the "fixed" version of that file.

// This script exists because using `eslint --fix` on the command line
// automatically writes the changes back to disk, which is not what we want.
//
// TextMate gives the buffer contents to a command and expects stdout to
// contain the fixed version; it gets confused if it has to reload the file
// from disk.
//
// In addition, we don't want an automatic save; we want to make an atomic
// change to the code in the editor and then let the user decide whether to
// commit those changes to disk.

try {
  var CLIEngine = require('eslint').CLIEngine;
} catch (error) {
  console.error(error);
  process.exit(3);
}

// Third argument will be the file we need to lint.
var path = process.argv[2];

var engine = new CLIEngine({
  // Will try to fix errors but will not write back to disk.
  fix: true
});
var report = engine.executeOnFiles([path]);

// Report will have a results property that is an array. We know we're
// linting only one file, so we can just read the first item.
var fileReport = report.results[0];

// If there was anything to fix, the output will live here. If this is
// undefined, it means there was nothing that could be fixed.
//
// NOTE: When we fix some problems but need the user to fix the rest
// manually, we want to replace the buffer contents _and_ show a tooltip, but
// that appears not to be possible. The user will have to run the command a
// second time to get the tooltip.
//
if (fileReport.output) {
  // All we'll do is print the fixed source code and then exit successfully.
  process.stdout.write(fileReport.output);
  process.exit();
} else {
  // We couldn't fix anything...
  if (report.errorCount === 0 && report.warningCount === 0) {
    // ...because nothing needs to be fixed.
    console.error('Nothing to fix.');
    process.exit(1);
  } else {
    // ...because all the problems need to be fixed manually.
    var status = [];
    var noun;
    if (report.errorCount > 0) {
      noun = (report.errorCount > 1) ? 'errors' : 'error'
      status.push(report.errorCount + ' ' + noun);
    }

    if (report.warningCount > 0) {
      noun = (report.warningCount > 1) ? 'warnings' : 'warning'
      status.push(report.warningCount + ' ' + noun);
    }

    status = status.join(' and ');

    console.error(status + ' must be fixed manually.');
    process.exit(2);
  }
}