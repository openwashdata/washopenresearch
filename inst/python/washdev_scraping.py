#!/usr/bin/env python
# coding: utf-8

import bs4
import requests
import os
import datetime
import pickle
import re
import pandas as pd
from tqdm import tqdm


# This script contains the code of scraping the data of Journal of Water, Sanitation and Hygiene for Development. 
headers = {
    'User-Agent': 'user'
} # need a header for authentification, otherwise get 403 back


# # Overview of all journal issues

# The following section will iterate all issues available online to get information of each issue, namely, 
# the volume and issue number, the accepted paper title and its url link. The journal starts from year 2011 
# as its first volume and made several changes on publication cycles. Since 2022, the journal publishes monthly.

# table of contents 
root = "https://iwaponline.com/washdev/issue" #volumne number/issue number

def get_issue_page(root, volume_id, issue_id, headers = {"User-Agent": "user"}):
    """
    
    """
    issue_url = os.path.join(root, str(volume_id), str(issue_id))
    page = requests.get(issue_url, headers=headers)
    status = page.status_code
    if status == 200:
        issue = {
            "volume": volume_id,
            "issue":issue_id,
            "page": page.content
        }
    else:
        print(f"Retrieve vol {volume_id} issue {issue_id} not successful!")
        issue = {
            "volume": volume_id,
            "issue":issue_id,
            "page": ""
        }
    return issue

# volume 1 (2011) - volume 13 (2023)
## Get all issues, access by volume 13 issue 11 
num_vol = 13
all_issues = []
for vol in range(1, num_vol+1):
    if vol <= 10:
        for i in range(1, 5):
            all_issues.append(get_issue_page(root, vol, i))
            
    elif vol == 11:
        for i in range(1, 7):
            all_issues.append(get_issue_page(root, vol, i))
    else:
        if vol == num_vol:
            for i in range(1, datetime.datetime.today().month): ## last month 
                all_issues.append(get_issue_page(root, vol, i))
        else:
            for i in range(1, 13):
                all_issues.append(get_issue_page(root, vol, i))
# TODO: update from current data, so we don't need to scrape all issues

# Retrieve data of each publication on supplementary materials, author, and data availability statement
# Supplementary data existence
def is_supp(soup):
    """
    True if having supplementary material
    """
    return False if soup.find("h2", id="supplementary-data") is None else True

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
    
def get_supp(soup):
    """
    Retrieve all variables related to supplementary materials
    """
    number_of_supp = get_supp_number(soup)
    supp_file_type = get_supp_file_type(soup)
    supp_file_link = get_supp_file_link(soup)
    supp = [is_supp(soup), number_of_supp, supp_file_type, supp_file_link]
    return supp

# First author (correspondence author) information
def get_author_info(soup):
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


# data availability statement variables
def has_das(soup):
    das = soup.find("h2", {"data-section-title": "DATA AVAILABILITY STATEMENT"})
    return True if das is not None else False

def get_das_text(soup):
    if has_das(soup):
        das = soup.find("h2", {"data-section-title": "DATA AVAILABILITY STATEMENT"})
        das_text = soup.find("div", {"data-section-parent-id": das["id"]}).text
        das_text = das_text.strip()
        
    else:
        das_text = None
    return das_text


def get_das_repo(das):
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

def get_das_info(soup):
    das_text = get_das_text(soup)
    das_type = None
    online = "All relevant data are available from an online repository or repositories"
    if das_text is not None and das_text.startswith(online):
        das_type = online
    else:
        das_type = das_text
    das_repo_url = get_das_repo(das_text)
    return [has_das(soup), das_text, das_type, das_repo_url]

    
# Keywords
def get_keywords(soup):
    keywords = []
    has_keyword = soup.find("div", {"class": "kwd-group"})
    if has_keyword:
        for k in has_keyword.children:
            if not isinstance(k, bs4.element.NavigableString):
                keywords.append(k.text)
    return keywords

def get_paper_metadata(url):
    paper = requests.get(url, headers = {"User-Agent": "user"})
    soup = bs4.BeautifulSoup(paper.content, "html.parser")
    if "unusual traffic" in str(paper.content):
        print(url)
    metadata = get_supp(soup) + get_author_info(soup) + get_das_info(soup) + [get_keywords(soup)] 
    return metadata


# Main scraping 
metadata = []
for url in tqdm(overview_df["url"]):
    metadata.append(get_paper_metadata(url))
metadata_columns = ["is_supp", "num_supp", "supp_file_type", "supp_link",
                    "num_authors", "first_author_name", "first_author_affiliation", "first_author_affiliation_country", 
                    "first_author_email", "first_author_orcid", "correspondence_author_name", "correspondence_author_affiliation",
                    "correspondence_author_affiliation_country", "correspondence_author_email", "correspondence_author_orcid",
                    "has_das", "das", "das_type", "das_repo_url", "keywords"]
metadata_df = pd.DataFrame(metadata, columns=metadata_columns)

# Concatenate overview and metadata
## TODO: revise
article_df = pd.read_csv("../data/raw/washdev-article-overview.csv", index_col=0)
metadata_df = pd.read_csv("../data/raw/washdev.csv", index_col=0)
washdev_df = pd.concat([article_df, metadata_df], axis=1)