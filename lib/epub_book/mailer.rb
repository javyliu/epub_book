module EpubBook
  class Mailer
    extend Forwardable

    def_delegators :@mailer, :from,:from=,:to,:to=,:subject,:subject=,:body,:body=,:add_file

    def initialize
      @mailer = Mail.new do
        from    EpubBook.config.mail_from
        subject EpubBook.config.mail_subject
        #body    EpubBook.config.mail_body
        #add_file  File.join(File.dirname(__FILE__),'bbsl.epub')
      end
    end

    def send_mail
      @mailer.deliver!
    end

  end
end
