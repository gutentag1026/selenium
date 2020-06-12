from selenium import webdriver
import time
import csv
url = 'https://www.airbnb.com/s/Fremont--CA--United-States/homes?tab_id=all_tab&refinement_paths%5B%5D=%2Fhomes&query=Fremont%2C%20CA&place_id=ChIJ98rot0a_j4AR1IjYiTsx2oo&source=structured_search_input_header&search_type=search_query'
driver = webdriver.Chrome()
driver.get(url)
time.sleep(1)
houses = []
prices = []
total_page = driver.find_elements_by_class_name('_13n1po3b')[-1].text #get the last page number before ->
page_total = int(total_page) 
print(page_total)
with open('results.csv', 'w') as f:
    f.write("summary, price\n")
for page in range(page_total):
    if page in (1, page_total - 1):
        current_url = driver.current_url #get current page url
        driver.get(current_url) #load page
    links_per_page = driver.find_elements_by_xpath('//a[@class="_i24ijs"]') # I didn't bother navigating to each page to do extraction
    for link in links_per_page:    
        houses.append(link.get_attribute('href'))
    prices = driver.find_elements_by_xpath('//span[@class="_1p7iugi"]')
    summaries = links_per_page
    print("price is",len(prices),"summaries is", len(summaries))
    smaller = min(len(summaries),len(prices))
    bigger = max(len(summaries),len(prices))
    for i in range(smaller):
        summary = summaries[i].get_attribute('aria-label')
        price = prices[i].text.split("\n")[-1] #price element has 2 lines 
        print(summary)
        print(price)
        with open('results.csv', 'a') as f:
            f.write(summary.encode('utf-8') + "," + price.encode('utf-8') + "\n") #not sure this is correct but it does write into csv files after multiple failure
    if len(summaries) > len(prices):
        str = "summary" 
    else:
        str =  "price"
    for i in range(smaller, bigger, 1):
        if str == summary:
            summary = summaries[i].get_attribute('aria-label')
            price = 'NAN'
        elif str == price:
            price = prices[i].text.split("\n")[1]
            summary = 'NAN'
        print(summary)
        print(price)
        with open('results.csv', 'a') as f:
            f.write(summary.encode('utf-8') + "," + price.encode('utf-8') + "\n")
    if page < page_total - 1:   #cannot proceed on last page
        next_page = driver.find_element_by_xpath('//a[@aria-label="Next"]')
        next_page.click()
driver.quit()
