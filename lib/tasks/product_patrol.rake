namespace :product_patrol do
  desc "商品情報の収集"
  task :operate, ['user'] => :environment do |task, args|
    user = args[:user]
    targets = Product.where(user: user)
    data = targets.group(:jan, :asin, :new_price, :used_price).pluck(:jan, :asin, :new_price, :used_price)
    Product.new.search(user, data)
  end
end
