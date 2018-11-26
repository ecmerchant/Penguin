class CandidatesController < ApplicationController

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  PER = 40

  def show
    @login_user = current_user
    asin = params[:asin]
    logger.debug(asin)
    @details = Candidate.where(user: current_user.email)
    temp = @details.where(asin: asin, filtered: false)
    @products = temp.page(params[:page]).per(PER)
    @amazon = Product.where(user: current_user.email, asin: asin)

    @account = Account.find_or_create_by(user: current_user.email)

    @flg_A = false
    @flg_AB = false
    @flg_B = false
    @flg_ALL = false

    if @account.condition == "A以上" then
      @flg_A = true
    elsif @account.condition == "AB以上" then
      @flg_AB = true
    elsif @account.condition == "B以上" then
      @flg_B = true
    elsif @account.condition == "全て" then
      @flg_ALL = true
    end

    @flg_at = @account.attachment
    @flg_new = @account.new_price_diff.to_i
    @flg_used = @account.used_price_diff.to_i
    
  end

end
