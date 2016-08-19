require 'spec_helper'

describe EpubBook do
  it 'has a version number' do
    expect(EpubBook::VERSION).not_to be nil
  end

  describe ".config" do
    #before  do
    #  EpubBook.default_config
    #end

    context 'not configure' do
      it 'return nil' do
        expect(EpubBook.config.mail_from).to eq(nil)
        expect(EpubBook.config.mail_password).to eq(nil)
      end
    end

  end

  describe '.configure' do

    describe 'not init @default_config' do
      context 'have a default_setting.yml' do
        it 'return original config' do
          expect(EpubBook.config.setting_file).to be_nil
        end

        it 'set config if invoke default_config' do
          EpubBook.default_config

          expect(EpubBook.config.setting_file).to be_nil

        end
      end

    end

    describe 'corfigure config' do

      let(:config) do
        EpubBook.configure do |config|
          config.mail_from = "test@example.com"
          config.mail_subject = "epub 电子书"
          config.mail_body = '您创建的电子书见附件'
          config.mail_address = "smtp.example.com"
          config.mail_port = 25
          config.mail_user_name = "test@example.com"
          config.mail_password = "test"
        end
        EpubBook.config

      end
      context 'setting config' do
        it 'return mail_from' do
          expect(config).to be_instance_of(EpubBook::Config)
          expect(config.mail_from).to eq("test@example.com")
          expect(config.mail_password).to eq("test")
        end
      end

      context 'have a default_setting.yml' do
        it 'return original config' do
          EpubBook.default_config
          expect(config.mail_from).to eq('test@example.com')
        end
      end
    end

  end

  describe '.create_book' do
    before :each do
      expect_any_instance_of(EpubBook::Book).to receive(:generate_book).with("bookname")
    end
    it 'use the default yml :book' do
      epub_book = EpubBook.create_book("http://www.example.com/bookindex.html","bookname")
      expect(epub_book).to be_instance_of(EpubBook::Book)
      expect(epub_book.instance_variable_get(:@index_url)).to eq("http://www.example.com/bookindex.html")
      expect(epub_book.limit).to eq(10)
      expect(epub_book.cover_css).to eq('.pic_txt_list .pic img')
    end

    it 'use the specify yml :www_piaotiao_net' do
      epub_book = EpubBook.create_book("http://www.piaotian.net/bookindex.html","bookname")
      expect(epub_book.instance_variable_get(:@index_url)).to eq("http://www.piaotian.net/bookindex.html")

      expect(epub_book.cover_css).to eq( '#content td>table:not(.grid) img[src$=jpg]')
    end

    it 'create book with a block' do
      epub_book = EpubBook.create_book("http://www.piaotian.net/bookindex.html","bookname") do |book|
        book.cover_css = "#content .cover"
        book.title_css = "#content .title"
      end

      expect(epub_book.cover_css).to eq( '#content .cover')
      expect(epub_book.title_css).to eq( '#content .title')

    end

  end

end
