require 'open-uri'
require 'nokogiri'
require 'csv'

 data = [] #result data

# get information from product page
def getInfoFromPage (url)
  html_page = open(url)
  doc_page = Nokogiri::HTML(html_page)
  title = doc_page.css('.nombre_fabricante_bloque h1').text.strip
  image = doc_page.css('#bigpic')[0].attr('src').chop
  price = doc_page.css('.price_comb').text.chop
  info = {
      'title': title,
      'image': image,
      'price': price
  }

  return info
end

# for first page
html = open('https://www.petsonic.com/snacks-huesos-para-perros/?p=' + 1.to_s)
first_doc = Nokogiri::HTML(html)

first_doc.css('.ajax_block_product').each do |product|
  link = product.css('.product_img_link')[0].attr('href')
  data.push(getInfoFromPage(link))
end

# for other pages
page_number = 2

begin
  html = open('https://www.petsonic.com/snacks-huesos-para-perros/?p=' + page_number.to_s)
  doc = Nokogiri::HTML(html)

  if  doc.css('.ajax_block_product') !=  first_doc.css('.ajax_block_product') #if it's new page
    doc.css('.ajax_block_product').each do |product|
      link = product.css('.product_img_link')[0].attr('href')
      data.push(getInfoFromPage(link))
    end
    page_number += 1
  end
end while page_number < 11

# save result to file
CSV.open('info.csv', 'wb') do |csv|
  data.each do |item|
    csv << ['title: ' + item[:title], 'image: ' + item[:image], 'prices: ' + item[:price]]
  end
end