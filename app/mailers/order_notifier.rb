require 'debugger'
class OrderNotifier < ActionMailer::Base
  default from: 'Sam Ruby <depot@example.com>'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.order_notifier.recived.subject
  #
  def recived(order)
    @order = order
    
    mail to: order.email, subject: 'Pragmatic Store Order Confirmation'
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.order_notifier.shipped.subject
  #
  def shipped(order)
    @order = order
    
    mail to: order.email, subject: 'Pragmatic Store Order Confirmation'
  end
end
