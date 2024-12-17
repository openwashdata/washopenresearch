import bs4
import time
import random
import os
import re
import pandas as pd
from tqdm import tqdm
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium_stealth import stealth

options = Options()
# run in headless mode
options.add_argument("--disable-blink-features=AutomationControlled")


# Initialize the WebDriver (you may need to specify the path to your driver)
service = Service("/Users/ydubey/Documents/GitHub/washopenresearch/inst/python/chromedriver")
driver = webdriver.Chrome(service=service, options=options)

def get_issue_page(root, volume_id, issue_id):
    """Retrieve an issue html content for WASH Development using Selenium"""
    issue_url = os.path.join(root, str(volume_id), str(issue_id))
    driver.get(issue_url)
    
    # Wait for the page to load
    WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
    
    issue = {
        "volume": volume_id,
        "issue": issue_id,
        "page": driver.page_source
    }
    # Add a random sleep to avoid being blocked
    time.sleep(random.randint(1, 3))
    return issue

def get_paper_metadata(url):
    driver.get(url)
    
    # Wait for the page to load
    WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
    
    soup = bs4.BeautifulSoup(driver.page_source, "html.parser")
    
    if "unusual traffic" in driver.page_source:
        print(url)
    
    metadata = get_supp(soup) + get_author_info(soup) + get_das_info(soup) + [get_keywords(soup)]
    return metadata

def get_keywords(soup):
    """
    Get keywords of the publication
    """
    keywords = []
    has_keyword = soup.find("div", {"class": "kwd-group"})
    if has_keyword:
        for k in has_keyword.children:
            if not isinstance(k, bs4.element.NavigableString):
                keywords.append(k.text)
    return keywords

def is_supp(soup):
    """
    True if having supplementary material
    """
    return False if soup.find("h2", id="supplementary-data") is None else True


def get_supp(soup):
    """
    Retrieve all variables related to supplementary materials
    """
    number_of_supp = get_supp_number(soup)
    supp_file_type = get_supp_file_type(soup)
    supp_file_link = get_supp_file_link(soup)
    supp = [is_supp(soup), number_of_supp, supp_file_type, supp_file_link]
    return supp

def get_supp_number(soup):
    """
    Number of supplementary materials
    """
    number_of_supp = len(soup.find_all("div", {"class": "dataSuppLink"}))
    return number_of_supp

def get_supp_file_type(soup):
    """
    File types of the supplementary materials
    """
    supp_list = soup.find_all("div", {"class": "dataSuppLink"})
    if len(supp_list) == 0:
        return None
    elif len(supp_list)==1:
        supp_type = supp_list[0].span.next.next.split(" ")[1]
        return supp_type
    else:
        supp_type_list = []
        for s in supp_list:
            supp_type_list.append(s.span.next.next.split(" ")[1])
        num_type = len(set(supp_type_list))
        if num_type == 1:
            return supp_type_list[0]
        else: # TODO: separate a case for num_type is 2 
            return "misc"
        
def get_supp_file_link(soup):
    """
    URL of supplementary files if available
    """
    supp_list = soup.find_all("div", {"class": "dataSuppLink"})
    link = []
    for s in supp_list:
        link.append(s.a["href"])
    return link

def get_author_info(soup):
    """
    Collect metadata of first and correspondence author
    """
    try:
        first_author = soup.find("div", {"class": "info-card-author"})
        if first_author is not None:
            first_author_name = first_author.find("div", {"class": "info-card-name"}).next
            first_author_name = str.strip(first_author_name)
            first_author_has_affiliation = first_author.find("div", {"class": "aff"})
            if first_author_has_affiliation:
                if first_author_has_affiliation.span is not None:
                    first_author_affiliation = first_author_has_affiliation.span.nextSibling.text
                else:
                    first_author_affiliation = first_author_has_affiliation.text
                first_author_affiliation_country = first_author_affiliation.split(", ")[-1]
                first_author_affiliation_country = first_author_affiliation_country.split(" Email")[0]
            else:
                first_author_affiliation, first_author_affiliation_country = None, None
            first_author_has_email = first_author.select('a[href^=mailto]')
            first_author_email = first_author_has_email[0].text if first_author_has_email else None
            first_author_has_orcid = first_author.select('a[id^=contrib-orcid]')
            first_author_orcid = first_author_has_orcid[0]['href'] if first_author_has_orcid else None
            first_author_info = [first_author_name, first_author_affiliation, first_author_affiliation_country, 
                                 first_author_email, first_author_orcid]    
        else:
            return [0, None, None, None, None, None, None, None, None, None, None] # No author information
    except AttributeError:
        print(first_author_has_affiliation.span)
    try:
        corr_author_email_card = soup.find("div", {"class": "info-author-correspondence"})
        if corr_author_email_card is not None:
            corr_author = corr_author_email_card.parent
            corr_author_name = corr_author.find("div", {"class": "info-card-name"}).next
            corr_author_name = str.strip(corr_author_name)
            corr_author_has_aff = corr_author.find("div", {"class": "aff"})
            if corr_author_has_aff:
                if corr_author_has_aff.span is not None:
                    corr_author_affiliation = corr_author_has_aff.span.nextSibling.text
                else:
                    corr_author_affiliation = corr_author_has_aff.text
                corr_author_affiliation_country = corr_author_affiliation.split(", ")[-1]
                corr_author_affiliation_country = corr_author_affiliation_country.split(" Email")[0]
            else:
                corr_author_affiliation, corr_author_affiliation_country = None, None
            corr_author_has_email = corr_author.select('a[href^=mailto]')
            corr_author_email = corr_author_has_email[0].text if corr_author_has_email else None
            corr_author_has_orcid = corr_author.select('a[id^=contrib-orcid]')
            corr_author_orcid = corr_author_has_orcid[0]['href'] if corr_author_has_orcid else None
            corr_author_info = [corr_author_name, corr_author_affiliation, corr_author_affiliation_country,
                               corr_author_email, corr_author_orcid]
        else:
            corr_author_info = [None, None, None, None, None]
    except AttributeError:
        print(corr_author_email_card)
    num_authors = len(soup.find_all("div", {"class": "info-card-name"}))
    
    author = [num_authors] + first_author_info + corr_author_info
    return author

def has_das(soup):
    """
    True if the publication has a data availability statement
    """
    das = soup.find("h2", {"data-section-title": "DATA AVAILABILITY STATEMENT"})
    return True if das is not None else False

def get_das_text(soup):
    """
    Get original text of data availability statement
    """
    if has_das(soup):
        das = soup.find("h2", {"data-section-title": "DATA AVAILABILITY STATEMENT"})
        das_text = soup.find("div", {"data-section-parent-id": das["id"]}).text
        das_text = das_text.strip()
        
    else:
        das_text = None
    return das_text


def get_das_info(soup):
    """
    Collect all relevant metadata about data availability statement
    """
    das_text = get_das_text(soup)
    das_type = None
    online = "All relevant data are available from an online repository or repositories"
    if das_text is not None and das_text.startswith(online):
        das_type = online
    else:
        das_type = das_text
    das_repo_url = get_das_repo(das_text)
    return [has_das(soup), das_text, das_type, das_repo_url]

def get_das_repo(das):
    """
    Get online repository url if the data availability is online repository
    """
    if das is not None:
        das = das.strip()
        online = "All relevant data are available from an online repository or repositories"
        if das.startswith (online):
            repo = re.findall(r'\((https?://[^\s]+)\)', das.split(online)[1])
            if len(repo) == 0 :
                repo = re.findall(r'(https?://[^\s]+)', das.split(online)[1])
                if len(repo) == 0:
                    repo = re.findall(r'\(([^\s]+)\)', das.split(online)[1])
                    repo = repo[0] if len(repo) >0 else None
                else:
                    repo = repo[0]
            else:
                repo = repo[0]
        else:
            repo = None
    else:
        repo = None
    return repo


def get_issues(start_vol, end_vol, end_issue):
    #end_issue = datetime.datetime.today().month - 1 ## last month from current date
    issues = []
    for vol in range(start_vol, end_vol+1):
        if vol == end_vol:
            if end_vol <= 10 and end_issue > 4:
                raise AssertionError("Volume 1-10 only has 4 issues each, end_issue has to be smaller or equal to 4")
            elif end_vol == 11 and end_issue > 6:
                raise AssertionError("Volume 11 only has 6 issues, end_issue has to be smaller or equal to 6") 
            #elif end_vol > 11:
                #raise AssertionError("End_issue has to be smaller or equal to 12") 
            for i in range(1, end_issue+1):
              issues.append(get_issue_page(root, vol, i))
        else:
            if vol <= 10:
                for i in range(1, 5):
                    issues.append(get_issue_page(root, vol, i))
            elif vol == 11:
                for i in range(1, 7):
                    issues.append(get_issue_page(root, vol, i))
            else:
                for i in range(1, 13):
                    issues.append(get_issue_page(root, vol, i))
    return issues

def build_overview_table(issues):
    article_tbl = []
    root = "https://iwaponline.com"
    journal_name = "Journal of Water, Sanitation & Hygiene for Development"
    
    for issue in issues:
        issue_page = issue["page"]
        soup = bs4.BeautifulSoup(issue_page, "html.parser")
        article_list = soup.find("div", {"id":"ArticleList"})
        articles = article_list.find_all("a", {"href":re.compile("/washdev/article/"), "class":None})
        
        for a in articles:
            url = root + a["href"]
            title = a.text
            data_resource_id = a.parent["data-resource-id-access"]
            published_year = issue["volume"] + 2010
            article_tbl.append([data_resource_id, issue["volume"], issue["issue"], url, journal_name, title, published_year])
    
    overview_df = pd.DataFrame(article_tbl, columns=['paperid', 'volume', 'issue', 'url', 'journal', 'title', 'published_year'])
    return overview_df

def build_metadata_table(overview_df):
    metadata = []
    for url in tqdm(overview_df["url"]):
        metadata.append(get_paper_metadata(url))
    
    metadata_columns = ["is_supp", "num_supp", "supp_file_type", "supp_link", "num_authors", "first_author_name", "first_author_affiliation", "first_author_affiliation_country", "first_author_email", "first_author_orcid", "correspondence_author_name", "correspondence_author_affiliation", "correspondence_author_affiliation_country", "correspondence_author_email", "correspondence_author_orcid", "has_das", "das", "das_type", "das_repo_url", "keywords"]
    metadata_df = pd.DataFrame(metadata, columns=metadata_columns)
    return metadata_df

if __name__ == "__main__":
    root = "https://iwaponline.com/washdev/issue"
    
    try:
        issues = get_issues(start_vol=1, end_vol=14, end_issue=11)
        overview_df = build_overview_table(issues)
        metadata_df = build_metadata_table(overview_df)
        
        # Concatenate overview and metadata
        washdev_df = pd.concat([overview_df, metadata_df], axis=1)
        
        #washdev_df.to_csv("path/to/rawdata-directory/washdev.csv")
    finally:
        # Make sure to close the browser when done
        driver.quit()
