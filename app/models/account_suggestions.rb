# frozen_string_literal: true

class AccountSuggestions
  include DatabaseHelper

  SOURCES = [
    AccountSuggestions::SettingSource,
    AccountSuggestions::FriendsOfFriendsSource,
    AccountSuggestions::GlobalSource,
  ].freeze

  TARGET_SET_SIZE = 100

  def initialize(account)
    @account = account
  end

  def get(limit, offset = 0)
    with_read_replica do
      account_ids = Rails.cache.fetch("follow_recommendations/#{@account.id}", expires_in: 15.minutes) do
        arr = []

        SOURCES.each do |klass|
          break if arr.size >= TARGET_SET_SIZE

          # FIXME: We're not keeping track of which algorithm the IDs come from
          arr.concat(klass.new.get(@account, limit: TARGET_SET_SIZE - arr.size))
        end

        arr
      end

      # The sources deliver accounts that haven't yet been followed, are not blocked,
      # and so on. Since we reset the cache on follows, blocks, and so on, we don't need
      # a complicated query on this end.
      Account.where(id: account_ids).limit(limit).offset(offset).sort_by { |account| account_ids.index(account.id) }.map { |account| AccountSuggestions::Suggestion.new(account: account, source: nil) }
    end
  end

  def remove(target_account_id)
    FollowRecommendationMute.create(account_id: @account.id, target_account_id: target_account_id)
  end
end
