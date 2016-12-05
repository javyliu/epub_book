require "epub_book/version"
require 'epub_book/book'
require 'epub_book/loggable'
require 'mail'

module EpubBook
  # Your code goes here...
  autoload :Book, "epub_book/book"
  autoload :Mailer, "epub_book/mailer"

  Config = Struct.new(:setting_file,:mail_from,:mail_subject,:mail_body,:mail_address,:mail_port,:mail_user_name,:mail_password,:log_level) do
    include Singleton
    def initialize
      self.mail_subject =  'epub 电子书'
      #self.mail_body =  "您创建的电子书见附件\n"
      self.mail_port = 25
      self.log_level = "info"
    end
  end

  extend Loggable

  #book initialize, and the block will prior the yml setting
  def self.create_book(url,bookname=nil,des_url=nil)

    url_host_key = url[/\/\/(.*?)\//,1].tr(?.,'_')

    epub_book = Book.new(url,des_url) do |book|
      (default_config['book']||{}).merge(default_config[url_host_key]||{}).each_pair do |key,value|
        book.send("#{key}=",value)
      end
    end

    yield epub_book if block_given?

    #epub_book.fetch_index
    epub_book.generate_book(bookname)

    epub_book
  end


  def self.config
    Config.instance
  end

  def self.configure
    yield config
  end

  #you can set in configure block or default_setting.yml,and configure block prior the yml setting
  def self.default_config
    unless @default_config
      @default_config= YAML.load(File.open(config.setting_file || "#{`pwd`.strip}/default_setting.yml"))
      configure do |_config|
        @default_config['smtp_config'].each_pair do |key,value|
          _config[key] ||= value
        end
      end
      ::Mail.defaults do
        delivery_method :smtp, {
          :address => EpubBook.config.mail_address,
          :port => EpubBook.config.mail_port,
          :user_name => EpubBook.config.mail_user_name,
          :password => EpubBook.config.mail_password,
          :authentication => :plain,
          :enable_starttls_auto => true
        }
      end
    end
    @default_config
  end
end
