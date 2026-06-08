class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true

  # Googleのプロフィール情報から該当ユーザーを検索し、いなければ作成、
  # いれば名前を最新の状態に同期してDBへ保存する
  def self.from_google(info)
    user = find_or_initialize_by(email: info["email"])
    user.name = info["name"]
    user.save!
    user
  end
end
