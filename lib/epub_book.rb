require "epub_book/version"
require 'epub_book/book'

module EpubBook
  # Your code goes here...
  autoload :Book, "epub_book/book"
  autoload :Mailer, "epub_book/mailer"

  def self.create_book(url,bookname=nil,&block)
    epub_book = Book.new(url,&block)
    #do |book|
    #  book.limit = 5
    #  book.cover_css = '.pic_txt_list .pic img'
    #  book.description_css = '.box p.description'
    #  book.title_css = '.pic_txt_list h3 span'
    #  book.index_item_css = 'ul.list li.c3 a'
    #  book.body_css = '.wrapper #content'
    #  book.creator = 'javy_liu'
    #  book.path  = '/home/oswap/ruby_test/epub_book/'
    #  book.user_agent = ''
    #  book.referer = ''
    #  book.mail_to = 'javy_liu@163.com'
    #end
    #epub_book.fetch_index
    epub_book.generate_book(bookname)
  end

  Config = Struct.new(:mail_from,:mail_subject,:mail_body,:mail_address,:mail_port,:mail_user_name,:mail_password)
  class Config
    include Singleton
    def initialize
      self.mail_subject =  'epub 电子书'
      self.mail_body =  "您创建的电子书见附件\n"
      self.mail_port = 25
      #mail_from
      #mail_address
      #mail_user_name
      #mail_password
    end
  end


  def self.config
    Config.instance
  end

  def self.configure
    yield config
  end
end
