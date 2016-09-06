# EpubBook

EpubBook is a epub generator which wrap EeePub, handle internal book by nokkogiri, you can create epub book from internal book in shell and send the generated epub book to your email.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'epub_book'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install epub_book

## Usage
### create book
```ruby
  EpubBook.create_book(book_url,bookname, des_url) do |book|
    book.cover_css = '.pic_txt_list .pic img'
    book.description_css = '.box p.description'
    book.title_css = '.pic_txt_list h3 span'
    book.index_item_css = 'ul.list li.c3 a'
    book.body_css = '.wrapper #content'
    book.creator = 'javy_liu'
    book.path  = '/tmp'
  end
``` 


###use Setting
```ruby 
  #default setting, this setting is prior the default_setting.yml
  EpubBook.configure do |config|
    #if not set,it will use `pwd`/default_setting.yml
    config.setting_file = "./default_setting.yml"
    #you can set following setting in default_setting.yml
    config.mail_address = 'smtp.example.com'
    config.mail_user_name = 'ex@example.com'
    config.mail_password = 'password'
    config.mail_from = 'yourmail@example.com'
  end
```
Or use a ./default_setting.yml file have following content

```ruby 
  smtp_config:
    mail_from: smpt_from@example.com
    mail_subject: mail subject 
    mail_body: 'your content '
    mail_address: smtp.example.com
    mail_port: 25
    mail_user_name: smpt_mail@example.com
    mail_password: smpt_pwd

  #default book setting
  book:
    limit: 10
    cover_css: '.pic_txt_list .pic img'
    description_css: '.box p.description'
    title_css: '.pic_txt_list h3 span'
    index_item_css: 'ul.list li.c3 a'
    body_css: '.wrapper #content'
    creator: 'user name'
    path: '/'
    mail_to: 'yourmail@example.com'

  #special host book setting(the key is book_url's host which replacing the dot with underline)
  #http://www.piaotian.net/html/0/431/index.html
  www_piaotian_net:
    cover_css: '#content td>table:not(.grid) img[src$=jpg]'
    description_css: '#content td>table:not(.grid) div:last-child > text()'
    title_css: '#content h1'
    index_item_css: '.centent a'
    body_css: 'body > text()'

  #http://www.shumilou.co/yitongjiangshan/
  www_shumilou_co:
    cover_css: ".content .list img.sayimg"
    description_css: ".content .list:contains(img) > text()"
    title_css: ".content .list .tit b:first"
    index_item_css: ".content .list ul li a"
    body_css: '#content p'
```

if you have setting file , you can create book like following 
```ruby 
  EpubBook.create_book(book_url,bookname, des_url)
```

## Parameter specification
```ruby
  book_url(required): internal book index page url (this page may include the description or cover)
  bookname(optional): created book file name, if not set ,it will use the Base64.url_encode(book_url)[-10,-2] 
  des_url(optional): if the book cover and book description is not in book_url catalog,you can set this for the cover and description

``` 

## Block parameter specification
```ruby 
    book.cover_css       #book cover image css path
    book.description_css #book description css path
    book.title_css       #book title css path
    book.index_item_css  #book catalog item  css path
    book.body_css        #book content css path
    book.creator         #epub creator
    book.path            #epub book save path
    book.mail_to         #if your want send by email when epub created, set this to your email
```
## Perform `create_book` in your terminal
```bash
  create_book(book_catalog_link, bookname)
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/epub_book. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

