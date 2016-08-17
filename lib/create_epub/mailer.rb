require 'mail'

module CreateEpub
  class Mailer
    extend Forwardable
    ::Mail.defaults do
      delivery_method :smtp, {
        :address => CreateEpub.config.mail_address,
        :port => CreateEpub.config.mail_port,
        :user_name => CreateEpub.config.mail_user_name,
        :password => CreateEpub.config.mail_password,
        :authentication => :plain,
        :enable_starttls_auto => true
      }
    end

    def_delegators :@mailer, :from,:from=,:to,:to=,:subject,:subject=,:body,:body=,:add_file



    def initialize
      @mailer = Mail.new do
        from    CreateEpub.config.mail_from
        subject CreateEpub.config.mail_subject
        body    CreateEpub.config.mail_body
        #add_file  File.join(File.dirname(__FILE__),'bbsl.epub')
      end
    end

    def send_mail
      @mailer.deliver!
    end

  end
end
