desc "This task is called by the Heroku scheduler add-on"
task :cleanup => :environment do
  puts "Cleaning up old links..."
  Link.clean_up!
  puts "Reevaluating order scores..."
  Link.update_all_order_scores!
  puts "done."
end

task :fetch => :environment do
  Link.fetch!
end