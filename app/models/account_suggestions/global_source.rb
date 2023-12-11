# frozen_string_literal: true

class AccountSuggestions::GlobalSource < AccountSuggestions::Source
  def key
    :global
  end

  def get(account, limit: 10)
    FollowRecommendation.localized(current_locale).joins(:account).merge(base_account_scope(account)).order(rank: :desc).limit(limit).pluck(:account_id)
  end

  private

  def current_locale
    I18n.locale.to_s.split(/[_-]/).first
  end
end
