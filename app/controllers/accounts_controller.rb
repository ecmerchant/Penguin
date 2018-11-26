class AccountsController < ApplicationController

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
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
      end

      if params[:commit] == "更新" then
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
      end
    end
  end


end
