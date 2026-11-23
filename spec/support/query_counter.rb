module QueryCounter
  IGNORED_NAMES = %w[SCHEMA TRANSACTION].freeze

  # ブロックの中で実行されたSQLの回数を返す（キャッシュされたものと、内部の問い合わせは、数えない）
  def count_queries(&block)
    count = 0
    counter = lambda do |*, payload|
      count += 1 unless payload[:cached] || IGNORED_NAMES.include?(payload[:name])
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter, type: :request
end
