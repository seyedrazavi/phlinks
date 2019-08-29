desc "This task is called by the Heroku scheduler add-on"
task :cleanup => :environment do
  puts "Cleaning up old links..."
  Link.clean_up!
  puts "done."
end

task :fetch => :environment do
  Link.fetch!
end