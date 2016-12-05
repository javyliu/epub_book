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
    attr_accessor :title_css, :index_item_css, :body_css, :limit, :item_attr, :page_css, :page_attr,:cover,:cover_css, :description_css,:path,:user_agent,:referer,:creator,:mail_to, :folder_name,:des_url


    Reg = /<script.*?>.*?<\/script>/m

    def initialize(index_url,des_url=nil )
      @index_url = index_url
      @des_url = des_url
      @user_agent = UserAgent
      @referer = Referer
      @folder_name = Base64.urlsafe_encode64(Digest::MD5.digest(@index_url))[0..-3]
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
      Dir.mkdir(@book_path) unless test(?d,@book_path)
      @book ||= test(?s,File.join(@book_path,'index.yml')) ? YAML.load(File.open(File.join(@book_path,'index.yml'))) : ({files: []})
    end

    def save_book
      File.open(File.join(@book_path,'index.yml' ),'w') do |f|
        f.write(@book.to_yaml)
      end
      book
    end


    #创建书本
    def generate_book(book_name=nil)
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

      book[:epub_file] = File.join(@book_path,"#{book_name || @folder_name}.epub")

      yield self if block_given?

      epub.save(book[:epub_file])

      #send mail

      if mail_to
        mailer = Mailer.new
        mailer.to = mail_to
        mailer.add_file book[:epub_file]
        mailer.body = "您创建的电子书[#{book[:title]}]见附件\n"
        mailer.send_mail
      end

    end

    #得到书目索引
    def fetch_index(url=nil, force: false)
      book[:files] = [] if force
      url ||= @index_url
      doc = Nokogiri::HTML(judge_encoding(open(URI.encode(url),"User-Agent" => @user_agent ,'Referer'=> @referer).read))
      #generate index.yml

      if !book[:title]
        doc1 = if @des_url.nil?
                 doc
               else
                 Nokogiri::HTML(judge_encoding(open(URI.encode(generate_abs_url(doc.css(@des_url).attr("href").to_s)),"User-Agent" => @user_agent ,'Referer'=> @referer).read))
               end
        get_des(doc1)
      end

      doc.css(@index_item_css).each do |item|
        _href = URI.encode(item.attr(@item_attr).to_s)
        next if _href.start_with?('javascript') || _href.start_with?('#')

        _href = generate_abs_url(_href)

        book[:files] << {label: item.text, url: _href}
      end

      #如果有分页
      if @page_css && @page_attr
        if next_page = doc.css(@page_css).attr(@page_attr).to_s
          fetch_index(generate_abs_url(next_page))
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
      EpubBook.logger.info "------Fetch book----------"
      book[:files].each_with_index do |item,index|
        break if limit && index >= limit

        content_path = File.join(@book_path,item[:content])

        #如果文件存在且长度不为0则获取下一个
        next if test(?s,content_path)

        begin
          doc_file = Nokogiri::HTML(judge_encoding(open(item[:url],"User-Agent" => @user_agent,'Referer'=> @referer).read))

          File.open(content_path,'w') do |f|
            f.write("<h3>#{item[:label]}</h3>")
            f.write(doc_file.css(@body_css).to_s.gsub(Reg,''))
          end


        rescue  Exception => e
          EpubBook.logger.info "Error:#{e.message}"
          #EpubBook.logger.info e.backtrace
          next
        end
      end

    end


    private
    #is valid encoding
    def judge_encoding(str)
      str.scrub! unless str.valid_encoding?
      /<meta.*?charset\s*=[\s\"\']?utf-8/i =~ str ? str : str.force_encoding('gbk').encode('utf-8',invalid: :replace)
    end

    #得到书名，介绍，及封面
    def get_des(doc)
      book[:title] = doc.css(@title_css).text.strip
      if @cover_css && !book[:cover]
        cover_url = doc.css(@cover_css).attr("src").to_s
        cover_url = generate_abs_url(cover_url) #link_host + cover_url unless cover_url.start_with?("http")
        cover_path = File.join(@book_path,@cover)
        system("curl #{cover_url} -o #{cover_path} ")
        book[:cover] = cover_path
      end

      if @description_css && !book[:description]
        book[:description] = doc.css(@description_css).text
      end
    end

    def generate_abs_url(url)
      if url.start_with?("http")
        url
      elsif url.start_with?("/")
        "#{link_host}#{url}"
      else
        @path_name ||= @index_url[/.*\//]
        "#{@path_name}#{url}"
      end

    end

  end

end
