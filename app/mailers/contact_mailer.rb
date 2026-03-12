class ContactMailer < ApplicationMailer
  def contact_message(name:, email:, message:)
    @name = name
    @email = email
    @message = message

    mail(
      to: "dageismar@gmail.com",
      subject: "New Contact Form Submission from #{name}",
      reply_to: email
    )
  end
end

