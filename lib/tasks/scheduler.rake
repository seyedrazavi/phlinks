desc "This task is called by the Heroku scheduler add-on"
task :cleanup => :environment do
  puts "Cleaning up old links..."
  Link.clean_up!
  puts "Reevaluating order scores..."
  Link.update_all_not_deleted!
  Rails.cache.clear
  puts "done."
end

task :fetch => :environment do
  Rails.cache.clear
  Link.fetch!
end