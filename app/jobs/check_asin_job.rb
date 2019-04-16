class CheckAsinJob < ApplicationJob
  queue_as :check_asin

  rescue_from(StandardError) do |exception|
    logger.debug("===== Standard Error Escape Active Job =====")
    logger.error exception
  end

  def perform(user)
    products = Product.where(user: user)
    @account = Account.find_or_create_by(user: user)
    org_url = @account.shop_url
    maxnum = 1000
    ua = CSV.read('app/others/User-Agent.csv', headers: false, col_sep: "\t")

    for pgnum in 1..400
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
      temp = doc.css('div/@data-asin')

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
