#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
REGISTRY_FILE = File.join(TABLE_DIR, "canon_source_registry.tsv")
MANIFEST_FILE = File.join(BUILD_DIR, "manifests", "canon_build_manifest.yml")

HEADERS = %w[
  source_id source_title source_type source_scope source_date source_citation edition editors_or_authors
  publisher coverage_limits extraction_method packet_ids extraction_status notes
].freeze

def read_registry(path)
  return [] unless File.exist?(path)

  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_registry(path, rows)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: HEADERS) do |csv|
    rows.sort_by { |row| row["source_id"].to_s }.each do |row|
      csv << HEADERS.map { |header| row[header] }
    end
  end
end

new_rows = [
  {
    "source_id" => "e013_cambridge_history_latin_american_lit_1996",
    "source_title" => "The Cambridge History of Latin American Literature",
    "source_type" => "region_literary_history",
    "source_scope" => "Latin American literature including Brazilian literature, pre-Columbian traditions, colonial literature, and twentieth-century literature",
    "source_date" => "1996; online 2008",
    "source_citation" => "Cambridge Core series page: https://www.cambridge.org/core/series/cambridge-history-of-latin-american-literature/F1BAF6C15BEBF9D61A58A0CE54C4338B",
    "edition" => "3 vols.",
    "editors_or_authors" => "Roberto Gonzalez Echevarria; Enrique Pupo-Walker",
    "publisher" => "Cambridge University Press",
    "coverage_limits" => "Reference/history layer, not anthology inclusion evidence; chapter text partly gated",
    "extraction_method" => "Extract public chapter TOC and bibliography structure; use named works as context and authority, not direct canon votes",
    "packet_ids" => "E013",
    "extraction_status" => "ready_partial_public",
    "notes" => "Latin American literary-history authority layer"
  },
  {
    "source_id" => "e013_oxford_latin_american_short_stories_1997",
    "source_title" => "The Oxford Book of Latin American Short Stories",
    "source_type" => "field_anthology",
    "source_scope" => "Latin American short fiction from colonial period to contemporary period",
    "source_date" => "1997",
    "source_citation" => "CCA library TOC: https://library.cca.edu/cgi-bin/koha/opac-ISBDdetail.pl?biblionumber=32656 ; Google Books: https://books.google.com/books/about/The_Oxford_Book_of_Latin_American_Short.html?id=MHDRCwAAQBAJ",
    "edition" => "1st ed.",
    "editors_or_authors" => "Roberto Gonzalez Echevarria",
    "publisher" => "Oxford University Press",
    "coverage_limits" => "Short-story only; translated selections; not full-work evidence for authors",
    "extraction_method" => "Extract public TOC story rows with author and translator where available; classify complete story versus excerpt",
    "packet_ids" => "E013",
    "extraction_status" => "ready_public_toc",
    "notes" => "High-priority extractable Latin American short-fiction anthology"
  },
  {
    "source_id" => "e013_oxford_latin_american_poetry_2009",
    "source_title" => "The Oxford Book of Latin American Poetry: A Bilingual Anthology",
    "source_type" => "poetry_anthology",
    "source_scope" => "Latin American poetry across more than 500 years, multilingual, original texts plus English translations",
    "source_date" => "2009",
    "source_citation" => "Google Books: https://books.google.com/books/about/The_Oxford_Book_of_Latin_American_Poetry.html?id=UJ-Qj-Sx4RoC ; Calicut library TOC: https://find.uoc.ac.in/Record/308884/TOC",
    "edition" => "illustrated ed.",
    "editors_or_authors" => "Cecilia Vicuna; Ernesto Livon-Grosman",
    "publisher" => "Oxford University Press",
    "coverage_limits" => "Poetry-only; many excerpts, oral/codex items, and translation-title variants",
    "extraction_method" => "Extract poem and selection rows from public TOC; flag excerpts, anonymous/traditional items, original language, and collection/cycle cases",
    "packet_ids" => "E013",
    "extraction_status" => "ready_public_toc",
    "notes" => "Strong Latin American poetry layer"
  },
  {
    "source_id" => "e013_fsg_20c_latin_american_poetry_2011",
    "source_title" => "The FSG Book of Twentieth-Century Latin American Poetry",
    "source_type" => "poetry_anthology",
    "source_scope" => "Twentieth-century Latin American poetry in Spanish, Portuguese, Ladino, Spanglish, and Indigenous languages",
    "source_date" => "2011/2012",
    "source_citation" => "Macmillan: https://academic.macmillan.com/academictrade/9780374533182/thefsgbookoftwentiethcenturylatinamericanpoetry/ ; Boulder library TOC: https://boulder.marmot.org/GroupedWork/07e23042-8c1d-b5bd-5f7c-81eebfe68805/Home",
    "edition" => "1st ed.; trade paperback",
    "editors_or_authors" => "Ilan Stavans",
    "publisher" => "Farrar, Straus and Giroux",
    "coverage_limits" => "Twentieth-century poetry only; overlaps Oxford poetry; edition page counts differ by format",
    "extraction_method" => "Extract author and poem rows from library TOC; preserve bilingual titles and translator or edition notes where exposed",
    "packet_ids" => "E013",
    "extraction_status" => "ready_public_toc",
    "notes" => "Modern Latin American poetry comparator"
  },
  {
    "source_id" => "e014_rienner_anthology_african_lit_2007",
    "source_title" => "The Rienner Anthology of African Literature",
    "source_type" => "field_anthology",
    "source_scope" => "African oral and written literature from ancient cultures to the present, continent-wide",
    "source_date" => "2007",
    "source_citation" => "Lynne Rienner official page and contents: https://www.rienner.com/title/The_Rienner_Anthology_of_African_Literature",
    "edition" => "paperback; 977 pages",
    "editors_or_authors" => "Anthonia C. Kalu",
    "publisher" => "Lynne Rienner Publishers",
    "coverage_limits" => "Many rows are excerpts, chapters, acts, oral-tradition selections, or translated pieces",
    "extraction_method" => "Extract official contents by part, region, and period; classify complete piece, excerpt, oral item, drama act, and novel chapter",
    "packet_ids" => "E014",
    "extraction_status" => "ready_public_toc",
    "notes" => "Priority African literature anthology layer"
  },
  {
    "source_id" => "e014_cambridge_history_african_caribbean_lit_2000",
    "source_title" => "The Cambridge History of African and Caribbean Literature",
    "source_type" => "region_literary_history",
    "source_scope" => "African and Caribbean literary history, oral traditions through postcolonial literatures",
    "source_date" => "2000; online 2008",
    "source_citation" => "Cambridge Vol. 1: https://www.cambridge.org/core/books/the-cambridge-history-of-african-and-caribbean-literature/1B9F2963235BC68CB3CA5EA6D534AC60 ; Vol. 2: https://www.cambridge.org/core/books/cambridge-history-of-african-and-caribbean-literature/383D7F023CD01BFB6AF3F29A7CDD7EB7",
    "edition" => "2 vols.",
    "editors_or_authors" => "F. Abiola Irele; Simon Gikandi",
    "publisher" => "Cambridge University Press",
    "coverage_limits" => "Includes Caribbean; chapter-level reference source, not direct anthology evidence; text partly gated",
    "extraction_method" => "Extract chapter TOC and African chapter metadata; use for regional, language, and boundary checks",
    "packet_ids" => "E014",
    "extraction_status" => "ready_partial_public",
    "notes" => "African and Caribbean literary-history context layer"
  },
  {
    "source_id" => "e014_penguin_modern_african_poetry_4e_2007",
    "source_title" => "The Penguin Book of Modern African Poetry",
    "source_type" => "poetry_anthology",
    "source_scope" => "Modern African poetry; 99 poets from 27 countries",
    "source_date" => "2007",
    "source_citation" => "Penguin Random House: https://www.penguinrandomhouse.com/books/301584/the-penguin-book-of-modern-african-poetry-by-edited-by-gerald-moore-introduction-by-gerald-moore-and-ulli-beier/",
    "edition" => "4th ed.",
    "editors_or_authors" => "Gerald Moore; Ulli Beier",
    "publisher" => "Penguin Classics",
    "coverage_limits" => "Official page gives strong metadata but not complete public TOC; poetry-only",
    "extraction_method" => "Extract publisher metadata now; seek library or physical TOC before claiming exhaustive poem-level rows",
    "packet_ids" => "E014",
    "extraction_status" => "ready_partial_public",
    "notes" => "Modern African poetry layer"
  },
  {
    "source_id" => "e014_african_writers_series_heinemann_penguin",
    "source_title" => "African Writers Series",
    "source_type" => "authoritative_edition_series",
    "source_scope" => "Modern African literary edition series: fiction, poetry, drama, essays, and biography",
    "source_date" => "1962-current; 2023 title list",
    "source_citation" => "Pearson PDF: https://www.pearson.com/content/dam/one-dot-com/one-dot-com/international-schools/pdfs/rights-and-licensing/African-Writers-Series-2023-Oct.pdf ; Penguin Random House series: https://www.penguinrandomhouse.com/series/PAF/penguin-african-writers-series/",
    "edition" => "series",
    "editors_or_authors" => "Heinemann/Pearson editors; Penguin Classics relaunch",
    "publisher" => "Pearson / Penguin Random House",
    "coverage_limits" => "Edition/reception evidence, not anthology vote; English/translation and publishing-history skew; includes nonliterary prose",
    "extraction_method" => "Parse Pearson title-list PDF and Penguin Random House title pages; classify genre, author, original language where known, and exact work identity",
    "packet_ids" => "E014",
    "extraction_status" => "public_index_ready",
    "notes" => "Important African edition/reception series, not standalone inclusion evidence"
  },
  {
    "source_id" => "murty_classical_library_india",
    "source_title" => "Murty Classical Library of India",
    "source_type" => "translation_series",
    "source_scope" => "Classical Indian literature across multiple Indic languages, with English translations facing original scripts",
    "source_date" => "2015-ongoing",
    "source_citation" => "Books: https://www.murtylibrary.com/books ; mission: https://www.murtylibrary.com/about/our-mission ; Harvard South Asia Institute: https://mittalsouthasiainstitute.harvard.edu/2022/03/murty-classical-library/",
    "edition" => "ongoing bilingual series",
    "editors_or_authors" => "Murty Classical Library of India editorial board",
    "publisher" => "Harvard University Press",
    "coverage_limits" => "Selective and ongoing; premodern/classical emphasis; edition/translation support, not standalone canon-vote evidence",
    "extraction_method" => "Parse books, language, and product pages; one row per volume and contained primary text; classify complete work versus selection or volume",
    "packet_ids" => "E015",
    "extraction_status" => "ready_public_metadata",
    "notes" => "Major modern edition/translation layer for classical South Asian works"
  },
  {
    "source_id" => "clay_sanskrit_library_56vol",
    "source_title" => "The Complete Clay Sanskrit Library",
    "source_type" => "translation_series",
    "source_scope" => "Classical Sanskrit literature in 56 bilingual volumes, including epic, drama, poetry, narrative, Buddhist, and Jain materials",
    "source_date" => "2005-2009",
    "source_citation" => "Clay Sanskrit Library volume list: https://claysanskritlibrary.org/volumes/volumes-list/ ; NYU Press set: https://nyupress.org/9780814717431/the-complete-clay-sanskrit-library/",
    "edition" => "56-volume set",
    "editors_or_authors" => "Clay Sanskrit Library editors",
    "publisher" => "NYU Press / JJC Foundation",
    "coverage_limits" => "Sanskrit only; completed/discontinued; many rows are epic books, selections, or multi-volume parts rather than whole works",
    "extraction_method" => "Parse official volume list and NYU product metadata; group multi-volume works; flag partial epic and book scope",
    "packet_ids" => "E015",
    "extraction_status" => "public_index_ready",
    "notes" => "Strong Sanskrit edition/translation authority layer"
  },
  {
    "source_id" => "oxford_modern_indian_poetry_1998",
    "source_title" => "The Oxford Anthology of Modern Indian Poetry",
    "source_type" => "poetry_anthology",
    "source_scope" => "Twentieth-century Indian poetry: 125 poets in English and English translation from 14 Indian languages",
    "source_date" => "1998",
    "source_citation" => "Oxford India page: https://india.oup.com/product/the-oxford-anthology-of-modern-indian-poetry-9780195639179/ ; National Library of Australia: https://catalogue.nla.gov.au/catalog/1539648",
    "edition" => "Oxford India Paperbacks",
    "editors_or_authors" => "Vinay Dharwadker; A. K. Ramanujan",
    "publisher" => "Oxford University Press",
    "coverage_limits" => "India-focused and poetry-only; poem-level evidence, not full-book evidence",
    "extraction_method" => "Use OUP metadata plus library TOC; extract poet, poem, section, and language/translation where available",
    "packet_ids" => "E015",
    "extraction_status" => "ready_public_toc",
    "notes" => "Major modern Indian poetry anthology layer"
  },
  {
    "source_id" => "brians_modern_south_asian_lit_english_2003",
    "source_title" => "Modern South Asian Literature in English",
    "source_type" => "region_literary_history",
    "source_scope" => "Introductory critical guide to major modern South Asian English-language fiction from India, Pakistan, and Sri Lanka",
    "source_date" => "2003",
    "source_citation" => "Bloomsbury: https://www.bloomsbury.com/us/modern-south-asian-literature-in-english-9780313320118/",
    "edition" => "1st ed.",
    "editors_or_authors" => "Paul Brians",
    "publisher" => "Greenwood / Bloomsbury",
    "coverage_limits" => "English-language modern fiction only; 15 selected chapters; weak for vernacular, poetry, Bangladesh, and Nepal coverage",
    "extraction_method" => "Extract chapter and work rows from public TOC; treat as literary-history/context support, not anthology inclusion",
    "packet_ids" => "E015",
    "extraction_status" => "ready_public_toc",
    "notes" => "Modern South Asian Anglophone fiction context layer"
  },
  {
    "source_id" => "columbia_traditional_chinese_lit_1996",
    "source_title" => "The Columbia Anthology of Traditional Chinese Literature",
    "source_type" => "field_anthology",
    "source_scope" => "Traditional Chinese literature across foundations, poetry, prose, fiction, drama, criticism, and popular/peripheral forms",
    "source_date" => "1996",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/the-columbia-anthology-of-traditional-chinese-literature/9780231074292/ ; library TOC: https://search.cpl.org/Record/a207337",
    "edition" => "Translations from the Asian Classics",
    "editors_or_authors" => "Victor H. Mair",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Public publisher page exposes high-level contents; library TOC helps item-level extraction; many items are excerpts/selections",
    "extraction_method" => "Extract public TOC and library contents; mark complete work, excerpt, selection, genre, and context item",
    "packet_ids" => "E016",
    "extraction_status" => "ready_public_toc",
    "notes" => "Major traditional Chinese literature anthology layer"
  },
  {
    "source_id" => "columbia_modern_chinese_lit_2e_2007",
    "source_title" => "The Columbia Anthology of Modern Chinese Literature",
    "source_type" => "field_anthology",
    "source_scope" => "Modern Chinese literature in translation from China, Taiwan, Hong Kong, and early twenty-first-century extensions",
    "source_date" => "2007",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/the-columbia-anthology-of-modern-chinese-literature/9780231138406/ ; Google Books: https://books.google.com/books?id=DRt84_yIsrAC",
    "edition" => "2nd ed.",
    "editors_or_authors" => "Joseph S. M. Lau; Howard Goldblatt",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Selection anthology; fiction, poetry, and essays dominate; complete-work support must be verified item by item",
    "extraction_method" => "Use publisher metadata plus public TOC previews; extract author, title, genre, period section, and region where available",
    "packet_ids" => "E016",
    "extraction_status" => "ready_public_toc",
    "notes" => "Major modern Chinese literature anthology layer"
  },
  {
    "source_id" => "cambridge_history_chinese_lit_2010",
    "source_title" => "The Cambridge History of Chinese Literature",
    "source_type" => "language_literary_history",
    "source_scope" => "Scholarly history of Chinese literature from early periods through modernity",
    "source_date" => "2010",
    "source_citation" => "Cambridge Core listing: https://www.cambridge.org/core/books/cambridge-history-of-chinese-literature/6FEBDC1995B8D05749A1F453D7577D21/listing",
    "edition" => "Vols. 1-2",
    "editors_or_authors" => "Kang-i Sun Chang; Stephen Owen",
    "publisher" => "Cambridge University Press",
    "coverage_limits" => "Chapter-level and partly gated; reference/context evidence, not a selection anthology",
    "extraction_method" => "Extract public chapter metadata and accessible summaries; use for work, period, and boundary context and corroboration",
    "packet_ids" => "E016",
    "extraction_status" => "ready_partial_public",
    "notes" => "Chinese literary-history authority layer"
  },
  {
    "source_id" => "chinese_text_project_premodern",
    "source_title" => "Chinese Text Project",
    "source_type" => "digital_text_collection",
    "source_scope" => "Open digital library/index of premodern Chinese texts, including Pre-Qin/Han and Post-Han corpora",
    "source_date" => "ongoing",
    "source_citation" => "Chinese Text Project: https://ctext.org/",
    "edition" => "online digital collection",
    "editors_or_authors" => "Chinese Text Project",
    "publisher" => "Chinese Text Project",
    "coverage_limits" => "Not a canon list; includes philosophical, historical, technical, and nonliterary texts; variable source provenance",
    "extraction_method" => "Parse public tables of contents or API where available; use for title authority, aliases, text access, and corpus presence",
    "packet_ids" => "E016",
    "extraction_status" => "public_index_ready",
    "notes" => "Premodern Chinese title authority and access layer"
  },
  {
    "source_id" => "e017_columbia_traditional_japanese_lit_2007",
    "source_title" => "Traditional Japanese Literature: An Anthology, Beginnings to 1600",
    "source_type" => "field_anthology",
    "source_scope" => "Japanese literature from earliest writing through Muromachi; poetry, prose, drama, setsuwa, criticism",
    "source_date" => "2007",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/traditional-japanese-literature/9780231136969/ ; Google Books: https://books.google.com/books/about/Traditional_Japanese_Literature.html?id=KmWCAAAAIAAJ",
    "edition" => "Translations from the Asian Classics; hardcover 2007/paperback 2008",
    "editors_or_authors" => "Haruo Shirane",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "English-translation anthology; official page has period-level TOC, Google Books has partial item TOC; selections/excerpts need item-scope coding",
    "extraction_method" => "Extract official period and genre headings plus Google Books partial items; mark complete, excerpt, or selection",
    "packet_ids" => "E017",
    "extraction_status" => "ready_partial_public",
    "notes" => "Traditional Japanese literature anthology layer"
  },
  {
    "source_id" => "e017_columbia_early_modern_japanese_lit_2002",
    "source_title" => "Early Modern Japanese Literature: An Anthology, 1600-1900",
    "source_type" => "field_anthology",
    "source_scope" => "Edo/Tokugawa through early Meiji; fiction, poetry, drama, essays, treatises, criticism, and popular genres",
    "source_date" => "2002",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/early-modern-japanese-literature/9780231109901/ ; Google Books: https://books.google.com/books/about/Early_Modern_Japanese_Literature.html?id=jAf9aqjnnGMC",
    "edition" => "Translations from the Asian Classics; hardcover 2002/paperback 2004",
    "editors_or_authors" => "Haruo Shirane",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Public TOC is mostly chapter/genre-level; many contained works are excerpts/selections",
    "extraction_method" => "Extract chapter TOC and public partial contents; match Saikaku, Basho, Chikamatsu, Bakin, kabuki, yomihon, and haikai rows separately",
    "packet_ids" => "E017",
    "extraction_status" => "ready_partial_public",
    "notes" => "Early modern Japanese literature anthology layer"
  },
  {
    "source_id" => "e017_columbia_modern_japanese_lit_v1_2005",
    "source_title" => "The Columbia Anthology of Modern Japanese Literature, Volume 1: From Restoration to Occupation, 1868-1945",
    "source_type" => "field_anthology",
    "source_scope" => "Meiji through wartime modern Japanese literature; fiction, poetry, drama, essays",
    "source_date" => "2005",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/the-columbia-anthology-of-modern-japanese-literature/9780231118606/",
    "edition" => "Modern Asian Literature Series; hardcover 2005/paperback 2007",
    "editors_or_authors" => "J. Thomas Rimer; Van C. Gessel",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Covers anthology selections, not necessarily complete works; romanization normalization needed",
    "extraction_method" => "Extract official line-item contents; classify work, selection, or excerpt and match author-title pairs",
    "packet_ids" => "E017",
    "extraction_status" => "ready_public_toc",
    "notes" => "Modern Japanese literature anthology layer through 1945"
  },
  {
    "source_id" => "e017_columbia_modern_japanese_lit_v2_2007",
    "source_title" => "The Columbia Anthology of Modern Japanese Literature, Volume 2: 1945 to the Present",
    "source_type" => "field_anthology",
    "source_scope" => "Postwar to early twenty-first-century Japanese literature; fiction, poetry, drama, essays",
    "source_date" => "2007",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/the-columbia-anthology-of-modern-japanese-literature/9780231138048/ ; Google Books: https://books.google.com/books/about/The_Columbia_Anthology_of_Modern_Japanes.html?id=BAg9tUJR1aEC",
    "edition" => "Modern Asian Literature Series; hardcover",
    "editors_or_authors" => "J. Thomas Rimer",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Official page is metadata-rich but not full line-item TOC; Google Books TOC is partial; copyrighted text unavailable",
    "extraction_method" => "Extract official named examples plus Google Books TOC; flag missing denominator pending physical or ebook TOC",
    "packet_ids" => "E017",
    "extraction_status" => "ready_partial_public",
    "notes" => "Modern Japanese literature anthology layer after 1945"
  },
  {
    "source_id" => "e018_columbia_traditional_korean_poetry_2003",
    "source_title" => "The Columbia Anthology of Traditional Korean Poetry",
    "source_type" => "field_anthology",
    "source_scope" => "Traditional Korean poetry: hyangga, Koryo songs, Songs of Flying Dragons, sijo, kasa, Chinese-language poetry, folk and shamanist songs",
    "source_date" => "2003",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/the-columbia-anthology-of-traditional-korean-poetry/9780231111133/",
    "edition" => "Translations from the Asian Classics",
    "editors_or_authors" => "Peter H. Lee",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Poetry-only; official contents are genre-level, not poem-level; no prose/pansori fiction coverage",
    "extraction_method" => "Extract genre, author, and index anchors; match named poem cycles and poet selections conservatively",
    "packet_ids" => "E018",
    "extraction_status" => "ready_partial_public",
    "notes" => "Traditional Korean poetry anthology layer"
  },
  {
    "source_id" => "e018_columbia_premodern_korean_prose_2018",
    "source_title" => "Premodern Korean Literary Prose: An Anthology",
    "source_type" => "field_anthology",
    "source_scope" => "Korean prose from tenth to nineteenth century; Silla, Koryo, and Choson prose, short fiction, long fiction, unofficial histories, diaries, oral narratives, and novellas",
    "source_date" => "2018",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/premodern-korean-literary-prose/9780231165808/",
    "edition" => "Translations from the Asian Classics",
    "editors_or_authors" => "Michael J. Pettid; Gregory N. Evon; Chan Park",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Anthology selections; not comprehensive for pansori cycle works; item scope varies by excerpt or complete text",
    "extraction_method" => "Extract official line-item TOC; match original titles, translated titles, translators, and excerpt status",
    "packet_ids" => "E018",
    "extraction_status" => "ready_public_toc",
    "notes" => "Premodern Korean prose anthology layer"
  },
  {
    "source_id" => "e018_columbia_modern_korean_fiction_2005",
    "source_title" => "Modern Korean Fiction: An Anthology",
    "source_type" => "field_anthology",
    "source_scope" => "Twentieth-century Korean fiction across colonial, division, North/South, women writers, and postwar modern fiction",
    "source_date" => "2005",
    "source_citation" => "Columbia University Press: https://cup.columbia.edu/book/modern-korean-fiction/9780231135139/",
    "edition" => "Modern Asian Literature Series",
    "editors_or_authors" => "Bruce Fulton; Youngmin Kwon",
    "publisher" => "Columbia University Press",
    "coverage_limits" => "Short-fiction anthology; weak for novels and post-2005 contemporary works",
    "extraction_method" => "Extract official 22-item TOC; match story-level items and author-title variants",
    "packet_ids" => "E018",
    "extraction_status" => "ready_public_toc",
    "notes" => "Modern Korean fiction anthology layer"
  },
  {
    "source_id" => "e018_lti_korea_digital_library_classics",
    "source_title" => "LTI Korea Digital Library of Korean Literature / LTIKOREA Classic Sourcebook",
    "source_type" => "digital_text_collection",
    "source_scope" => "Korean literature in translation; public catalog, writer metadata, e-books, and 26 representative classical works including Chunhyangjeon",
    "source_date" => "2007-ongoing; API registered 2022-11-25, edited 2026-01-07",
    "source_citation" => "LTI Korea library: https://library.ltikorea.or.kr/about/aboutLibrary?tab=operation ; OpenAPI: https://www.data.go.kr/en/data/15108417/openapi.do ; Classic Sourcebook example: https://library.ltikorea.or.kr/translatedbooks/22459",
    "edition" => "online",
    "editors_or_authors" => "Literature Translation Institute of Korea",
    "publisher" => "LTI Korea",
    "coverage_limits" => "Not a canon-selection source by itself; metadata/access layer; catalog coverage follows translated availability",
    "extraction_method" => "Use public catalog/API records for original title, romanization, author, translation, language, and access metadata; do not score as anthology inclusion",
    "packet_ids" => "E018",
    "extraction_status" => "public_index_ready",
    "notes" => "Korean literature metadata and public access layer"
  }
]

existing = read_registry(REGISTRY_FILE)
by_id = existing.to_h { |row| [row["source_id"], row] }
new_rows.each { |row| by_id[row["source_id"]] = row }
write_registry(REGISTRY_FILE, by_id.values)

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_crosswalk_batch_e013_e018_registered"
manifest["artifacts"]["source_registry"] = "e001_e018_registered_source_items_pending"
manifest["source_crosswalk_batch_e013_e018"] = {
  "source_registry_rows_added_or_updated" => new_rows.size,
  "e013_status" => "registered_needs_latin_american_toc_extraction",
  "e014_status" => "registered_needs_african_literature_toc_extraction",
  "e015_status" => "registered_needs_south_asian_metadata_and_toc_extraction",
  "e016_status" => "registered_needs_chinese_toc_and_metadata_extraction",
  "e017_status" => "registered_needs_japanese_toc_extraction",
  "e018_status" => "registered_needs_korean_toc_and_metadata_extraction",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_registry_rows"] = by_id.size
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "registered or updated #{new_rows.size} E013-E018 source layers"
