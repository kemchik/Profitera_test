require 'nokogiri'
require 'csv'
require 'curb'


class Logger
 def info(message)
  puts "Message: #{message}"
 end
end

class File
 def initialize
  @logger = Logger.new
 end

 def save_to_file_csv(data, number, file_name)
  logger.info "Write down information about the product #{number} to the file #{file_name}"

  CSV.open(file_name, 'wb') do |csv|
   data.each do |item|
    csv << "name: #{item[:name]} image: #{item[:image]} prices: #{item[:price]}"
   end
  end
 end

 private

 attr_reader :logger
end

class Parser
 ALL_PAGINATION_BOTTOMS_SPANS = "//*[@id='pagination_bottom']/ul/li/a/span"
 All_LI_IN_PRODUCT_LIST = "//ul[@id='product_list']//li"
 ALL_HREFS_ON_PRODUCT = "//a[@class='product-name']/@href"

 def initialize
  @logger = Logger.new
  @product = Product.new
  @file = File.new
 end

 def get_page(url, number)
  logger.info "Download page #{number}"
  http = Curl.get(url)
  product_p = http.body_str
  product_page = Nokogiri::HTML(product_p)
  return product_page
 end

 def get_number_of_pages(page)
  page_span = page.xpath(ALL_PAGINATION_BOTTOMS_SPANS)
  number_of_pages = page_span[page_span.size - 2].text.to_i
  return number_of_pages
 end

 def set_url_and_filename
  logger.info "Enter category link"
  @url = gets.chomp.strip.to_s
  # @url = 'https://www.petsonic.com/snacks-huesos-para-perros/'
  logger.info "Enter file name"
  @file_name = "#{gets.chop.to_s}.csv"
  # @file_name = 'infor.csv'
 end

 def get_information_about_every_product(page)
  amount_of_product = page.xpath(All_LI_IN_PRODUCT_LIST).size
  amount_of_product.times do |link|
   link_product = page.xpath(ALL_HREFS_ON_PRODUCT)[link].to_s
   data = product.get_information_from_product_page(link_product, link + 1)
   # file.save_to_file_csv(data, link + 1, @file_name)
  end
 end

 def get_information_about_category
  set_url_and_filename
  page = get_page(@url, '')
  data = []

  for number in 1..get_number_of_pages(page) + 1
   page = get_page(@url + '?p=' + number.to_s, number)
   get_information_about_every_product(page)
  end

  console.log(data)
  logger.info "The End!"
 end

 private

 attr_reader :logger, :product, :file
end

class Product
 ALL_LI_WITH_WEIGHT = "//ul[@class='attribute_radio_list']/li"
 H1_PRODUCT_NAME = "//h1[@class='product_main_name']/text()"
 SRS_ON_IMAGE = "//img[@id='bigpic']/@src"
 ALL_PRODUCT_PRICES = "//span[@class='price_comb']"
 ALL_PRODUCT_WEIGHT = "//span[@class='radio_label']/text()"

 def initialize
  @logger = Logger.new
 end

 def get_information_from_product_page(url, number)
  page = get_page(url, number)
  elements = get_elements(page)
  return elements
 end

 def get_page(url, number)
  logger.info "Download product page #{number}"
  http = Curl.get(url)
  product_p = http.body_str
  product_page = Nokogiri::HTML(product_p)
  return product_page
 end

 def get_elements(page)
  products = []
  number_of_weights = page.xpath(ALL_LI_WITH_WEIGHT).size
  product_name = page.xpath(H1_PRODUCT_NAME).text.strip
  image_link = page.xpath(SRS_ON_IMAGE).text.strip.to_s

  data = get_each_weight_and_price(page, number_of_weights)
  data.each do |item|
   products.push(
       name: "#{product_name} - #{item[:weight]}",
       price: item[:price],
       image: image_link,
       )
  end
  return products
 end

 def get_each_weight_and_price(page, number_el_product)
  weight_and_prices = []
  number_el_product.times do |number|
   product_weight = page.xpath(ALL_PRODUCT_WEIGHT)[number].text.strip
   product_price = page.xpath(ALL_PRODUCT_PRICES)[number].text.strip
   weight = " #{product_weight} "
   weight_and_prices.push(
       weight: weight,
       price: product_price,
       )
  end

  return weight_and_prices
 end

 private

 attr_reader :logger
end


Parser.new.get_information_about_category