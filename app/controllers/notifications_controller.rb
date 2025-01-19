# fronzen_string_literal: true

class NotificationsController < BaseController
  include Pagy::Backend

  def index
    @notifications = current_medical_organization_partner.notifications.order("created_at desc")
    @notifications = @notifications.unread if params[:filter]&.to_sym == :unread
    @pagy, @notifications = pagy(@notifications)

    if @notifications.empty?
      head :no_content
    else
      respond_to do |format|
        format.html # Renderiza a página inicial
        format.turbo_stream # Para carregamento via Turbo Stream
      end
    end
  rescue Pagy::OverflowError
    head :no_content
  end

  def show
    @notification = current_medical_organization_partner.notifications.find(params[:id])
    @notification.read!
  end
end
