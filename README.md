
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

If you want linting by default, regardless of context, you can reference a globally-installed version of `eslint` in your `~/.tm_properties` file, or else the bundle will use whichever `eslint` binary it finds in your path.

If a command can't find any `eslint` binary, it'll either complain via tooltip (the “Fix File” and “Validate File” commands) or silently do nothing (the “Quick Lint” command).

ESLint itself is very good at finding the proper `.eslintrc` file to use, so you don't have to give it special configuration in the bundle. It'll use the nearest `.eslintrc` file to the file you're linting.

## Features

### Quick linting & gutter marking

Every time you save a file, the bundle will lint your code in the background. If it passes linting, you'll see nothing. If it fails linting with errors and/or warnings, you'll see a tooltip with the number of errors and warnings, and your gutter will get marked accordingly.

### Full linting

If you want details about the warnings and errors, run the `Validate File` command (<kbd>Ctrl-Shift-V</kbd> by default). You'll get an HTML window showing descriptions of the errors and warnings, along with hyperlinks that go to the specific line and column of the error.

### Fixing

Some style violations — indentation, semicolons, and such — can automatically be fixed by ESLint. To fix the file you're in, run the `Fix File` command (<kbd>Ctrl-Shift-H</kbd> by default). If there are errors or warnings that can be automatically fixed, the command will replace the contents of your file with the fixed version. (You'll still have to save the file to commit the changes.)

If it can't fix your code — either because there's nothing wrong with it, or because the remaining problems must be fixed manually — it'll say so in a tooltip.

## Configuration

If you don't want the bundle to mark your gutters, define a `TM_ESLINT_DISABLE_GUTTER` variable in your `.tm_properties` file. The value doesn't matter — if that variable is present, the bundle will skip gutter marks.

If you're working with very large files, you may want to disable automatic linting on save, because it can hang TextMate in extreme cases. If so, you can define `TM_ESLINT_IGNORE` and give it a Ruby-style [file glob pattern][shell glob syntax]. Any file that matches this glob will not get linted on save. (The `Validate File` and `Fix File` commands ignore this setting, since they're opt-in commands.)

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

