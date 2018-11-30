# /config/schedule.rb
set :environment, :development
set :output, {:error => 'log/error.log', :standard => 'log/cron.log'}

every 1.day, at: '4:30 am' do
  rake "product_patrol:operarte['murakami@ec-merchant.com']"
end
