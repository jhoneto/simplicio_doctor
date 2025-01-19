# frozen_string_literal: true

module NotificationHelper
  def active_notification_filter(button_filter, current_filter)
    if button_filter == current_filter
      "btn-primary"
    else
      "btn-outline-primary"
    end
  end
end
