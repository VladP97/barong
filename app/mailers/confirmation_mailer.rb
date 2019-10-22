class ConfirmationMailer < ApplicationMailer
  default from: 'no-reply@example.com',
          return_path: 'system@example.com'

  def confirmation(email, token)
    @token = token
    mail(to: email,
         bcc: ["bcc@example.com", "Order Watcher <watcher@example.com>"])
  end
end