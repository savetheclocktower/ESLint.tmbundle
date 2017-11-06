
# TextMate bundle for ESLint

A bundle for [ESLint][], the linter and style checker for JavaScript.

Built for [TextMate 2][textmate].

## Installation

```bash
mkdir -p ~/Library/Application\ Support/TextMate/Pristine\ Copy/Bundles
cd ~/Library/Application\ Support/TextMate/Pristine\ Copy/Bundles
git clone git://github.com/savetheclocktower/ESLint.tmbundle.git
osascript -e 'tell app "TextMate" to reload bundles'
```

## Setup

If you're using `eslint` in a specific project, you'll likely want to use that project's version of `eslint`. So define the `TM_ESLINT` variable in your project's `.tm_properties` file and assign it the path to your `eslint` binary:

```
TM_ESLINT = '$CWD/node_modules/.bin/eslint'
```

If you want linting by default, regardless of context, you can define `TM_ESLINT` (either in **Preferences &rarr; Variables** or in your `~/.tm_properties` file) to point to a global `eslint` installation, or else the bundle will use whichever `eslint` binary it finds in your path.

If a command can't find any `eslint` binary, it'll either complain via tooltip (the “Fix File” and “Validate File” commands) or silently do nothing (the “Quick Lint” command).

ESLint itself is very good at finding the proper `.eslintrc` file to use, so you don't have to give it special configuration in the bundle. It'll use the nearest `.eslintrc` file to the file you're linting. Read about [`.eslintrc` files](https://eslint.org/docs/user-guide/configuring) on the ESLint web site.

## Features

### Quick linting & gutter marking

Every time you save a file, the bundle will lint your code in the background. If it passes linting, you'll see nothing. If it fails linting with errors and/or warnings, you'll see a tooltip with the number of errors and warnings, and your gutter will get marked accordingly.

<img width="333" alt="screen shot 2017-11-06 at 11 29 04 am" src="https://user-images.githubusercontent.com/3450/32454913-3eb56b0e-c2e6-11e7-9754-c22c0c41adb4.png">

### Full linting

If you want details about the warnings and errors, run the `Validate File` command (<kbd>Ctrl-Shift-V</kbd> by default). You'll get an HTML window showing descriptions of the errors and warnings, along with hyperlinks that go to the specific line and column of the error.

<img width="455" alt="screen shot 2017-11-06 at 11 28 19 am" src="https://user-images.githubusercontent.com/3450/32454916-3ee10b60-c2e6-11e7-8c94-1111f36363ac.png">

### Fixing

Some style violations — indentation, semicolons, and such — can automatically be fixed by ESLint. To fix the file you're in, run the `Fix File` command (<kbd>Ctrl-Shift-H</kbd> by default). If there are errors or warnings that can be automatically fixed, the command will replace the contents of your file with the fixed version.

Unlike `eslint --fix`, it **will not commit the changes to disk**; you should save the file to commit your changes. This makes `Fix File` behave like other TextMate reformatting and beautifying commands.

If it can't fix your code — either because there's nothing wrong with it, or because the remaining problems must be fixed manually — it'll say so in a tooltip.

### Ignoring files

When you run `eslint` on the command line, ESLint looks for an `.eslintignore` file in whatever directory you run the command from. When the bundle runs the `eslint` command, to determine the right working directory it uses the first value in this list that exists:

1. the `TM_ESLINT_WORKING_DIRECTORY` environment variable, which you should only define in `.tm_properties` if your project root is somehow not where your `.eslintignore` file is kept;
2. the `TM_PROJECT_DIRECTORY` environment variable (which TextMate provides when we're inside of a project);
3. the directory of the file being linted.

If you save a file that's included in your `.eslintignore`, the bundle will skip automatic linting.

If you want to disable automatic linting on certain files that _aren't_ in your `.eslintignore`, you can define `TM_ESLINT_IGNORE` and give it a Ruby-style [file glob pattern][shell glob syntax]: 

```
TM_ESLINT_IGNORE = "/dist/**/*.js"
```

Any file that matches this glob will not get linted on save.

Note:

* If you're in a project, the `TM_ESLINT_IGNORE` glob is considered **relative to the project root**, so you should not include `$CWD`.
* Files matched by `.eslintignore` or `TM_ESLINT_IGNORE` are only ignored on save; you can still run `Validate File` or `Fix File` against these files.)

## License

(The MIT License)

Copyright (c) 2016 Andrew Dupont, mit@andrewdupont.net

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[eslint]:            http://eslint.org
[textmate]:          https://github.com/textmate/textmate
[shell glob syntax]: http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob

