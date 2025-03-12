require 'rake'

desc "Restart the entire analytics pipeline"
task :restart do
  sh "bin/restart"
end

desc "Start the Pinot analytics stack"
task :start do
  sh "bin/start"
end

desc "Stop the Pinot analytics stack"
task :stop do
  sh "bin/stop"
end

desc "Set up Pinot schema and table"
task :setup do
  sh "bin/setup"
end

desc "Show available tasks"
task :default do
  puts "\n" + "=" * 40
  puts "Pinot Analytics Pipeline Commands"
  puts "=" * 40
  puts "\nAvailable commands:"
  puts "  rake restart        # Restart the entire analytics pipeline"
  puts "  rake start          # Start the Pinot analytics stack"
  puts "  rake stop           # Stop the Pinot analytics stack"
  puts "  rake setup          # Set up Pinot schema and table"
  puts "\n" + "=" * 40
end
