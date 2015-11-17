module NegativeBalanceProtection
  module Actions
    class ShutdownWarningEmailToUser
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        NegativeBalanceMailer.shutdown_warning_email_to_user(user).deliver_now
      end
    end
  end
end