set :output, 'log/output.log'
set :environment, :development
# minute, hour, day_of_month, month, day_of_week
every 1.day, :at => '02:20' do
    rake "product_patrol:operarte['murakami@ec-merchant.com']"
end
