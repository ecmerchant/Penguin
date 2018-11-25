class ProductsController < ApplicationController

  require 'rubyXL'
  require 'open-uri'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  PER = 40

  def show
    @login_user = current_user
    temp = Product.where(user: current_user.email)
    @products = temp.page(params[:page]).per(PER)
    @labels = Label.where(user: current_user.email).pluck(:caption)
  end

  def search
    targets = Product.where(user: current_user.email)
    data = targets.group(:jan, :asin, :new_price, :used_price).pluck(:jan, :asin, :new_price, :used_price)
    ProductPatrolJob.perform_later(current_user.email, data)
    redirect_to products_show_path
  end

  def update
    logger.debug('========== UPDATE ===========')
    if request.post? then
      commit = params[:commit]
      if commit == "更新" then
        memos = params[:memo]
        labels = params[:label]
        checks = params[:check]
        logger.debug(memos)
        logger.debug(labels)
        temp = Product.where(user: current_user.email)
        if checks != nil then
          checks.each do |key, value|
            tid = key.to_i
            tag = temp.find(tid)
            tag.update(
              memo: memos[key],
              label: labels[key]
            )
          end
        end
      elsif commit == "削除" then
        checks = params[:check]
        if checks != nil then
          temp = Product.where(user: current_user.email)
          checks.each do |key, value|
            tid = key.to_i
            temp.find(tid).delete
          end
        end
      end
    end
    redirect_to products_show_path
  end

  def import
    user = current_user.email
    if request.post? then
      data = params[:amazon_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xls" || ext == ".xlsx" then
          logger.debug("=== UPLOAD ===")
          products = Product.where(user: user)
          data_list = Array.new
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          worksheet.each_with_index do |row, i|
            if row[0].value == nil then break end
            if i != 0 then
              logger.debug("---------------")
              asin = row[0].value.to_s
              title = row[1].value.to_s
              used_price = row[2].value.to_f
              new_price = row[3].value.to_f
              jan = row[4].value.to_s
              sales = row[5].value.to_i

              delta_link = "https://delta-tracer.com/item/detail/jp/" + asin

              data_list << Product.new(user: user, asin: asin, title: title, new_price: new_price, used_price: used_price, jan: jan, sales: sales, delta_link: delta_link)
            end
          end
          Product.import data_list, on_duplicate_key_update: {constraint_name: :for_upsert, columns: [:title, :new_price, :used_price, :jan, :sales, :delta_link]}
          data_list = nil
        end
      end
    end
    redirect_to products_show_path
  end

end
