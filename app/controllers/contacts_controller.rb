class ContactsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :create ]
  skip_before_action :set_current_tenant, only: [ :create ]

  def create
    name = params[:name]
    email = params[:email]
    message = params[:message]

    if name.blank? || email.blank? || message.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "contact-form",
            partial: "contacts/form",
            locals: { error: "All fields are required" }
          )
        end
        format.html do
          redirect_to root_path, alert: "All fields are required"
        end
      end
      return
    end

    # Send email
    if Rails.env.development?
      ContactMailer.contact_message(name: name, email: email, message: message).deliver_now
    else
      ContactMailer.contact_message(name: name, email: email, message: message).deliver_later
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "contact-form",
          partial: "contacts/success"
        )
      end
      format.html do
        redirect_to root_path, notice: "Thank you for your message! We'll get back to you soon."
      end
    end
  end
end
