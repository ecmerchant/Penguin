class ProductsController < ApplicationController

  require 'rubyXL'
  require 'open-uri'
  require 'csv'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  PER = 100

  def clear
    temp = Candidate.where(user: current_user.email)
    temp.update(
      filtered: false
    )
    targets = Product.where(user: current_user.email)
    targets.each do |tag|
      asin = tag.asin
      temp = Candidate.where(user: current_user.email, asin: asin)
      result = temp.count
      tag.update(
        search_result: result.to_s
      )
    end
    account = Account.find_by(user: current_user.email)
    account.update(
      condition: "全て",
      attachment: "false",
      new_price_diff: -99999,
      used_price_diff: -99999
    )
    redirect_to products_show_path
  end

  def show
    @login_user = current_user
    @labels = Label.where(user: current_user.email).pluck(:caption)
    @labels_add = @labels.push("すべて")
    @account = Account.find_or_create_by(user: current_user.email)
    border_condition = @account.condition
    border_attachment = @account.attachment
    border_new_price = @account.new_price_diff.to_i
    border_used_price = @account.used_price_diff.to_i

    label_tag = @account.label
    temp = Product.where(user: current_user.email)
    if label_tag != "すべて" then
      temp = temp.where(label: label_tag)
    end

    temp = temp.order("search_result DESC NULLS LAST")
    @total = temp.count
    @products = temp.page(params[:page]).per(PER).order("search_result DESC NULLS LAST")

    temp2 = Candidate.where(user: current_user.email)

    if border_condition == "A以上" then
      temp2 = temp2.where("condition like ?", "%A(美品)%")
    elsif border_condition == "AB以上" then
      temp2 = temp2.where("condition like ? OR condition like ?", "%A(美品)%", "%AB(良品)%")
    elsif border_condition == "B以上" then
      temp2 = temp2.where("condition like ? OR condition like ? OR condition like ?", "%A(美品)%", "%AB(良品)%", "%B(並品)%")
    end

    if border_attachment == true then
      temp2 = temp2.where("attachment like ? OR attachment like ?", "%箱%", "%説明書%")
    end

    temp2 = temp2.where("diff_new_price >= ?", border_new_price)
    temp2 = temp2.where("diff_used_price >= ?", border_used_price)

    @candidates = temp2

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

    if @account.attachment == "true" then
      @flg_at = true
    else
      @flg_at = false
    end
    @flg_new = @account.new_price_diff.to_i
    @flg_used = @account.used_price_diff.to_i

    if request.post? then
      commit = params[:commit]
      if commit == "更新" then
        memos = params[:memo]
        labels = params[:label]
        checks = params[:check]
        jans =  params[:jan]
        new_prices =  params[:new_price]
        used_prices =  params[:used_price]
        logger.debug(memos)
        logger.debug(labels)
        logger.debug(jans)
        temp = Product.where(user: current_user.email)
        if checks != nil then
          checks.each do |key, value|
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
        end
        redirect_to products_show_path
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
        redirect_to products_show_path
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

        #Product.new.reload(current_user.email)
        redirect_to products_show_path
      elsif commit == "CSV出力" then
        checks = params[:check]
        if checks != nil then
          temp = Product.where(user: current_user.email)
          ids = Array.new
          checks.each do |key, value|
            tid = key.to_i
            if tid != 0 then
              ids.push(tid)
              #tag = temp.find(tid)
            end
          end
          tag = temp.where id: ids

          bom = "\uFEFF"
          output = CSV.generate(bom) do |csv|
            header = Constants::CONV_P.values
            keys = Constants::CONV_P.keys
            csv << header
            tag.each do |tt|
              buf = Array.new
              keys.each do |hh|
                buf.push(tt[hh])
              end
              csv << buf
            end
          end
          tt = Time.now
          strTime = tt.strftime("%Y%m%d%H%M")
          fname = "product_data_" + strTime + ".csv"
          logger.debug(fname)
          send_data(output, filename: fname, type: :csv)
        else
          redirect_to products_show_path
        end
      elsif commit == "データ取得" then
        checks = params[:check]
        account = Account.find_by(user: current_user.email)
        account.update(
          progress: 0
        )
        if checks != nil then
          temp = Product.where(user: current_user.email)
          ids = Array.new
          checks.each do |key, value|
            tid = key.to_i
            if tid != 0 then
              ids.push(tid)
            end
          end
          targets = Product.where id: ids
          data = targets.group(:jan, :asin, :new_price, :used_price).pluck(:jan, :asin, :new_price, :used_price)
          ProductPatrolJob.perform_later(current_user.email, data)
        else
          targets = Product.where(user: current_user.email)
          data = targets.group(:jan, :asin, :new_price, :used_price).pluck(:jan, :asin, :new_price, :used_price)
          ProductPatrolJob.perform_later(current_user.email, data)
        end
        redirect_to products_show_path
      end
    end
  end

  def search
    targets = Product.where(user: current_user.email)
    data = targets.group(:jan, :asin, :new_price, :used_price).pluck(:jan, :asin, :new_price, :used_price)
    ProductPatrolJob.perform_later(current_user.email, data)
    redirect_to products_show_path
  end


  def import
    user = current_user.email
    if request.post? then
      account = Account.find_by(user: user)
      account.update(
        progress: 0
      )
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
            if row[0] == nil || row[0].value == "" then break end
            if i != 0 then
              if row[0] != nil then
                asin = row[0].value.to_s
              end
              if row[1] != nil then
                title = row[1].value.to_s
              end
              if row[2] != nil then
                used_price = row[2].value.to_f
              end
              if row[3] != nil then
                new_price = row[3].value.to_f
              end
              if row[4] != nil then
                jan = row[4].value.to_s
              end
              if row[5] != nil then
                sales = row[5].value.to_i
              end
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
