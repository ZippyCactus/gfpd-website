#!/usr/bin/env python3
# pyright: reportOptionalMemberAccess=false, reportOptionalSubscript=false

"""
Fetch Great Falls SC ordinances from Municode's internal API and write structured JSON.

The script:
  1. Reads the top-level tree (chapters/sections) using the CodesToc endpoint.
  2. Iterates each section `docId` and fetches HTML via CodesContent/docIds.
  3. Cleans the HTML and aggregates chapter/section content into JSON.

Run: python scripts/sync_ordinances.py
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import time
from dataclasses import dataclass, field
from typing import Iterable, List

import requests
from bs4 import BeautifulSoup
import argparse

BASE = "https://library.municode.com"
PRODUCT_ID = "13058"  # Great Falls code product id
JOB_ID = "430600"      # print job id observed from manual capture

TOC_ENDPOINT = f"{BASE}/api/codesToc/fullTree"
CONTENT_ENDPOINT = f"{BASE}/api/CodesContent/docIds"

# Headers captured from browser request; update COOKIE string if your session changes.
COOKIE = "_ga=GA1.1.1368568897.1760231002; visitedClients=[2435]; walkthroughViewed2=\"true\"; _ga_EWTX042HHN=GS2.1.s1760295143$o3$g0$t1760295210$j60$l0$h0"

HEADERS = {
    "accept": "application/json, text/plain, */*",
    "accept-language": "en-US,en;q=0.9",
    "cookie": COOKIE,
    "dnt": "1",
    "priority": "u=1, i",
    "referer": "https://library.municode.com/sc/great_falls/codes/code_of_ordinances?nodeId=COOR_CH1GEPR",
    "sec-ch-ua": '"Google Chrome";v="141", "Not?A_Brand";v="8", "Chromium";v="141"',
    "sec-ch-ua-mobile": "?1",
    "sec-ch-ua-platform": '"Android"',
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "user-agent": "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36",
    "x-csrf": "1",
}

@dataclass
class Section:
    id: str
    title: str
    url: str
    text: str = ""
    children: List[Section] = field(default_factory=list)

@dataclass
class Chapter:
    id: str
    title: str
    url: str
    sections: List[Section] = field(default_factory=list)


def fetch_json(url: str, params: dict) -> dict:
    response = requests.get(url, params=params, headers=HEADERS, timeout=30)
    response.raise_for_status()
    return response.json()


def collect_sections() -> List[Chapter]:
    params = {"jobId": JOB_ID, "nodeId": PRODUCT_ID, "productId": PRODUCT_ID}
    toc = fetch_json(TOC_ENDPOINT, params)

    chapters: List[Chapter] = []
    for chapter_node in toc.get("Children", []):
        chapter = build_chapter(chapter_node)
        if chapter.sections:
            chapters.append(chapter)
    return chapters


def build_chapter(node: dict) -> Chapter:
    node_id = node.get("Id")
    heading = node.get("Heading", "").strip()
    url = f"{BASE}/sc/great_falls/codes/code_of_ordinances?nodeId={node_id}" if node_id else ""

    chapter = Chapter(id=node_id, title=heading, url=url)
    for child in node.get("Children", []) or []:
        section = build_section(child)
        if section:
            chapter.sections.append(section)
    return chapter


def build_section(node: dict) -> Section | None:
    node_id = node.get("Id")
    if not node_id:
        return None

    heading = node.get("Heading", "").strip()
    url = f"{BASE}/sc/great_falls/codes/code_of_ordinances?nodeId={node_id}"
    doc_type = (node.get("Data") or {}).get("DocType")

    section = Section(id=node_id, title=heading, url=url)

    if doc_type == 1:
        section.text = fetch_section_html(node_id)
        time.sleep(0.4)

    for child in node.get("Children", []) or []:
        child_section = build_section(child)
        if child_section:
            section.children.append(child_section)

    has_content = bool(section.text.strip())
    has_children = bool(section.children)
    if has_content or has_children:
        return section
    return None


def fetch_section_html(section_id: str) -> str:
    params = {
        "docIds": section_id,
        "jobId": JOB_ID,
        "productId": PRODUCT_ID,
        "outputType": "html",
        "showChanges": "false",
    }
    response = requests.get(CONTENT_ENDPOINT, params=params, headers=HEADERS, timeout=30)
    response.raise_for_status()
    data = response.json()
    html = ""
    if isinstance(data, list) and data:
        first = data[0]
        html = first.get("content") or first.get("Content") or ""
    return clean_html(html)


CLEAN_RE = re.compile(r"\s+")


def clean_html(html: str) -> str:
    if not html:
        return ""
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "nav"]):
        tag.decompose()
    # unwrap anchors but keep href for reference
    for a in soup.find_all("a"):
        href = a.get("href")
        if href:
            a.insert_after(soup.new_string(f" ({href})"))
        a.unwrap()
    text = soup.get_text("\n")
    text = CLEAN_RE.sub(" ", text)
    text = re.sub(r"\n{2,}", "\n\n", text)
    return text.strip()


def serialize(chapters: List[Chapter]) -> List[dict]:
    return [chapter_to_dict(ch) for ch in chapters]


def chapter_to_dict(chapter: Chapter) -> dict:
    return {
        "id": chapter.id,
        "title": chapter.title,
        "url": chapter.url,
        "sections": [section_to_dict(section) for section in chapter.sections],
    }


def section_to_dict(section: Section) -> dict:
    payload = {
        "id": section.id,
        "title": section.title,
        "url": section.url,
    }
    if section.text:
        payload["text"] = section.text
    if section.children:
        payload["children"] = [section_to_dict(child) for child in section.children]
    return payload


def serialize_flat(chapters: List[Chapter]) -> List[dict]:
    flat_list: List[dict] = []

    def walk(section: Section, ancestry: List[str]):
        entry = {
            "id": section.id,
            "title": section.title,
            "url": section.url,
            "hierarchy": ancestry,
        }
        if section.text:
            entry["text"] = section.text
        flat_list.append(entry)
        for child in section.children:
            walk(child, ancestry + [section.title])

    for chapter in chapters:
        chapter_label = [chapter.title]
        for section in chapter.sections:
            walk(section, chapter_label)

    return flat_list


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Sync Great Falls ordinances from Municode")
    parser.add_argument(
        "--flat",
        action="store_true",
        help="Write a flattened list of sections with hierarchy metadata",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    chapters = collect_sections()
    output = pathlib.Path("assets/data/ordinances.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    data = serialize(chapters) if not args.flat else serialize_flat(chapters)
    output.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    label = "sections" if args.flat else "chapters"
    print(f"Wrote {len(data)} {label} to {output}")


if __name__ == "__main__":
    main()
