# frozen_string_literal: true

class AccountSuggestions::FriendsOfFriendsSource < AccountSuggestions::Source
  def key
    :friends_of_friends
  end

  def get(account, limit: 10)
    Account.find_by_sql([<<~SQL.squish, { id: account.id, limit: limit }])
      WITH first_degree AS (
          SELECT target_account_id
          FROM follows
          JOIN accounts AS target_accounts ON follows.target_account_id = target_accounts.id
          WHERE account_id = :id
            AND NOT target_accounts.hide_collections
      )
      SELECT accounts.id, COUNT(*) AS frequency
      FROM accounts
      JOIN follows ON follows.target_account_id = accounts.id
      JOIN account_stats ON account_stats.account_id = accounts.id
      LEFT OUTER JOIN follow_recommendation_mutes ON follow_recommendation_mutes.target_account_id = accounts.id AND follow_recommendation_mutes.account_id = :id
      WHERE follows.account_id IN (SELECT * FROM first_degree)
        AND follows.target_account_id NOT IN (SELECT * FROM first_degree)
        AND follows.target_account_id <> :id
        AND accounts.discoverable
        AND accounts.suspended_at IS NULL
        AND accounts.silenced_at IS NULL
        AND accounts.moved_to_account_id IS NULL
        AND follow_recommendation_mutes.target_account_id IS NULL
      GROUP BY accounts.id, account_stats.id
      ORDER BY frequency DESC, account_stats.followers_count ASC
      LIMIT :limit
    SQL
  end
end
