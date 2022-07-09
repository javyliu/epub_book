require 'http'
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
#ext_name 扩展名 epub,txt
#ignore_txt 忽略字符，带有ignore_txt的行将被删除
module EpubBook
  class Book
    UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"
    Referer = "http://www.baidu.com/"
    attr_accessor :title_css, :index_item_css, :body_css, :limit, :item_attr, :page_css, :page_attr,:cover,:cover_css, :description_css,:path,:user_agent,:referer,:creator,:mail_to, :folder_name,:des_url,:ext_name,:ignore_txt


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
      @ext_name = 'epub'
      yield self if block_given?
    end

    def book_path
      @book_path ||= File.join((@path || `pwd`.strip), @folder_name)
    end

    def link_host
      @link_host ||= @index_url[/\A(https?:\/\/.*?)\/\w+/,1]
    end

    def book
      return @book if @book
      Dir.mkdir(book_path) unless test(?d,book_path)
      @book = test(?s,File.join(book_path,'index.yml')) ? YAML.load(File.open(File.join(book_path,'index.yml'))) : {files: []}
    end

    #save catalog file
    def save_book
      File.open(File.join(book_path,'index.yml' ),'w') do |f|
        f.write(@book.to_yaml)
      end
    end


    #创建书本
    def generate_book(book_name=nil)
      #获取epub源数据
      fetch_index  if !test(?s,File.join(book_path,'index.yml'))

      book[:file_abs_name] = File.join(book_path,"#{book[:title]}.#{ext_name}")

      fetch_book
      if ext_name == 'epub'
        if  !@cover_css && @cover
          generate_cover = <<-eof
            convert #{File.expand_path("../../../#{@cover}",__FILE__)} -font tsxc.ttf -gravity center -fill red -pointsize 16 -draw "text 0,0 '#{book[:title]}'"  #{File.join(book_path,@cover)}
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
        _files = []
        book[:files].collect! do |item|
          _file = File.join(book_path,item[:content])
          if test(?f, _file)
            _files.push(_file)
            item
          end
        end
        book[:files].compact!

        epub.files _files.push(File.join(book_path,@cover))
        epub.nav book[:files]
        yield self if block_given?

        epub.save(book[:file_abs_name])
      end
      #send mail

      if mail_to
        mailer = Mailer.new
        mailer.to = mail_to
        mailer.add_file book[:file_abs_name]
        mailer.body = "您创建的电子书[#{book[:title]}]见附件\n"
        mailer.send_mail
      end

    end

    #得到书目索引
    def fetch_index(url=nil)
      book[:files] = []
      url ||= @index_url
      doc = Nokogiri::HTML(judge_encoding(HTTP.headers("User-Agent" => @user_agent ,'Referer'=> @referer).get(url).to_s))
      #generate index.yml
      EpubBook.logger.info "------Fetch index--#{url}---------------"

      if !book[:title]
        doc1 = if @des_url.nil?
                 doc
               else
                 Nokogiri::HTML(judge_encoding(HTTP.headers("User-Agent" => @user_agent ,'Referer'=> @referer).get(generate_abs_url(doc.css(@des_url).attr("href").to_s)).to_s))
               end
        get_des(doc1)
      end

      #binding.pry
      doc.css(@index_item_css).each do |item|
        _href = item.attr(@item_attr).to_s
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
      #fetch_index  if !test(?s,File.join(book_path,'index.yml'))
      EpubBook.logger.info "------Fetch book----------"
      #open a txt file to write
      if ext_name == 'txt'
        txt_file = File.open(book[:file_abs_name], 'a')
        txt_file.write("简介\n\n")
        txt_file.write('  ')
        txt_file.write(book[:description] || " ")
      end

      book[:files].each_with_index do |item,index|
        break if limit && index >= limit

        content_path = File.join(book_path,item[:content])

        #如果文件存在且长度不为0则获取下一个
        #binding.pry
        next if test(?s,content_path)

        begin
          doc_file = Nokogiri::HTML(judge_encoding(HTTP.headers("User-Agent" => @user_agent,'Referer'=> @referer).get(item[:url]).to_s))

          EpubBook.logger.info item[:label]
          #binding.pry
          if ext_name == 'pub'
            File.open(content_path,'w') do |f|
              f.write("<h3>#{item[:label]}</h3>")
              f.write(doc_file.css(@body_css).to_s.gsub(Reg,''))
            end
          else
            txt_file.write("\n\n")
            txt_file.write(item[:label])
            txt_file.write("\n  ")
            txt_file.write(doc_file.css(@body_css).text)
          end
        rescue  Exception => e
          EpubBook.logger.info "Error:#{e.message},#{item.inspect}"
          #EpubBook.logger.info e.backtrace
          next
        end
      end
      if ext_name == 'txt'
        txt_file.close
        EpubBook.logger.info "=============去除包含指定忽略字符的行======="
        EpubBook.logger.info ignore_txt
        if ignore_txt
          system("sed -i -r '/#{ignore_txt}/d' #{book[:file_abs_name]}")
        end

      end

    end


    private
    #is valid encoding
    def judge_encoding(str)
      EpubBook.logger.info str.encoding
      #/<meta.*?charset\s*=[\s\"\']?utf-8/i =~ str ? str : str.force_encoding('gbk').encode!('utf-8',invalid: :replace, undef: :replace)

      str.scrub('')! unless str.valid_encoding?
      str.encode!('utf-8') if str.encoding.name != 'UTF-8'

      EpubBook.logger.info "-------encode 后 #{str.encoding}"
      str
    end

    #得到书名，介绍，及封面
    def get_des(doc)
      book[:title] = doc.css(@title_css).text.strip

      #EpubBook.logger.info doc
      #EpubBook.logger.info @title_css

      #binding.pry
      if @cover_css && !book[:cover] && ext_name == 'epub'
        cover_url = doc.css(@cover_css).attr("src").to_s
        cover_url = generate_abs_url(cover_url) #link_host + cover_url unless cover_url.start_with?("http")
        cover_path = File.join(book_path,@cover)
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
