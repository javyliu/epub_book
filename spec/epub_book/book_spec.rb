require 'spec_helper'

describe EpubBook::Book do

  subject { EpubBook::Book.new("http://www.test.com/n/bubushenglian/xiaoshuo.html") }

  describe "#link_host" do
    it 'return link host of the index_url' do
      expect(subject.link_host).to eql('http://www.test.com')
    end
  end

  describe "#book" do
    it 'return a hash' do
      expect(subject.book).to be_an_instance_of(Hash)
    end

    it 'return a hash with files key' do
      expect(subject.book).to have_key(:files)
    end

    it 'return a hash with files key,and the files is empty' do
      expect(subject.book[:files]).not_to be_nil
      expect(subject.book[:files]).to be_empty
    end
  end

  describe "#save_book" do
    before :each do
      @link_host = subject.link_host
      files = [
        {label: 'test_text', url: "#{@link_host}/test.html" },
        {label: 'test_text1', url: "#{@link_host}/test1.html"}
      ]
      subject.book[:files] = files

      @book_path = subject.instance_variable_get(:@book_path)

    end

    it 'no index.yml in book path' do
      expect(test(?s, File.join(@book_path, 'index.yml'))).to  be_nil
    end

    it 'have a index.yml after save_book' do
      subject.save_book
      expect(test(?s, File.join(@book_path, 'index.yml'))).to  be_truthy
    end

    it 'book with files' do
      expect(subject.book[:files].length).to eql(2)
      expect(subject.book[:files][0][:label]).to eql('test_text')
    end

    after :each do
      FileUtils.rm_f(File.join(@book_path, 'index.yml'))
    end

  end


end
