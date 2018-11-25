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
    temp = @details.where(asin: asin)
    @products = temp.page(params[:page]).per(PER)
    @amazon = Product.where(user: current_user.email, asin: asin)
  end

end
