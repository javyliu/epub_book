require 'open-uri'
require 'nokogiri'
require 'eeepub'
require 'base64'
require 'yaml'

#index_url 书目录地址
#title_css 书名css路径
#index_item_css 目录页列表项目,默认 ul.list3>li>a
#body_css 内容css, 默认 .articlebody
#limit 用于测试时使用，得到页面的页数
#item_attr 目录页item获取属性 默认为 'href'
#page_css 分页css路径
#page_attr 分页链接地址属性
#path 存储目录
#user_agent 访问代理
#referer 访问原地址
#creator 责任人

module EpubBook
  class Book
    UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"
    Referer = "http://www.baidu.com/"
    attr_accessor :title_css, :index_item_css, :body_css, :limit, :item_attr, :page_css, :page_attr,:cover
    attr_accessor :cover_css, :description_css,:path,:user_agent,:referer,:creator,:mail_to


    Reg = /<script.*?>.*?<\/script>/m

    def initialize(index_url )
      @index_url = index_url
      @user_agent = UserAgent
      @referer = Referer
      @folder_name =  Base64.urlsafe_encode64(index_url)[-10..-3]
      @creator = 'javy_liu'
      @title_css = '.wrapper h1.title1'
      @index_item_css = 'ul.list3>li>a'
      @cover = 'cover.jpg'
      @body_css = '.articlebody'
      @item_attr = "href"
      yield self if block_given?
      @book_path = File.join((@path || `pwd`.strip), @folder_name)
    end


    def link_host
      @link_host ||= @index_url[/\A(http:\/\/.*?)\/\w+/,1]
    end

    def book
      @book ||= test(?s,File.join(@book_path,'index.yml')) ? YAML.load(File.open(File.join(@book_path,'index.yml'))) : ({files: []})
    end

    def save_book
      File.open(File.join(@book_path,'index.yml' ),'w') do |f|
        f.write(@book.to_yaml)
      end
    end


    #创建书本
    def generate_book(book_name=nil)
      Dir.mkdir(@book_path) unless test(?d,@book_path)
      #获取epub源数据
      fetch_book
      if  !@cover_css && @cover
        generate_cover = <<-eof
        convert #{File.expand_path("../../../#{@cover}",__FILE__)} -font tsxc.ttf -gravity center -fill red -pointsize 16 -draw "text 0,0 '#{book[:title]}'"  #{File.join(@book_path,@cover)}
        eof
        system(generate_cover)
      end

      epub = EeePub.make

      epub.title book[:title]
      epub.creator @creator
      epub.publisher @creator
      epub.date Time.now
      epub.identifier "http://javy_liu.com/book/#{@folder_name}", :scheme => 'URL'
      epub.uid "http://javy_liu.com/book/#{@folder_name}"
      epub.cover @cover
      epub.subject book[:title]
      epub.description book[:description] if book[:description]

      book[:files] = book[:files][0...limit] if limit

      epub.files book[:files].map{|item| File.join(@book_path,item[:content])}.push(File.join(@book_path,@cover))
      epub.nav book[:files]


      epub_file = File.join(@book_path,"#{book_name || @folder_name}.epub")

      epub.save(epub_file)

      #send mail
      puts mail_to
      if mail_to
        mailer = Mailer.new
        mailer.to = mail_to
        mailer.add_file epub_file

        mailer.send_mail
      end

    end


    def fetch_index(url=nil)
      url ||= @index_url
      doc = Nokogiri::HTML(open(URI.encode(url),"User-Agent" => @user_agent ,'Referer'=> @referer).read)
      #generate index.yml

      book[:title] ||= doc.css(@title_css).text.strip

      if @cover_css && !book[:cover]
        cover_url = doc.css(@cover_css).attr("src").to_s
        cover_url = link_host + cover_url unless cover_url.start_with?("http")
        system("curl #{cover_url} -o #{File.join(@book_path,@cover)} ")
        book[:cover] = File.join(@book_path,@cover)
      end

      if @description_css && !book[:description]
        book[:description] = doc.css(@description_css).text
      end

      doc.css(@index_item_css).each do |item|
        _href = URI.encode(item.attr(@item_attr).to_s)
        _href = link_host + _href unless _href.start_with?("http")
        book[:files] << {label: item.text, url: _href}
      end

      #如果有分页
      if @page_css && @page_attr
        if next_page = doc.css(@page_css).attr(@page_attr).to_s
          fetch_index(next_page)
        else
          return
        end
      end

      book[:files].each_with_index{|item,index| item[:content] = "#{index}.html"}

      #保存书目
      save_book

    end

    def fetch_book
      #重新得到书目，如果不存在或重新索引的话
      fetch_index  if !test(?s,File.join(@book_path,'index.yml'))
      book[:files].each_with_index do |item,index|
        break if limit && index >= limit

        content_path = File.join(@book_path,item[:content])

        #如果文件存在且长度不为0则获取下一个
        next if test(?s,content_path)

        begin
          doc_file = Nokogiri::HTML(open(item[:url],"User-Agent" => @user_agent,'Referer'=> @referer).read)

          File.open(content_path,'w') do |f|
            f.write("<h3>#{item[:label]}</h3>")
            f.write(doc_file.css(@body_css).to_s.gsub(Reg,''))
          end

          puts item[:label]

        rescue  Exception => e
          puts e.message
          puts e.backtrace.inspect
          next
        end
      end

    end

  end

end
