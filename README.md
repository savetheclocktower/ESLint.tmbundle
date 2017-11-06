
# TextMate bundle for ESLint

A bundle for [ESLint][], the linter and style checker for JavaScript.

Built for [TextMate 2][textmate].

## Setup

If you want the bundle to use a specific `eslint` binary, or one that isn't in your `PATH`, define the `TM_ESLINT` variable in your `.tm_properties` file and assign it the path to your `eslint` binary.

Failing that, the bundle will use whichever `eslint` binary it finds in your `PATH`.

ESLint is very good at finding the proper `.eslintrc` file to use, so you don't have to give it special configuration in the bundle. It'll use the nearest `.eslintrc` file to the file you're linting.

## Features

### Quick linting & gutter marking

Every time you save a file, the bundle will lint your code in the background. If it passes linting, you'll see nothing. If it fails linting with errors and/or warnings, you'll see a tooltip with the number of errors and warnings, and your gutter will get marked accordingly.

### Full linting

If you want details about the warnings and errors, run the `Validate File` command (<kbd>Ctrl-Shift-V</kbd> by default). You'll get an HTML window showing descriptions of the errors and warnings, along with hyperlinks that go to the specific line and column of the error.

### Fixing

For some of the style rules, ESLint can automatically fix mistakes. To fix the file you're in, run the `Fix File` command (<kbd>Ctrl-Shift-H</kbd> by default). If there are errors or warnings that can be automatically fixed, the command will replace the contents of your file with the fixed version. (You'll still have to save the file to commit the changes.)

If it can't fix your code — either because there's nothing wrong with it, or because the remaining problems must be fixed manually — it'll say so in a tooltip.

## Configuration

If you don't want the bundle to mark your gutters, define a `TM_ESLINT_DISABLE_GUTTER` variable in your `.tm_properties` file. The value doesn't matter — if that variable is present, the bundle will skip gutter marks.

If you're working with very large files, you may want to disable automatic linting on save, because it can hang TextMate in extreme cases. If so, you can define `TM_ESLINT_IGNORE` and give it a Ruby-style [file glob pattern][shell glob syntax]. Any file that matches this glob will not get linted on save. (The `Validate File` and `Fix File` commands ignore this setting, since they're opt-in commands.)

[eslint]:            http://eslint.org
[textmate]:          https://github.com/textmate/textmate
[shell glob syntax]: http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob

## License

(The MIT License)

Copyright (c) 2016 Andrew Dupont,   mit@andrewdupont.net

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

