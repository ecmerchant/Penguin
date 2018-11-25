class ProductPatrolJob < ApplicationJob
  queue_as :product_patrol

  rescue_from(StandardError) do |exception|
    logger.debug("===== Standard Error Escape Active Job =====")
    logger.error exception
  end

  def perform(user, data)
    Product.new.search(user, data)
  end

end
