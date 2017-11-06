#!/usr/bin/env ruby18

require 'pp'
require ENV['TM_BUNDLE_SUPPORT'] + '/helpers.rb'

exit_unless_eslint(:silent => true)

# The TM_ESLINT_IGNORE glob, if it exists, should be compared to the path
# relative to the project directory, not the absolute path.
relative_path = ENV['TM_FILEPATH']
if ( ENV.has_key?('TM_PROJECT_DIRECTORY') )
  relative_path = ENV['TM_FILEPATH'].sub(ENV['TM_PROJECT_DIRECTORY'], '')
end

# Don't quick-lint this file if it matches the TM_ESLINT_IGNORE glob.
#
# This is different from `.eslintignore` because a user may want to skip
# quick-linting in the IDE for certain files without skipping linting
# _altogether_ for those files.
if ENV.has_key?('TM_ESLINT_IGNORE')
  if File.fnmatch?(ENV['TM_ESLINT_IGNORE'], relative_path)
    TextMate::exit_show_tool_tip("Skipping quick lint on this file.")
  end
end

file = Pathname.new(FILEPATH)

begin
  result = validate(file, :use_ignore => true)
rescue Exception => e
  TextMate::exit_show_tool_tip("Something went wrong!\n#{e}")
end

mark_errors(result)

# If linting passed, do nothing.
if result[:success]
  if result[:ignored]
    TextMate::exit_show_tool_tip("File ignored by .eslintignore.")
  else
    TextMate::exit_discard 
  end
end

# Otherwise show the numbers of errors and warnings in a tooltip.
puts result[:status]