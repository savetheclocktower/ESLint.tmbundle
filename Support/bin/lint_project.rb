#!/usr/bin/env ruby18
require ENV['TM_SUPPORT_PATH'] + '/lib/web_preview.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/helpers.rb'

exit_unless_eslint(:silent => false)

unless ENV['TM_PROJECT_DIRECTORY']
  TextMate::exit_show_tool_tip("No project to lint! Define a .tm_properties file in the root of your project and set \"projectDirectory = $CWD\".")
end

meta = { :title => "ESLint", :message => "Linting project..." }
TextMate::call_with_progress(meta) do
  result = validate(:all, :use_ignore => true)

  if result[:success]
    TextMate::exit_show_tool_tip("Passed ESLint.")
  end

  puts display_result_as_html(result)
end
