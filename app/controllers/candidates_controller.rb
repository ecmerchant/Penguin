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
    @products = temp
    @amazon = Product.where(user: current_user.email, asin: asin)
    @labels = Label.where(user: current_user.email).pluck(:caption)
    @labels_add = @labels.push("すべて")

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

    if request.post? then
      logger.debug(request.referer)
      commit = params[:commit]
      if commit == "更新" then
        memos = params[:memo]
        labels = params[:label]
        jans =  params[:jan]
        new_prices =  params[:new_price]
        used_prices =  params[:used_price]
        logger.debug(memos)
        logger.debug(labels)
        logger.debug(jans)
        temp = Product.where(user: current_user.email)

        jans.each do |key, value|
          tid = key.to_i
          if tid != 0 then
            tag = temp.find(tid)
            tag.update(
              jan: jans[key],
              memo: memos[key],
              label: labels[key],
              new_price: new_prices[key],
              used_price: used_prices[key]
            )
          end
        end

      elsif commit == "削除" then
        checks = params[:check]
        if checks != nil then
          temp = Product.where(user: current_user.email)
          checks.each do |key, value|
            tid = key.to_i
            if tid != 0 then
              temp.find(tid).delete
            end
          end
        end
      elsif commit == "適用" then
        cond = params[:condition]
        if cond != nil then
          key = cond.keys[0]
          condition = cond[key]
        end
        attach = params[:attachment]

        if attach == "true" then
          attach = "true"
        else
          attach = "false"
        end

        diff_new_price = params[:diff_new_price].to_i
        diff_used_price = params[:diff_used_price].to_i

        @account.update(
          condition: condition,
          attachment: attach,
          new_price_diff: diff_new_price,
          used_price_diff: diff_used_price
        )

        Product.new.reload(current_user.email)
      end
      redirect_to request.referer
    end

  end

end
