class Notification < ApplicationRecord
  belongs_to :medical_organization_partner

  scope :unread, -> { where(read: false) }

  def read!
    update(read: true)
  end
end
