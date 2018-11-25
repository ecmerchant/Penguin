class Product < ApplicationRecord

  require 'typhoeus'
  require 'mechanize'
  require 'open-uri'

  def search(user, data)

    data_list = Array.new

    data.each do |temp|
      jan = temp[0]
      asin = temp[1]
      new_price = temp[2].to_f
      used_price = temp[3].to_f
      logger.debug("==== ACCESS ====")
      url = "http://shop.kitamura.jp/used/list.html?f[]=k3&q=" + jan.to_s

      agent = Mechanize.new
      page = agent.get(url)

      logger.debug(url)
      logger.debug(page.title)

      targets = page.search("dl.item-element.used-element")
      hit_num = targets.count

      product = Product.where(user: user, asin: asin)
      product.update(search_result: hit_num.to_s)

      targets.each do |target|
        item_page = target.at("a")[:href]
        item_page = "http://shop.kitamura.jp" + item_page
        item_id = /\/used\/([\s\S]*?)\//.match(item_page)[1]
        title = target.at("dd.omission a").inner_text
        price = target.at("span.red").inner_text
        price = price.gsub("¥","").gsub(",","").to_f

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

        p condition
        p attachment
        p memo

        new_agent = nil
        new_page = nil

        diff_new_price = new_price - price
        diff_used_price = used_price - price

        data_list << Candidate.new(user: user, jan: jan, asin: asin, item_id: item_id, url: item_page, title: title, price: price, attachment: attachment, memo: memo, condition: condition, diff_new_price: diff_new_price, diff_used_price: diff_used_price)

        p item_page
        p item_id
        p title
        p price.to_s
      end
    end

    Candidate.import data_list, on_duplicate_key_update: {constraint_name: :for_upsert_candidate, columns: [:url, :title, :price, :memo, :attachment, :condition, :diff_new_price, :diff_used_price]}

  end

end
