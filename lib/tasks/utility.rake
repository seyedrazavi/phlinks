desc "Utility tasks"
task :count => :environment do
  puts "#{Link.where(deleted: false).count} links (#{Link.where(deleted: true).count} deleted)"
end