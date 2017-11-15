require 'pathname'
# Bring our own JSON to the party. We need Ruby 1.8, so we're using
# TextMate's version, but we can't rely on gem dependencies.
$:.unshift( Pathname.new(ENV['TM_BUNDLE_SUPPORT']).join('lib') )
require 'json/pure'
require 'open3'
require 'pp'

require ENV['TM_SUPPORT_PATH'] + '/lib/escape'
require ENV['TM_SUPPORT_PATH'] + '/lib/tm/process'
require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes'
require ENV['TM_SUPPORT_PATH'] + '/lib/progress'

# The user can point us to the copy of `eslint` we should be using. Failing
# that, if it's in the PATH, we'll find it.
TM_ESLINT = ENV['TM_ESLINT'] if ENV.key?('TM_ESLINT')
unless defined?(TM_ESLINT)
  output = `which eslint`.chomp
  TM_ESLINT = output if $?.exitstatus == 0
end

def exit_unless_eslint(options={})
  silent = options.delete(:silent)
  unless defined?(TM_ESLINT)
    exit if silent
    TextMate::exit_show_tool_tip("The ESLint bundle can't find an eslint binary. Either make sure it's defined somewhere in your PATH or define TM_ESLINT in your .tm_properties file with the path to your ESLint binary.")
  end
end

# If the user specified this variable in their config, they want us not to
# mark the gutter. We'll still do quick-linting, but the only feedback
# they'll get is a tooltip if there are any problems.
GUTTER_DISABLED = true if ENV.has_key?('TM_ESLINT_DISABLE_GUTTER')

FILEPATH = ENV['TM_FILEPATH']
MATE     = ENV['TM_MATE']
NODE     = ENV.has_key?('TM_NODE') ? ENV['TM_NODE'] : 'node'

# Determine where to run the `eslint` command from. Usually this will be the
# project root.
def get_working_directory(path)
  ENV['TM_ESLINT_WORKING_DIRECTORY'] ||
  ENV['TM_PROJECT_DIRECTORY'] ||
  path.dirname
end

# Given a file path, validate it with ESLint and return the parsed JSON
# output.
def validate(path, options={})
  # Prefer the project directory; that's where we'll find .eslintignore.
  pwd = get_working_directory(path)
  use_ignore = options.delete(:use_ignore)
  
  if path == :all
    path = "#{pwd}/**/*.js"
  else
    path = e_sh(path)
  end

  args = [TM_ESLINT, path, "--format", "json"]
  args << '--no-ignore' unless use_ignore

  output, error = TextMate::Process.run(args, :chdir => pwd)
  
  begin
    result = JSON::parse(output)
  rescue Exception => e
    # ESLint _should_ be writing errors to STDERR, but they aren't. So look
    # for some tokens that are likely to appear in the "you don't have an
    # .eslintrc" error message.
    #
    # UPDATE: This now appears to be fixed?
    if (/Oops!/ =~ output && /eslint --init/ =~ output)
      raise "ESLint couldn't find an .eslintrc file. Run `eslint --init` to create one."
    else
      # If it's something else, just pass the error up and make it someone
      # else's problem.
      raise "Error parsing eslint output:\n#{output}\n#{error}"
    end
  end

  interpret_result(result)
end

# Given the parsed JSON output of an `eslint` result, do some housekeeping on
# the data.
def interpret_result(result)
  total_errors   = 0
  total_warnings = 0
  
  ignored = false

  result.each do |file|
    total_errors   += file['errorCount']
    total_warnings += file['warningCount']
    
    problems = file['messages']
    problems.each do |p|
      if p['message'] =~ /ignored/
        ignored = true
        total_warnings -= 1
        break
      end
    end
  end
  
  status = []

  if (total_errors > 0)
    noun = total_errors == 1 ? 'error' : 'errors'
    status.push("#{total_errors} #{noun}")
  end

  if (total_warnings > 0)
    noun = total_warnings == 1 ? 'warning' : 'warnings'
    status.push("#{total_warnings} #{noun}")
  end

  status = status.join(', ')

  {
    :success  => total_errors + total_warnings == 0,
    :errors   => total_errors,
    :warnings => total_warnings,
    :status   => status,
    :results  => result,
    :ignored  => ignored
  }
end

# Turn a severity integer into a string. Used for setting gutter marks and
# for the HTML class name.
def get_mark_type_for_severity(severity)
  return :warning if severity == 1
  return :error
end

# Remove all marks from the gutter.
def clear_errors
  return if defined?(GUTTER_DISABLED)
  system(MATE, "--clear-mark=warning", FILEPATH)
  system(MATE, "--clear-mark=error",   FILEPATH)
end

# Given a result from `eslint`, add appropriate marks to gutter lines.
def mark_errors(output)
  return if defined?(GUTTER_DISABLED)
  if output[:success]
    # We only do a bulk clear-errors if there are no marks to make. Otherwise
    # we clear an error at the same time as we set the new one, because the
    # atomic operation prevents a flicker in the gutter.
    clear_errors
    return
  end

  files = output[:results]

  files.each do |file|
    problem_table = {}

    file_name = file['filePath']
    next unless FILEPATH.end_with?(file['filePath'])

    problems = file['messages']
    # Since each line can contain several problems, we need to index the
    # problems by line number. Otherwise the gutter will only show whichever
    # of the problems was listed last.
    problems.each do |p|
      line    = p['line']
      message = p['message']
      mark    = get_mark_type_for_severity(p['severity'])

      problem_table[line] ||= []
      problem_table[line].push({ :severity => mark, :message => message })
    end

    # Now that we've indexed each problem we know enough to mark each line
    # with all its problems.
    mate_args = []
    problem_table.each do |line, problems|
      # If there's more than one problem on a particular line, consolidate
      # all those problems into one message whose severity is the highest
      # among all messages.
      severities = problems.map { |p| p[:severity].to_sym }
      severity   = severities.include?(:error) ? :error : :warning

      # TextMate appears not to allow more than one line in a gutter mark
      # message, so we'll have to put these all on one line. Each problem
      # will be its own sentence.
      message    = problems.map { |p| p[:message] }.join(" ")

      # Clear the old mark (if any) at the same time that we set the new
      # mark; this prevents a flicker in the gutter.
      args = [
        "--line=#{line}",
        "--clear-mark=warning",
        "--clear-mark=error",
        "--set-mark=#{severity}:#{message}"
      ]

      mate_args.push(*args)
    end

    # We can set all these marks with one call to `mate`, luckily.
    mate_args.push(FILEPATH)
    TextMate::Process.run(MATE, mate_args, {
      :pwd => ENV['TM_PROJECT_DIRECTORY'],
      :env => ENV
    })

  end
end

# Given a filepath, line number, and column number, generates a URL that,
# when followed, will open that file in TextMate for editing.
def url(file, line=0, column=0)
  %Q{txmt://open?url=file://#{e_url(file)}&line=#{line}&column=#{column}}
end

# Generates an HTML fragment containing the linting results for each file
# linted. (We don't allow for project-wide linting yet, but we may someday.)
def html_for_file(name, errors)
  errors_html = errors.map { |e| html_for_error(name, e) }.join("\n")

  if ENV.has_key?('TM_PROJECT_DIRECTORY')
    name = name.sub(ENV['TM_PROJECT_DIRECTORY'], '')
  end

  %Q{
    <h2>#{name}</h2>
    <table class="error-table">
      <thead>
        <tr>
          <th class="type">Type</th>
          <th class="line">Line</th>
          <th class="desc">Description</th>
        </tr>
      </thead>
      <tbody>
        #{errors_html}
      </tbody>
    </table>
  }
end

# Generate an HTML fragment for one error.
def html_for_error(file, e)
  line      = e['line']
  column    = e['column']
  source    = e['source']
  message   = e['message']
  rule_name = e['ruleId']

  severity = get_mark_type_for_severity(e['severity'])

  %Q{
    <tr class="row-#{severity}">
      <td class="badge">
        <span class='#{severity}'>#{severity}</span>
      </td>
      <td class="location">
        <a href="#{url(file, line, column)}">
          #{line}:#{column}
        </a>
      </td>
      <td class="description">
        <pre>#{source}</pre>
        <p class="message">
          #{message}
          <span class="rule-name">#{rule_name}</span>
        </p>
      </td>
    </tr>
  }
end

# Given the result of an `eslint` call, display the result as HTML.
def display_result_as_html(results)
  status = results[:status]
  output = []

  results[:results].each do |result|
    name, errors = result['filePath'], result['messages']
    next unless errors.any?
    output.push( html_for_file(name, errors) )
  end

  output = output.join("\n")

  html = <<-HTML
  <html>
    <head>
      <title>ESLint Results</title>
      <style type="text/css">
        body {
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          padding: 1rem;
        }

        pre {
          background-color: #eee;
          color: #400;
          margin: 0 0 3px;
          overflow: auto;
          padding: 10px;
          font-family: "Panic Sans";
          font-size: 13px;
          white-space: pre-wrap;
          border-radius: 3px;
        }

        pre code {
          white-space: nowrap;
          display: block;
        }


        h1 {
          font-size: 27px;
          margin: 0 0 0.5em;
          letter-spacing: -0.5px;
        }

        h2 {
          font-size: 20px;
          margin: 0 0 0.66em;
          letter-spacing: -0.5px;
        }

        table.error-table {
          border-collapse: collapse;
          width: 100%;
        }

        table.error-table td.badge {
          width: 50px;
          vertical-align: top;
          align: right;
          padding-top: 10px;
          padding-right: 10px;
        }

        table.error-table td.location {
          width: 50px;
          vertical-align: top;
          align: left;
          padding: 10px 10px 0;
        }

        table.error-table td.description {
          padding-top: 10px;
          padding-bottom: 3rem;
        }

        span.warning,
        span.error {
          display: block;
          border-radius: 3px;
          padding: 3px 5px;
          font-weight: bold;
          font-size: 12px;
          text-transform: uppercase;
          color: #fff;
          text-align: center;

/*          display: block;
          text-decoration: none;
          border-radius: 3px;
          color: #049;
          text-align: center;
          border: 1px solid #049;
*/        }

        span.warning {
          background-color: #c90;
        }

        span.error {
          background-color: #900;
        }

        ul {
          margin: 10px 0 0;
          padding: 0;
        }

        li {
          margin: 0 0 1.0em;
          list-style-type: none;
          padding-left: 0;
        }

        li p {
          padding: 0 0 1.0em;
        }

        span.rule-name {
          display: none;
          padding: 0 4px;
          background-color: #eee;
          color: #555;
          font-size: 12px;
          border-radius: 2px;
          font-family: "Panic Sans", Monaco, monospace;
        }

        p.message:hover span.rule-name {
          display: inline;
        }

        td.location a {
          display: block;
          text-decoration: none;
          border-radius: 3px;
          color: #049;
          padding: 3px 5px;
          text-align: center;
          border: 1px solid #049;
          font-size: 12px;
        }

        td.location a:hover {
          color: #fff;
          background-color: #049;
        }

        th {
          padding: 10px 5px 10px;
          color: #999;
          border-bottom: 1px solid #eee;
        }

        th.desc {
          text-align: left;
        }

        .filters ul {
          display: inline-block;
        }

        .filters li {
          display: inline-block;
        }

        .filters button {
          background-color: #fff;
          border: 1px solid #039;
          color: #039;
          font-size: 14px;
          border-radius: 3px;
          cursor: pointer;
        }

        .filters button:hover {
          background-color: #f5f5ff;
        }

        .filters button.active {
          background-color: #039;
          color: #fff;
        }

      </style>
      <script type="text/javascript">
        function forEachSelector (selector, iterator) {
          var nodes = document.querySelectorAll(selector);
          for (var i = 0, node; node = nodes[i]; i++) {
            iterator(node, i);
          }
        }

        function makeActiveButton (selector) {
          forEachSelector('div.filters button', function (button) {
            button.classList.remove('active');
          });
          document.querySelector(selector).classList.add('active');
        }

        function showAll () {
          makeActiveButton('button.show-all');
          forEachSelector('.row-error, .row-warning', function (row) {
            row.style.display = 'table-row';
          });
        }

        function showErrors () {
          makeActiveButton('button.show-errors');
          forEachSelector('.row-error, .row-warning', function (row) {
            if ( row.matches('.row-error') ) {
              row.style.display = 'table-row';
            } else {
              row.style.display = 'none';
            }
          });
        }

        function showWarnings () {
          makeActiveButton('button.show-warnings');
          forEachSelector('.row-error, .row-warning', function (row) {
            if ( row.matches('.row-warning') ) {
              row.style.display = 'table-row';
            } else {
              row.style.display = 'none';
            }
          });
        }
      </script>
    </head>
    <body>
      <h1>#{status}</h1>
      <div class="filters">
        Show:
        <ul>
          <li>
            <button type="button" class="show-all active">All</a>
          </li>
          <li>
            <button type="button" class="show-errors">Errors</a>
          </li>
          <li>
            <button type="button" class="show-warnings">Warnings</a>
          </li>
        </ul>
      </div>

      <script type="text/javascript">
        document.querySelector('button.show-all').addEventListener('click', showAll, false);
        document.querySelector('button.show-errors').addEventListener('click', showErrors, false);
        document.querySelector('button.show-warnings').addEventListener('click', showWarnings, false);
      </script>

      #{output}
    </body>
  </html>
  HTML

  html
end