module WheneverHelper
  def update_schedule
    schedule_path = File.join(Rails.root, 'config/schedule.rb')

    File.open(schedule_path, 'w') do |f|
      f.flock File::LOCK_EX
      header = "set :output, 'log/output.log'\n"
      header << "set :environment, :development\n"
      f.write(header)
    end

    accounts = Account.all
    accounts.each do |account|
      if account.patrol_time != nil then

        content = <<-FILE
# minute, hour, day_of_month, month, day_of_week
every 1.day, :at => '#{crontime(account)}' do
    rake "product_patrol:operarte['#{account.user}']"
end
        FILE

        File.open(schedule_path, 'a') do |f|
          f.flock File::LOCK_EX
          f.write(content)
        end
      end
    end
    system("bundle exec whenever --update-crontab")

  end

  private
  def crontime account
    tag = account.patrol_time
    "%s" % [tag.strftime("%H:%M")]
  end

end
