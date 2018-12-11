class AccountsController < ApplicationController

  include WheneverHelper

  require 'nokogiri'
  require 'open-uri'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def delete
    if request.post? then
      password = params[:current_password]
      user = User.find_by(email: current_user.email)
      if user.valid_password?(params[:user][:current_password]) then
        logger.debug("PASSWORD VALID")
        Product.where(user: current_user.email).delete_all
        Candidate.where(user: current_user.email).delete_all
        Account.find_by(user: current_user.email).update(
          progress: 0
        )
      end
    end
    redirect_to products_show_path
  end

  def download
    if request.post? then
      bom = "\uFEFF"
      output = CSV.generate(bom) do |csv|
        header = ["ASIN", "商品名", "新品価格", "中古価格", "JAN", "売れ行き"]
        csv << header
      end
      fname = "登録用データ.csv"
      send_data(output, filename: fname, type: :csv)
    else
      redirect_to accounts_setup_path
    end
  end

  def edit
    if request.post? then
      current_user.update_with_password(
        user_params
      )
    end
    redirect_to accounts_setup_path
  end

  def update
    if request.post? then
      label = params[:label]
      user = current_user.email
      temp = Account.find_by(user: user)
      temp.update(
        label: label
      )
    end
    redirect_to products_show_path
  end

  def setup
    @user = User.find_by(email: current_user.email)
    @login_user = current_user
    @account = Account.find_or_create_by(user: current_user.email)
    @label = Label.find_or_create_by(user: current_user.email)
    @labels = Label.where(user: current_user.email).order("number ASC")
    if request.post? then

      if params[:commit] == "設定" then
        res = params[:account]
        shop_url = res[:shop_url]
        patrol_time = Time.zone.local(res["patrol_time(1i)"].to_i, res["patrol_time(2i)"].to_i, res["patrol_time(3i)"].to_i, res["patrol_time(4i)"].to_i, res["patrol_time(5i)"].to_i)
        logger.debug(shop_url)
        logger.debug(patrol_time)
        @account.update(
          shop_url: shop_url,
          patrol_time: patrol_time
        )
        #update_schedule
      elsif params[:commit] == "更新" then
        res = params[:label]
        number = res[:number].to_i
        caption = res[:caption].to_s
        logger.debug(number)
        logger.debug(caption)
        target = Label.find_by(user: current_user.email, number: number)
        if target == nil then
          Label.create(
            user: current_user.email,
            number: number,
            caption: caption
          )
        else
          target.update(
            number: number,
            caption: caption
          )
        end
      elsif params[:commit] == "ASIN取得" then
        logger.debug("==== ASIN ====")
        products = Product.where(user: current_user.email)
        org_url = @account.shop_url
        maxnum = 1000
        ua = CSV.read('app/others/User-Agent.csv', headers: false, col_sep: "\t")

        for pgnum in 1..20
          pos = org_url.index('&page=')
          if pos == nil then
            url = org_url + '&page=' + pgnum.to_s
          else
            ipg = org_url.match(/&page=([\s\S]*?)&/)[0]
            url = org_url.gsub(ipg,'&page=' + pgnum.to_s + '&')
          end
          user_agent = ua.sample[0]
          charset = nil
          begin
            html = open(url, "User-Agent" => user_agent) do |f|
              charset = f.charset
              f.read
            end
          rescue OpenURI::HTTPError => error
            response = error.io
            logger.debug(error)
          end

          doc = Nokogiri::HTML.parse(html, charset)
          temp = doc.css('li/@data-asin')

          if temp.count == 0 then
            logger.debug("=== NO ASIN ===")
            break
          end
          temp.each do |list|
            asin = list.value
            check = products.find_by(asin: asin)
            if check != nil then
              check.update(
                self_sale: true
              )
            end
            logger.debug(asin)
          end
        end

      end
    end
  end

  private
  def user_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

end
