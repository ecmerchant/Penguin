class Product < ApplicationRecord

  require 'typhoeus'
  require 'mechanize'
  require 'open-uri'
  require 'redis'

  def reload(user)
    account = Account.find_by(user: user)
    if account == nil then
      return
    end

    border_condition = account.condition
    border_attachment = account.attachment
    border_new_price = account.new_price_diff.to_i
    border_used_price = account.used_price_diff.to_i

    if border_condition == "A以上" then
      filter_text = temp.where("condition like ?", "%A(美品)%")
    elsif border_condition == "AB以上" then
      temp = temp.where("condition like ? OR condition like ?", "%A(美品)%", "%AB(良品)%")
    elsif border_condition == "B以上" then
      temp = temp.where("condition like ? OR condition like ? OR condition like ?", "%A(美品)%", "%AB(良品)%", "%B(並品)%")
    end

    targets = Product.where(user: user)
    candidates = Candidate.where(user: user)
    candidates.update(filtered: true)

    targets.each do |tag|
      asin = tag.asin
      temp = candidates.where(asin: asin)

      if border_condition == "A以上" then
        temp = temp.where("condition like ?", "%A(美品)%")
      elsif border_condition == "AB以上" then
        temp = temp.where("condition like ? OR condition like ?", "%A(美品)%", "%AB(良品)%")
      elsif border_condition == "B以上" then
        temp = temp.where("condition like ? OR condition like ? OR condition like ?", "%A(美品)%", "%AB(良品)%", "%B(並品)%")
      end

      if border_attachment == true then
        temp = temp.where("attachment like ? OR attachment like ?", "%箱%", "%説明書%")
      end

      temp = temp.where("diff_new_price >= ?", border_new_price)
      temp = temp.where("diff_used_price >= ?", border_used_price)

      data_list = Array.new
      temp.each do |ts|
        data_list << Candidate.new(user: user, asin: asin, item_id: ts.item_id, filtered: false)
      end
      Candidate.import data_list, on_duplicate_key_update: {constraint_name: :for_upsert_candidate, columns: [:filtered]}
      data_list = nil

      result = temp.count
      tag.update(
        search_result: result.to_i
      )
    end
  end

  def search(user, data)
    data_list = Array.new
    perc = 0
    counter = 0
    total = data.count
    account = Account.find_by(user: user)
    account.update(
      progress: counter,
      search_num: total.to_i
    )

    product = Product.where(user: user)
    candidates = Candidate.where(user: user)
    logger.debug(total)

    data.each do |temp|
      jan = temp[0]
      asin = temp[1]
      new_price = temp[2].to_f
      used_price = temp[3].to_f
      logger.debug("==== ACCESS ====")
      url = "http://shop.kitamura.jp/used/list.html?limit=100&f[]=k3&n7c=1&q=" + jan.to_s
      logger.debug(url)
      agent = Mechanize.new
      page = agent.get(url)

      candidates.where(asin: asin).update(
        sold: true
      )

      targets = page.search("dl.item-element.used-element")
      hit_num = targets.count
      logger.debug(hit_num)
      data_list = Array.new
      targets.each do |target|

        item_page = target.at("a")[:href]
        item_page = "http://shop.kitamura.jp" + item_page
        item_id = /\/used\/([\s\S]*?)\//.match(item_page)[1]
        title = target.at("dd.omission a").inner_text
        price = target.at("span.red").inner_text
        price = price.gsub("¥","").gsub(",","").to_f
        logger.debug("=== ITEM ===")
        logger.debug(item_page)

        judge = candidates.find_by(asin: asin, item_id: item_id)

        if judge == nil then
          logger.debug("==== NEW ITEM ====")
          begin
            new_agent = Mechanize.new
            new_page = new_agent.get(item_page)

            temp = new_page.at("table.used-spec")
            specs = temp.search("tr")

            condition = nil
            attachment = nil
            memo = nil

            specs.each do |row|
              thead = row.at("th").inner_text
              if thead == "状態" then
                condition = row.at("td").inner_text
                condition = condition.gsub("商品の状態について", "")
              elsif thead == "付属品" then
                attachment = row.at("td").inner_text
              elsif thead == "備考" then
                memo = row.at("td").inner_text
              end
            end
            new_agent = nil
            new_page = nil

            diff_new_price = (0.85 * new_price.to_f).round(0) - price
            diff_used_price = (0.85 * used_price.to_f).round(0) - price
            if title != nil && title != "" then
              data_list << Candidate.new(user: user, jan: jan, asin: asin, item_id: item_id, url: item_page, title: title, price: price, attachment: attachment, memo: memo, condition: condition, diff_new_price: diff_new_price.to_i, diff_used_price: diff_used_price.to_i, sold: false)
            end
          rescue => e
            logger.debug(e)
          end
        else
          logger.debug("==== REGISTERD ITEM ====")
          begin
            judge.update(sold: false)
          rescue => e
            logger.debug(e)
          end
        end
      end
      Candidate.import data_list, on_duplicate_key_update: {constraint_name: :for_upsert_candidate, columns: [:url, :title, :price, :memo, :attachment, :condition, :diff_new_price, :diff_used_price, :sold]}
      temp = product.where(asin: asin)
      temp.update(search_result: hit_num.to_i)

      counter += 1
      account.update(
        progress: counter
      )
      data_list = nil

    end
  end

end
