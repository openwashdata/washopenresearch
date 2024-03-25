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

# UNC Newsletter issue release date and its url
unc_newletter_url = "https://us12.campaign-archive.com/home/?u=b41c2458c63f1551b2a7a6f44&id=681984abd7"
unc_newletter_page = requests.get(unc_newletter_url).content
soup = bs4.BeautifulSoup(unc_newletter_page, "html.parser")

# Retrieve newsletter archive list
archive_list = soup.find("ul", {"id":"archive-list"}).find_all("li")
issue_release_date = []
issue_url = []
for issue in archive_list:
    issue_release_date.append(issue.text.split(" ")[0])
    issue_url.append(issue.find("a")["href"])
archive_df = pd.DataFrame({"date":issue_release_date, "issue_url": issue_url})

# Extract paper title and url
issue, paper_url, paper_info =[], [], []
for issue_url in archive_df["issue_url"]:
    issue_page = requests.get(issue_url).content
    soup = bs4.BeautifulSoup(issue_page, "html.parser")
    has_research = "Research" in soup.find_all("ul")[-1].parent.span.text
    if has_research:
        research_list = soup.find_all("ul")[-1].find_all("li")
        issue += [issue_url]*len(research_list)

        for i in research_list:
            if i.find("a") is not None:
                url = i.find("a")["href"]
                try:
                    info = i.span.text
                except AttributeError:
                    info = i.p.text
                paper_url.append(url)
                paper_info.append(info)
            else:
                paper_url.append(None)
                paper_info.append(None)

# Extract paper title and url
issue, paper_url, paper_info =[], [], []
for issue_url in archive_df["issue_url"]:
    issue_page = requests.get(issue_url).content
    soup = bs4.BeautifulSoup(issue_page, "html.parser")
    has_research = "Research" in soup.find_all("ul")[-1].parent.span.text
    if has_research:
        research_list = soup.find_all("ul")[-1].find_all("li")
        issue += [issue_url]*len(research_list)

        for i in research_list:
            if i.find("a") is not None:
                url = i.find("a")["href"]
                try:
                    info = i.span.text
                except AttributeError:
                    info = i.p.text
                paper_url.append(url)
                paper_info.append(info)
            else:
                paper_url.append(None)
                paper_info.append(None)

paper_df = pd.DataFrame({"issue_url": issue, "paper_url": paper_url, "paper_info": paper_info})
paper_df['url_source'] = paper_df["paper_url"].apply(lambda x: x.split("/")[2])
paper_df.merge(archive_df, how = "left", on = "issue_url")