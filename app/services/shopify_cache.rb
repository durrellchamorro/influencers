module ShopifyCache
  # Caches both Products and the associated ProductVariants
  def self.pull_products
    pull_entity(ShopifyAPI::Product, Product) do |product_data|
      variants = product_data['variants'].map do |variant|
        pv = ProductVariant.find_or_initialize_by(id: variant['id'])
        pv.update(variant)
        pv
      end
      product_data.merge('variants' => variants)
    end
  end

  def self.pull_collects
    pull_entity ShopifyAPI::Collect, Collect
  end

  def self.pull_custom_collections
    pull_entity ShopifyAPI::CustomCollection, CustomCollection
  end

  def self.pull_all
    pull_collects
    pull_custom_collections
    pull_products
  end

  # Used to cache a Shopify Entity to a local database.
  #
  # Arguments:
  #
  # * api_entity: The ShopifyAPI class to query
  # * db_entity: The ActiveRecord class to save into
  # * query_params: a hash corresponting to the index query params of the
  # ShopifyAPI::Entity::where function. Useful for limiting the scope of the
  # cache update
  # * &block(data): data is the attributes hash of the shopify entity. The result
  # of the block is passed to the ActiveRecord::Base#update function.
  #
  # Returns: nil
  def self.pull_entity(api_entity, db_entity, query_params = {})
    puts "Starting pull of #{api_entity}"
    count = api_entity.count
    puts "Found #{count} records"
    limit = 250
    pages = count.fdiv(limit).ceil

    objects = (1..pages).flat_map do |page|
      where_args = query_params.merge(limit: limit, page: page)
      shopify_api_throttle
      api_entity.where(where_args)
    end

    objects.each do |object|
      data = block_given? ? yield(object.attributes.as_json) : object.attributes.as_json
      # instead of resetting the table you can find_or_initialize_by(id: object.id)
      # since the id's in the local DB are set as the id's in Shopify
      db_entity.find_or_initialize_by(id: object.id).update(data)
    end
    puts "Pull of #{api_entity} complete"
  end

  def self.shopify_api_throttle
    return if ShopifyAPI.credit_left > 5
    puts "CREDITS LEFT: #{ShopifyAPI.credit_left}"
    puts "SLEEPING 10"
    sleep 10
  end
end
