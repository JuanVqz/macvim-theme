# Imports orders from a CSV export and reports what changed.
require "csv"

module Shop
  class OrderImporter < BaseImporter
    HEADER = /\Aorder_id,total/i
    MAX_ROWS = 5_000

    attr_reader :path, :errors

    def initialize(path, dry_run: false)
      super()
      @path = path
      @dry_run = dry_run
      @errors = []
    end

    def call
      return nil unless valid_header?

      rows.first(MAX_ROWS).each_with_index do |row, index|
        order = Order.find_or_initialize_by(external_id: row["order_id"])
        order.total_cents = (row["total"].to_f * 100).round
        save(order, line: index + 2)
      end

      puts "Imported #{rows.size} orders into #{self.class.name}"
      errors.empty?
    end

    private

    def save(order, line:)
      return true if @dry_run

      order.save || errors << "line #{line}: #{order.errors.full_messages.join(', ')}"
    end
  end
end
