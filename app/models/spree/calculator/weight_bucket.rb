module Spree
  class Calculator::WeightBucket < Calculator
    preference :weight_table, :string
    preference :price_table, :string
    preference :default_weight, :string, :default => 0
    preference :min_price, :string, :default => '50'
    preference :max_price, :string, :default => '10000000'

    attr_accessible :preferred_weight_table, :preferred_price_table, :preferred_default_weight, :preferred_min_price, :preferred_max_price

    def self.description
      "Weight buckets"
    end

    def self.register
      super
    end

    def available?(order)
      return false if order.total < self.preferred_min_price.to_f
      return false if order.total >= self.preferred_max_price.to_f

      return true
    end

    def compute(order)
      prices = self.preferred_price_table.nil? ? [] : self.preferred_price_table.split
      weights = self.preferred_weight_table.nil? ? [] : self.preferred_weight_table.split

      weight_prices = weights.to_enum(:each_with_index).map do |weight, i|
        {:weight => weight.to_f, :price => prices[i].to_f}
      end

      total_weight = 0
      order.line_items.each do |item|
        total_weight += item.quantity * (item.variant.weight || self.preferred_default_weight.to_f)
      end

      shipping_price = 0
      start_of_current_range = 0
      weight_prices.each do |weight_price|
        if total_weight >= start_of_current_range && total_weight < weight_price[:weight]
          shipping_price = weight_price[:price]
        end
        start_of_current_range = weight_price[:weight]
      end

      return shipping_price
    end
  end
end
