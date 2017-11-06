#!/usr/bin/env ruby18
require ENV['TM_SUPPORT_PATH'] + '/lib/web_preview.rb'
require ENV['TM_BUNDLE_SUPPORT'] + '/helpers.rb'

exit_unless_eslint(:silent => false)

filepath = Pathname.new(ENV['TM_FILEPATH'])

result = validate(filepath, :use_ignore => true)

if result[:success]
  TextMate::exit_show_tool_tip("Passed ESLint.")
end

puts display_result_as_html(result)
