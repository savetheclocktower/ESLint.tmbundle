#!/usr/bin/env ruby18

require ENV['TM_BUNDLE_SUPPORT'] + '/helpers.rb'

exit_unless_eslint(:silent => false)

file_path   = ENV['TM_FILEPATH']
script_path = ENV['TM_BUNDLE_SUPPORT'] + '/bin/eslint-fix.js'

# We're running a Node script here, not the `eslint` binary, so we need to
# know the load path for the eslint library.
def guess_node_modules_path
  # If the TM_ESLINT variable is defined, it almost certainly contains the
  # correct path to node_modules.
  if defined?(TM_ESLINT) && TM_ESLINT.include?('node_modules')
    module_path = Pathname.new( TM_ESLINT.gsub(/(node_modules).*$/, '\1') ).expand_path
    return module_path
  end

  root_path = Pathname.new(ENV['TM_PROJECT_DIRECTORY']).join('node_modules')
  return root_path if root_path.exist?

  global_path = Pathname.new(`npm root -g`).chomp
  return global_path if global_path.exist?
  nil
end

if ENV.has_key?('TM_PROJECT_DIRECTORY')
  node_modules_path = guess_node_modules_path
  if node_modules_path
    paths = (ENV['NODE_PATH'] || '').split(':')
    paths.push(node_modules_path)

    # Add in the global NPM root directory because for some reason this isn't
    # present sometimes?
    global_path = `npm root -g`.chomp
    paths << global_path unless paths.include?(global_path)
    ENV['NODE_PATH'] = paths.join(':')
  end
end

meta = { :title => "ESLint", :message => "Fixing file..." }

TextMate::call_with_progress(meta) do
  args = [ NODE, script_path, file_path ]
  opts = {
    :pwd => ENV['TM_PROJECT_DIRECTORY'],
    :env => ENV
  }
  TextMate::Process.run(args, opts) do |str, type|
    if type == :err
      TextMate::exit_show_tool_tip(str)
    else
      print str
    end
  end
end