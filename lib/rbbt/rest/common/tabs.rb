module RbbtRESTHelpers
  class Tabs
    include RbbtRESTHelpers

    attr_accessor :headers, :codes, :content, :classes, :tab_classes
    def initialize(page)
      @page = page
    end

    def add(header = nil, code = nil, &block)
      
      @headers ||= []
      @codes ||= {}
      @content ||= {}

      if block_given? 
        html = $haml_6 ? capture(&block) : @page.capture_haml(&block)
      else
        html = nil
      end

      @headers << header
      @codes[header] = code.to_s if code
      @content[header] = html
    end

    def active(header=nil)
      @active ||= header.nil? ? false : header 
    end
  end
  
  def tabs(&block)
    tab = Tabs.new(self)
    block.call(tab)

    tab.headers.each do |header|
      code = tab.codes[header] || Misc.digest(header)
      content = tab.content[header]
    end

    partial_render('partials/tabs', :headers => tab.headers, :codes => tab.codes, :content => tab.content, :active => tab.active)
  end

end
