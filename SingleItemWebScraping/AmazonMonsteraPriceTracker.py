## Guided Project: Web Scraping with Python
## Source: https://github.com/AlexTheAnalyst, with multiple modifications
## Goal: To create an automated web scraping tool that tracks a monstera plant's listing price on Amazon.
## Modules used: BeautifulSoup, requests, datetime, csv
## Code written in: Python 3.8

from bs4 import BeautifulSoup
import requests
import time

def check_price():
    
    ## Assumption: a product marked as Best Seller on the product category page would be subject to higher price activity. 
    URL = 'https://www.amazon.co.jp/%EF%BC%BB%E8%A6%B3%E8%91%89%E6%A4%8D%E7%89%A9%E3%81%AE%E5%B0%82%E9%96%80%E5%BA%97-%E5%BD%A9%E6%A4%8D%E5%81%A5%E7%BE%8E%EF%BC%BD-%E3%80%90%E3%83%96%E3%83%A9%E3%82%A6%E3%83%B3%E9%89%A2%E3%82%AB%E3%83%90%E3%83%BC%E4%BB%98%E3%80%91%E3%83%92%E3%83%A1%E3%83%A2%E3%83%B3%E3%82%B9%E3%83%86%E3%83%A96%E5%8F%B7%E9%89%A2/dp/B002LP2YI8/ref=sr_1_2_sspa?__mk_ja_JP=%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A&crid=394F5WC62TSQI&keywords=%E3%83%A2%E3%83%B3%E3%82%B9%E3%83%86%E3%83%A9&qid=1641711867&sprefix=%E3%83%A2%E3%83%B3%E3%82%B9%E3%83%86%E3%83%A9%2Caps%2C216&sr=8-2-spons&psc=1&spLa=ZW5jcnlwdGVkUXVhbGlmaWVyPUExQURYOVFMVFlGMjgxJmVuY3J5cHRlZElkPUEwMTUxMTczM1Y2NFM5TjFCNlpHNiZlbmNyeXB0ZWRBZElkPUFWMjRSNUxYSUhFSU8md2lkZ2V0TmFtZT1zcF9hdGYmYWN0aW9uPWNsaWNrUmVkaXJlY3QmZG9Ob3RMb2dDbGljaz10cnVl'
    
    ## Web-scraping best practise: spoof headers to make requests seem to be coming from a browser instead of a script.
    ## User-Agent found through https://httpbin.org/get
    headers = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36", 
    "Accept-Encoding":"gzip, deflate", 
    "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", 
    "DNT":"1","Connection":"close", 
    "Upgrade-Insecure-Requests":"1"
    }
    
    page = requests.get(URL, headers=headers)
    soup1 = BeautifulSoup(page.content,"lxml")
    soup2 = BeautifulSoup(soup1.prettify(), "lxml")
    title = soup2.find(id="productTitle").get_text().strip()
    price = soup2.find('span',attrs={'class': 'a-offscreen'}).get_text().strip()[1:]

    import datetime
    today = datetime.datetime.today()
    
    ## Code written for an automated appendage of data, instead of first file creation.
    import csv
    header = ['Title', 'Price','Timestamp']
    data = [title, price, today]
    with open('MonsteraPriceTracker.csv', 'a+', newline='', encoding='UTF8') as f:
        writer = csv.writer(f)
        writer.writerow(data)
        
check_price()

## The scraper will run on the background on a daily basis.
while(True):
  check_price()
  time.sleep(86400)

## For efficiency purpose we will just view the data on this interface
import pandas as pd
df = pd.read_csv(r'/Users/.../MonsteraPriceTracker.csv')
print(df)
