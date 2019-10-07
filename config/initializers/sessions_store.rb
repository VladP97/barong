# frozen_string_literal:true

# Store sessions in cache
Rails.application.config.session_store :cache_store, key: '_barong_session', domain: :all, tld_length: 2
Barong::App.set(:session_expire_time, '1800', type: :integer)
