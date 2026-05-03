#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "yaml"

ROOT = File.expand_path("..", __dir__)
BUILD_DIR = File.join(ROOT, "_planning", "canon_build")
TABLE_DIR = File.join(BUILD_DIR, "tables")
SOURCE_ITEMS_FILE = File.join(TABLE_DIR, "canon_source_items.tsv")
SOURCE_REGISTRY_FILE = File.join(TABLE_DIR, "canon_source_registry.tsv")
MANIFEST_FILE = File.join(BUILD_DIR, "manifests", "canon_build_manifest.yml")

SOURCE_ITEM_HEADERS = %w[
  source_id source_item_id raw_title raw_creator raw_date source_rank source_section source_url source_citation
  matched_work_id match_method match_confidence evidence_type evidence_weight supports match_status notes
].freeze

SOURCE_REGISTRY_HEADERS = %w[
  source_id source_title source_type source_scope source_date source_citation edition editors_or_authors
  publisher coverage_limits extraction_method packet_ids extraction_status notes
].freeze

SOURCE_PREFIXES = {
  "e013_oxford_latin_american_short_stories_1997" => "e013_oblass",
  "e013_oxford_latin_american_poetry_2009" => "e013_oblap",
  "e013_fsg_20c_latin_american_poetry_2011" => "e013_fsg20c",
  "columbia_modern_chinese_lit_2e_2007" => "e016_cmcl2e_2007",
  "columbia_traditional_chinese_lit_1996" => "e016_ctcl1996",
  "e017_columbia_modern_japanese_lit_v1_2005" => "e017_modjp_v1"
}.freeze

URLS = {
  "e013_oxford_latin_american_short_stories_1997" => "https://library.cca.edu/cgi-bin/koha/opac-ISBDdetail.pl?biblionumber=32656",
  "e013_oxford_latin_american_poetry_2009" => "https://find.uoc.ac.in/Record/308884/TOC",
  "e013_fsg_20c_latin_american_poetry_2011" => "https://boulder.marmot.org/GroupedWork/07e23042-8c1d-b5bd-5f7c-81eebfe68805/Home",
  "columbia_modern_chinese_lit_2e_2007" => "https://search.worldcat.org/nl/title/The-Columbia-anthology-of-modern-Chinese-literature/oclc/634959501",
  "columbia_traditional_chinese_lit_1996" => "https://search.cpl.org/Record/a207337",
  "e017_columbia_modern_japanese_lit_v1_2005" => "https://cup.columbia.edu/book/the-columbia-anthology-of-modern-japanese-literature/9780231118606/"
}.freeze

CITATIONS = {
  "e013_oxford_latin_american_short_stories_1997" => "CCA Libraries ISBD public TOC; Google Books bibliographic metadata",
  "e013_oxford_latin_american_poetry_2009" => "University of Calicut public TOC; Google Books bibliographic metadata",
  "e013_fsg_20c_latin_american_poetry_2011" => "Boulder Public Library public TOC; Macmillan/FSG bibliographic metadata",
  "columbia_modern_chinese_lit_2e_2007" => "WorldCat public contents; CUP and Google Books metadata cross-check",
  "columbia_traditional_chinese_lit_1996" => "Cleveland Public Library public contents; CUP and Google Books metadata cross-check",
  "e017_columbia_modern_japanese_lit_v1_2005" => "Columbia UP official product Contents, Volume 1"
}.freeze

def read_tsv(path)
  CSV.read(path, headers: true, col_sep: "\t").map(&:to_h)
end

def write_tsv(path, headers, rows, sort_key:)
  CSV.open(path, "w", col_sep: "\t", write_headers: true, headers: headers) do |csv|
    rows.sort_by { |row| row[sort_key].to_s }.each do |row|
      csv << headers.map { |header| row[header].to_s }
    end
  end
end

def stable_id(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
end

def source_item_id(source_id, index, title, creator)
  prefix = SOURCE_PREFIXES.fetch(source_id)
  slug = stable_id([creator, title].reject(&:empty?).join(" "))[0, 64]
  "#{prefix}_#{index.to_s.rjust(3, "0")}_#{slug}"
end

def item(source_id:, index:, raw_title:, raw_creator: "", raw_date: "", source_rank: nil, source_section: "",
         evidence_type:, supports:, match_status:, matched_work_id: "", match_method: "",
         match_confidence: "", evidence_weight: "0.60", notes: "")
  {
    "source_id" => source_id,
    "source_item_id" => source_item_id(source_id, index, raw_title, raw_creator),
    "raw_title" => raw_title,
    "raw_creator" => raw_creator,
    "raw_date" => raw_date,
    "source_rank" => (source_rank || index).to_s,
    "source_section" => source_section,
    "source_url" => URLS.fetch(source_id),
    "source_citation" => CITATIONS.fetch(source_id),
    "matched_work_id" => matched_work_id,
    "match_method" => match_method,
    "match_confidence" => match_confidence,
    "evidence_type" => evidence_type,
    "evidence_weight" => evidence_weight,
    "supports" => supports,
    "match_status" => match_status,
    "notes" => notes
  }
end

rows = []

latin_short_stories = [
  ["How the men were parted from the women", "Fray Ramon Pane", "The colonial period"],
  ["A maiden's story", "Popol Vuh", "The colonial period"],
  ["Tocay Capac, the first Inca", "Felipe Guaman Poma de Ayala", "The colonial period"],
  ["Plague of ants", "Fray Bartolome de las Casas", "The colonial period"],
  ["The story of Pedro Serrano", "Garcilaso de la Vega, el Inca", "The colonial period"],
  ["The adventurer who pretended that he was a bishop", "Gaspar de Villarroel", "The colonial period"],
  ["Amorous and military adventures", "Catalina de Erauso", "The colonial period"],
  ["A deal with Juana Garcia", "Juan Rodriguez Freyle", "The colonial period"],
  ["The slaughter house", "Esteban Echeverria", "New nations"],
  ["The tiger of the plains", "Domingo Faustino Sarmiento", "New nations"],
  ["He who listens may hear, to his regret: confidence of a confidence", "Juana Manuela Gorriti", "New nations"],
  ["Fray Gomez's scorpion", "Ricardo Palma", "New nations"],
  ["Where and how the devil lost his poncho", "Ricardo Palma", "New nations"],
  ["Midnight Mass", "Joaquim Maria Machado de Assis", "New nations"],
  ["The death of the Empress of China", "Ruben Dario", "The contemporary period"],
  ["Yzur", "Leopoldo Lugones", "The contemporary period"],
  ["The decapitated chicken", "Horacio Quiroga", "The contemporary period"],
  ["The baby in pink buckram", "Joao do Rio (Paulo Barreto)", "The contemporary period"],
  ["The man who resembled a horse", "Rafael Arevalo Martinez", "The contemporary period"],
  ["The braider", "Ricardo Guiraldes", "The contemporary period"],
  ["The man who knew Javanese", "Alfonso Henriques de Lima Barreto", "The contemporary period"],
  ["Peace on high", "Romulo Gallegos", "The contemporary period"],
  ["The Christmas turkey", "Mario de Andrade", "The contemporary period"],
  ["The daisy dolls", "Felisberto Hernandez", "The contemporary period"],
  ["The photograph", "Enrique Amorim", "The contemporary period"],
  ["The clearing", "Luisa Mercedes Levinson", "The contemporary period"],
  ["The garden of forking paths", "Jorge Luis Borges", "The contemporary period"],
  ["Journey back to the source", "Alejo Carpentier", "The contemporary period"],
  ["The tree", "Maria Luisa Bombal", "The contemporary period"],
  ["The legend of \"El Cadejo\"", "Miguel Angel Asturias", "The contemporary period"],
  ["Encarnacion Mendoza's Christmas Eve", "Juan Bosch", "The contemporary period"],
  ["The third bank of the river", "Joao Guimaraes Rosa", "The contemporary period"],
  ["The image of misfortune", "Juan Carlos Onetti", "The contemporary period"],
  ["Tell them not to kill me!", "Juan Rulfo", "The contemporary period"],
  ["Hahn's pentagon", "Osman Lins", "The contemporary period"],
  ["The switchman", "Juan Jose Arreola", "The contemporary period"],
  ["The featherless buzzards", "Julio Ramon Ribeyro", "The contemporary period"],
  ["Meat", "Virgilio Pinera", "The contemporary period"],
  ["Unborn", "Augusto Roa Bastos", "The contemporary period"],
  ["The night face up", "Julio Cortazar", "The contemporary period"],
  ["Cooking lesson", "Rosario Castellanos", "The contemporary period"],
  ["The doll queen", "Carlos Fuentes", "The contemporary period"],
  ["The walk", "Jose Donoso", "The contemporary period"],
  ["Balthazar's marvelous afternoon", "Gabriel Garcia Marquez", "The contemporary period"],
  ["The challenge", "Mario Vargas Llosa", "The contemporary period"],
  ["The crime of the mathematics professor", "Clarice Lispector", "The contemporary period"],
  ["Buried statues", "Antonio Benitez Rojo", "The contemporary period"],
  ["A woman's back", "Jose Balza", "The contemporary period"],
  ["The warmth of things", "Nelida Pinon", "The contemporary period"],
  ["Penelope", "Dalton Trevisan", "The contemporary period"],
  ["The threshold", "Cristina Peri Rossi", "The contemporary period"],
  ["The parade ends", "Reinaldo Arenas", "The contemporary period"],
  ["When women love men", "Rosario Ferre", "The contemporary period"]
]

latin_short_stories.each.with_index(1) do |(title, creator, section), index|
  match = {}
  if index == 27
    match = {
      evidence_type: "representative_selection",
      match_status: "represented_by_selection",
      matched_work_id: "work_canon_ficciones",
      match_method: "local_alias_story_to_collection",
      match_confidence: "0.95",
      notes: "Matched because aliases list The Garden of Forking Paths under Ficciones; story-level anthology evidence only."
    }
  end
  rows << item({
    source_id: "e013_oxford_latin_american_short_stories_1997",
    index: index,
    raw_title: title,
    raw_creator: creator,
    source_section: section,
    evidence_type: match[:evidence_type] || "inclusion",
    supports: "field_anthology_public_toc",
    match_status: match[:match_status] || "unmatched",
    matched_work_id: match[:matched_work_id] || "",
    match_method: match[:match_method] || "",
    match_confidence: match[:match_confidence] || "",
    notes: match[:notes] || (index == 1 ? "Complete 53/53 story rows drafted from CCA public TOC; Google Books metadata states anthology contains 53 stories." : "")
  })
end

oxford_poetry = [
  ["Maya scribes; And all was destroyed (excerpt); Codex Cantares Mexicanos (excerpt); The Florentine Codex (excerpt); Inca Khipu", "Anonymous", {}],
  ["Beautiful maiden", "Inca Garcilaso de la Vega", {}],
  ["Popol Vuh (excerpt)", "Anonymous", { matched_work_id: "work_canon_popol_vuh", match_method: "title_excerpt_current_path", match_confidence: "0.97" }],
  ["The Araucaniad (excerpt)", "Alonso de Ercilla y Zuniga", { matched_work_id: "work_candidate_global_lit_la_araucana", match_method: "english_title_variant_excerpt_creator", match_confidence: "0.94" }],
  ["The Mestizo's ballade", "Mateo Rosas de Oquendo", {}],
  ["Cachiuia; Festival of the Inca; Principal accountant and treasurer; Priests who force the Indians to weave cloth", "Felipe Guaman Poma de Ayala", {}],
  ["Define your city; An anatomy of the ailments suffered by the body of the republic; To the city of Bahia; To the Palefaces of Bahia; Upon finding an arm taken from the statue of the Christ Child", "Gregorio de Matos", {}],
  ["First dream (excerpt); This coloured counterfeit that thou beholdest; Tarry, shadow of my scornful treasure; Diuturnal infirmity of hope; Villancico VIII (excerpt)", "Sor Juana Ines de la Cruz", {}],
  ["The book of Chilam Balam of Chumayel (excerpt); The book of Chilam Balam of Mani (excerpt); Grant Don Juan V life; Eight-line acrostic", "Anonymous", {}],
  ["Social virtues and illuminations", "Simon Rodriguez", {}],
  ["Atahualpa death prayer", "Anonymous", {}],
  ["New patriotic dialogue", "Bartolome Hidalgo", {}],
  ["To the most holy Virgin Mary; Multiform salve (excerpt); Alphabetical-numerical prophecy", "Francisco Acuna de Figueroa", {}],
  ["The slippery one", "Hilario Ascasubi", {}],
  ["Song of exile", "Antonio Goncalves Dias", {}]
]

oxford_poetry.each.with_index(1) do |(title, creator, match), index|
  rows << item({
    source_id: "e013_oxford_latin_american_poetry_2009",
    index: index,
    raw_title: title,
    raw_creator: creator,
    source_section: "Table of Contents",
    evidence_type: "representative_selection",
    supports: "poem_level_anthology_inclusion",
    match_status: match[:matched_work_id] ? "represented_by_selection" : "unmatched",
    matched_work_id: match[:matched_work_id] || "",
    match_method: match[:match_method] || "",
    match_confidence: match[:match_confidence] || "",
    notes: index == 1 ? "Partial draft: first 15/135 University of Calicut public-TOC selection groups; grouped semicolon-delimited titles retained at source grouping level." : ""
  })
end

fsg_poetry = [
  ["de Versos sencillos: from simple verses; Amor de ciudad grande: love in the big city; Dos patrias: two homelands", "Jose Marti"],
  ["Un poema: a poem", "Jose Asuncion Silva"],
  ["A Roosevelt: to Roosevelt; Sonatine: sonatina; Ama tu ritmo: love your rhythm; Lo fatal: lo fatal", "Ruben Dario"],
  ["El alba: the dawn", "Ricardo Jaimes Freire"],
  ["Y tu esperando: and thou, expectant", "Amado Nervo"],
  ["Tuercele el cuello al cisne: wring the swan's neck", "Enrique Gonzalez Martinez"],
  ["Historia de mi muerte: story of my death", "Leopoldo Lugones"],
  ["El regreso: the return", "Julio Herrera y Reissig"],
  ["Blason: a manifesto", "Jose Santos Chocano"],
  ["Fiera de amor", "Delmira Agustini"],
  ["La suave patria: sweet land", "Ramon Lopez Velarde"],
  ["La ola del sueno: the sleep-wave; La medianoche: the midnight; La flor del aire: airflower; Una palabra: a word; La otra: the other woman", "Gabriela Mistral"],
  ["Yerbas de tarahumara: Tarahumara herbs", "Alfonso Reyes"],
  ["Biblioteca nacional: national library; Reclame: advertisement; Procissao de enterro: funeral procession", "Oswald de Andrade"],
  ["Cuadrados y angulos: squares and angles; hombre pequenito: very little man", "Alfonsina Storni"]
]

fsg_poetry.each.with_index(1) do |(title, creator), index|
  rows << item({
    source_id: "e013_fsg_20c_latin_american_poetry_2011",
    index: index,
    raw_title: title,
    raw_creator: creator,
    source_section: "From the Book - 1st ed.",
    evidence_type: "representative_selection",
    supports: "poem_level_anthology_inclusion",
    match_status: "unmatched",
    notes: index == 1 ? "Partial draft: first 15/84 Boulder public-TOC author-entry rows; grouped bilingual title strings retained at source grouping level." : ""
  })
end

modern_chinese = [
  ["Preface to the First Collection of Short Stories, Call to Arms", "Lu Xun", "1.1", "Fiction, 1918-1949", "representative_selection", "represented_by_selection", "work_candidate_global_lit_call_to_arms_lu_xun", "title_creator_collection_basis", "0.90", "Partial draft: 14 rows emitted from 166 counted public modern contents entries; row is preface/selection, not complete collection proof."],
  ["A Madman's Diary", "Lu Xun", "1.2", "Fiction, 1918-1949", "representative_selection", "represented_by_selection", "work_candidate_global_lit_call_to_arms_lu_xun", "local_alias_title_creator", "0.92", "Local alias maps A Madman's Diary to Call to Arms by Lu Xun; selection-level support only."],
  ["Kong Yiji", "Lu Xun", "1.3", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", "Possible Call to Arms contained-work relation requires review."],
  ["A Posthumous Son", "Ye Shaojun", "1.4", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["Sinking", "Yu Dafu", "1.5", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["Spring Silkworms", "Mao Dun", "1.6", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["An Old and Established Name", "Lao She", "1.7", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["Xiaoxiao", "Shen Congwen", "1.8", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["The Night of Midautumn Festival", "Ling Shuhua", "1.9", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["Dog", "Ba Jin", "1.10", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["Sealed Off", "Zhang Ailing", "1.11", "Fiction, 1918-1949", "inclusion", "unmatched", "", "", "", ""],
  ["Excerpts from Wild Grass", "Lu Xun", "8.1", "Essays, 1918-1949", "representative_selection", "represented_by_selection", "work_candidate_eastasia_lit_wild_grass", "title_creator_collection_selection", "0.95", "Exact local current-path candidate Wild Grass by Lu Xun; source lists excerpts."],
  ["On the Road at Eighteen", "Yu Hua", "3.18", "Fiction since 1976", "inclusion", "unmatched", "", "", "", "Local Yu Hua candidates are novels, not this story."],
  ["Iron Child", "Mo Yan", "3.13", "Fiction since 1976", "inclusion", "unmatched", "", "", "", "Local Mo Yan candidates are novels, not this story."]
]

modern_chinese.each.with_index(1) do |(title, creator, rank, section, evidence_type, status, work_id, method, confidence, notes), index|
  rows << item({
    source_id: "columbia_modern_chinese_lit_2e_2007",
    index: index,
    raw_title: title,
    raw_creator: creator,
    source_rank: rank,
    source_section: section,
    evidence_type: evidence_type,
    supports: "field_anthology_public_toc",
    match_status: status,
    matched_work_id: work_id,
    match_method: method,
    match_confidence: confidence,
    notes: notes
  })
end

traditional_chinese = [
  ["Confucian Analects, Book 2", "Anonymous", "1.7", "Foundations and interpretations > Philosophy, thought, and religion", "representative_selection", "represented_by_selection", "work_canon_analects", "title_selection_to_current_path", "0.95", "Partial draft: 22 rows emitted from 278 reported selections; Book 2 selection only."],
  ["Fish and Bear's Paws; Bull Mountain", "Meng Ko", "1.8", "Foundations and interpretations > Philosophy, thought, and religion", "representative_selection", "represented_by_selection", "work_candidate_mandatory_mencius", "title_creator_selection_to_current_path", "0.93", ""],
  ["Chuang Tzu, Chapter 17 and other passages", "Chuang Chou", "1.9", "Foundations and interpretations > Philosophy, thought, and religion", "representative_selection", "represented_by_selection", "work_canon_zhuangzi", "romanized_title_creator_selection", "0.95", ""],
  ["The Classic Book of Integrity and the Way: Tao te ching", "Lao Tzu", "1.10", "Foundations and interpretations > Philosophy, thought, and religion", "representative_selection", "represented_by_selection", "work_canon_dao_de_jing", "title_alias_creator_basis", "0.95", ""],
  ["From Lotus Sutra, Chapter 3: Parable", "Kumarajiva (translator)", "1.13", "Foundations and interpretations > Philosophy, thought, and religion", "representative_selection", "represented_by_selection", "work_candidate_lotus_sutra", "title_chapter_selection_to_current_path", "0.90", ""],
  ["From Classic of Odes", "Anonymous", "2.1", "Verse > Classical poetry", "representative_selection", "represented_by_selection", "work_candidate_book_of_songs", "title_alias_to_current_path", "0.90", ""],
  ["Heavenly Questions", "Ch'u Yuan", "2.148", "Verse > Elegies and rhapsodies", "representative_selection", "represented_by_selection", "work_candidate_chu_ci", "poem_creator_to_chu_ci_collection", "0.85", ""],
  ["The Peach Blossom Spring", "T'ao Ch'ien", "3.204", "Prose > Discourses, essays, and sketches", "inclusion", "matched_current_path", "work_candidate_peach_blossom_spring", "title_creator_romanization_variant", "0.98", ""],
  ["Preface to and tales from Search for the Supernatural", "Kan Pao", "4.242", "Fiction > Tales of the strange", "representative_selection", "represented_by_selection", "work_candidate_soushen_ji", "title_creator_collection_selection", "0.95", ""],
  ["Strange Tales from Make-Do Studio", "P'u Sung-ling", "4.246", "Fiction > Tales of the strange", "representative_selection", "represented_by_selection", "work_candidate_strange_tales_liaozhai", "title_creator_variant_to_liaozhai", "0.86", ""],
  ["The Story of Ying-ying", "Yuan Chen", "4.252", "Fiction > Classical-language short stories", "inclusion", "matched_current_path", "work_candidate_scale_lit_yingying_biography", "title_creator_romanization_variant", "0.98", ""],
  ["Romance of the Three Kingdoms, chapters 45 and 46", "Anonymous", "4.258", "Fiction > Novels", "representative_selection", "represented_by_selection", "work_candidate_romance_three_kingdoms", "title_chapter_selection_creator_mismatch", "0.84", ""],
  ["The Journey to the West, chapter 7", "Wu Ch'eng-en", "4.259", "Fiction > Novels", "representative_selection", "represented_by_selection", "work_candidate_journey_to_the_west", "title_creator_chapter_selection", "0.96", ""],
  ["Gold Vase Plum, chapter 12", "Anonymous", "4.260", "Fiction > Novels", "representative_selection", "represented_by_selection", "work_candidate_jin_ping_mei", "title_alias_chapter_selection", "0.88", ""],
  ["Wu Sung fights the tiger, from Water Margin", "Anonymous, with commentary by Chin Sheng-t'an", "4.261", "Fiction > Novels", "representative_selection", "represented_by_selection", "work_candidate_water_margin", "title_selection_to_current_path", "0.88", ""],
  ["The Scholars, chapter 3", "Wu Ching-tzu", "4.262", "Fiction > Novels", "representative_selection", "represented_by_selection", "work_candidate_scholars_wu_jingzi", "title_creator_chapter_selection", "0.96", ""],
  ["From Dream of Red Towers: A Burial Mound for Flowers; One Smear Wang", "Ts'ao Hsueh-ch'in", "4.263", "Fiction > Novels", "representative_selection", "represented_by_selection", "work_canon_dream_of_the_red_chamber", "title_creator_variant_selection", "0.92", ""],
  ["Master Tung's Western Chamber Romance, chapter 2", "Tung Chieh-yuan", "5.269", "Oral and performing arts > Prosimetric storytelling", "representative_selection", "represented_by_selection", "work_candidate_romance_western_chamber", "title_alias_chapter_selection", "0.82", "Source is Master Tung version; relation review required."],
  ["Injustice to Tou O, act 3", "Kuan Han-ch'ing", "5.273", "Oral and performing arts > Drama", "representative_selection", "represented_by_selection", "work_candidate_global_lit_injustice_dou_e", "title_creator_romanization_variant_act_selection", "0.94", ""],
  ["The Peony Pavilion, scene 7", "T'ang Hsien-tsu", "5.276", "Oral and performing arts > Drama", "representative_selection", "represented_by_selection", "work_candidate_peony_pavilion", "title_creator_romanization_variant_scene_selection", "0.96", ""],
  ["The Peach Blossom Fan", "K'ung Shang-jen", "5.277", "Oral and performing arts > Drama", "representative_selection", "represented_by_selection", "work_candidate_global_lit_peach_blossom_fan", "title_creator_romanization_variant", "0.95", "Treat as selection until source scope confirms complete play."],
  ["The Lute, scene 33", "Kao Ming", "5.274", "Oral and performing arts > Drama", "representative_selection", "unmatched", "", "", "", "No high-confidence local candidate found for The Lute/Pipa ji; scene selection."]
]

traditional_chinese.each.with_index(1) do |(title, creator, rank, section, evidence_type, status, work_id, method, confidence, notes), index|
  rows << item({
    source_id: "columbia_traditional_chinese_lit_1996",
    index: index,
    raw_title: title,
    raw_creator: creator,
    source_rank: rank,
    source_section: section,
    evidence_type: evidence_type,
    supports: "field_anthology_public_toc",
    match_status: status,
    matched_work_id: work_id,
    match_method: method,
    match_confidence: confidence,
    notes: notes
  })
end

japanese_groups = [
  ["1. First Experiments | Fiction", "Mori Ogai", ["The Dancing Girl"]],
  ["1. First Experiments | Fiction", "San'yutei Encho", ["The Ghost Tale of the Peony Lantern"]],
  ["1. First Experiments | Fiction", "Tokai Sanshi", ["Strange Encounters with Beautiful Women"]],
  ["1. First Experiments | Poetry", "", ["Spring Blossoms into Flower", "Butterflies"]],
  ["1. First Experiments | Poetry", "Yuasa Hangetsu", ["Twelve Stones"]],
  ["1. First Experiments | Poetry", "Ueki Emori", ["Liberty Song"]],
  ["1. First Experiments | Poetry", "Ochiai Naobumi", ["Song of the Faithful Daughter Shiragiku"]],
  ["1. First Experiments | Poetry", "Shimazaki Toson", ["The Fox's Trick", "First Love"]],
  ["1. First Experiments | Poetry", "Yosano Hiroshi", ["Victory Arches", "Withered Lotus"]],
  ["1. First Experiments | Poetry", "Takeshima Hagoromo", ["The Maiden Called Love"]],
  ["2. Beginnings | Fiction", "Futabatei Shimei", ["Drifting Clouds"]],
  ["2. Beginnings | Fiction", "Izumi Kyoka", ["The Holy Man of Mount Koya"]],
  ["2. Beginnings | Fiction", "Koda Rohan", ["The Icon of Liberty"]],
  ["2. Beginnings | Fiction", "Kunikida Doppo", ["Meat and Potatoes"]],
  ["2. Beginnings | Fiction", "Masamune Hakucho", ["The Clay Doll"]],
  ["2. Beginnings | Fiction", "Mori Ogai", ["The Boat on the River Takase"]],
  ["2. Beginnings | Fiction", "Nagai Kafu", ["The Mediterranean in Twilight"]],
  ["2. Beginnings | Fiction", "Ozaki Koyo", ["The Gold Demon"]],
  ["2. Beginnings | Fiction", "Shimazaki Toson", ["The Life of a Certain Woman"]],
  ["2. Beginnings | Fiction", "Tayama Katai", ["The Girl Watcher"]],
  ["2. Beginnings | Fiction", "Tokuda Shusei", ["The Town's Dance Hall"]],
  ["2. Beginnings | Fiction", "Tokutomi Roka", ["Ashes"]],
  ["2. Beginnings | Poetry in the International Style", "Kodama Kagai", ["The Suicide of an Unemployed Person", "The Setting Sun"]],
  ["2. Beginnings | Poetry in the International Style", "Ishikawa Takuboku", ["Better than Crying", "Do Not Get Up", "A Spoonful of Cocoa", "After Endless Discussions"]],
  ["2. Beginnings | Poetry in the International Style", "Kawai Suimei", ["Snowflame", "Living Voice"]],
  ["2. Beginnings | Poetry in the International Style", "Kitahara Hakushu", ["Anesthesia of Red Flowers", "Spider Lilies", "Kiss"]],
  ["2. Beginnings | Poetry in the International Style", "Yamamura Bocho", ["Ecstasy", "Dance", "Mandala"]],
  ["2. Beginnings | Poetry in the International Style", "Takamura Kotaro", ["Bear Fur", "A Steak Platter"]],
  ["2. Beginnings | Poetry in the International Style", "Kinoshita Mokutaro", ["Nagasaki Style", "Gold Leaf Brandy"]],
  ["2. Beginnings | Poetry in the International Style", "Yosano Akiko", ["Beloved, You Must Not Die", "In the First Person", "A Certain Country", "From Paris on a Postcard", "The Heart of a Thirtyish Woman"]],
  ["2. Beginnings | Poetry in Traditional Forms", "Yosano Akiko", ["The Dancing Girl", "Spring Thaw"]],
  ["2. Beginnings | Essays", "Natsume Soseki", ["The Civilization of Modern-Day Japan", "My Individualism"]],
  ["2. Beginnings | Essays", "Yosano Akiko", ["An Open Letter"]],
  ["3. The Interwar Years | Fiction", "Akutagawa Ryunosuke", ["The Nose", "The Christ of Nanking"]],
  ["3. The Interwar Years | Fiction", "Arishima Takeo", ["The Clock that Does Not Move"]],
  ["3. The Interwar Years | Fiction", "Edogawa Ranpo", ["The Human Chair"]],
  ["3. The Interwar Years | Fiction", "Hori Tatsuo", ["The Wind Has Risen"]],
  ["3. The Interwar Years | Fiction", "Inagaki Taruho", ["One-Thousand-and-One-Second Stories"]],
  ["3. The Interwar Years | Fiction", "Ito Sei", ["A Department Store Called M"]],
  ["3. The Interwar Years | Fiction", "Kajii Motojiro", ["The Lemon"]],
  ["3. The Interwar Years | Fiction", "Kawabata Yasunari", ["The Dancing Girl of Izu"]],
  ["3. The Interwar Years | Fiction", "Kobayashi Takiji", ["The Fifteenth of March, 1928"]],
  ["3. The Interwar Years | Fiction", "Kuroshima Denji", ["A Flock of Circling Crows"]],
  ["3. The Interwar Years | Fiction", "Miyamoto Yuriko", ["A Sunless Morning"]],
  ["3. The Interwar Years | Fiction", "Origuchi Shinobu", ["Writings from the Dead"]],
  ["3. The Interwar Years | Fiction", "Shiga Naoya", ["The Diary of Claudius", "The Paper Door", "The Shopboy's God"]],
  ["3. The Interwar Years | Fiction", "Takeda Rintaro", ["The Lot of Dire Misfortune"]],
  ["3. The Interwar Years | Fiction", "Tani Joji", ["The Shanghaied Man"]],
  ["3. The Interwar Years | Fiction", "Tanizaki Jun'ichiro", ["The Two Acolytes"]],
  ["3. The Interwar Years | Fiction", "Uno Koji", ["Landscape with Withered Tree"]],
  ["3. The Interwar Years | Fiction", "Yokomitsu Riichi", ["Mount Hiei"]],
  ["3. The Interwar Years | Poetry in the International Style", "Takamura Kotaro", ["Cathedral in the Thrashing Rain"]],
  ["3. The Interwar Years | Poetry in the International Style", "Hagiwara Sakutaro", ["On a Trip", "Bamboo", "Sickly Face at the Bottom of the Ground", "The One Who's in Love with Love", "The Army", "The Corpse of a Cat"]],
  ["3. The Interwar Years | Poetry in the International Style", "Miyazawa Kenji", ["Spring & Asura", "The Morning of the Last Farewell", "November 3rd"]],
  ["3. The Interwar Years | Poetry in the International Style", "Nishiwaki Junzaburo", ["Seven Poems from Ambarvalia", "No Traveler Returns"]],
  ["3. The Interwar Years | Poetry in the International Style", "Kitasono Katsue", ["Collection of White Poems", "Vin du masque", "Words", "Two Poems", "Almost Midwinter", "Kitasono's First Letter to Ezra Pound"]],
  ["3. The Interwar Years | Poetry in the International Style", "Nakano Shigeharu", ["Imperial Hotel", "Song", "Paul Claudel", "Train", "The Rate of Exchange"]],
  ["3. The Interwar Years | Drama", "Kishida Kunio", ["The Swing"]],
  ["3. The Interwar Years | Drama", "Tanizaki Jun'ichiro", ["Okuni and Gohei"]],
  ["3. The Interwar Years | Essays", "Kobayashi Hideo", ["Literature of the Lost Home"]],
  ["3. The Interwar Years | Essays", "Sato Haruo", ["Discourse on 'Elegance'"]],
  ["4. The War Years | Fiction", "Dazai Osamu", ["December 8th"]],
  ["4. The War Years | Fiction", "Ishikawa Tatsuzo", ["Soldiers Alive"]],
  ["4. The War Years | Fiction", "Kajiyama Toshiyuki", ["The Clan Records"]],
  ["4. The War Years | Fiction", "Nakajima Atsushi", ["The Ox Man"]],
  ["4. The War Years | Fiction", "Ooka Shohei", ["Taken Captive"]],
  ["4. The War Years | Fiction", "Ota Yoko", ["Fireflies"]],
  ["4. The War Years | Fiction", "Shimao Toshio", ["The Departure Never Came"]],
  ["4. The War Years | Fiction", "Uno Chiyo", ["A Wife's Letters"]],
  ["4. The War Years | Poetry in the International Style", "Takamura Kotaro", ["The Elephant's Piggy Bank", "The Final Battle for the Ryukyu Islands"]],
  ["4. The War Years | Poetry in the International Style", "Yoshida Issui", ["Swans"]],
  ["4. The War Years | Poetry in the International Style", "Kusano Shinpei", ["Mount Fuji"]],
  ["4. The War Years | Poetry in the International Style", "Oguma Hideo", ["Long, Long Autumn Nights"]],
  ["4. The War Years | Poetry in Traditional Forms", "Toki Zenmaro", ["Evidence"]],
  ["4. The War Years | Essays", "Hagiwara Sakutaro", ["Return to Japan"]],
  ["4. The War Years | Essays", "Kobayashi Hideo", ["On Impermanence", "Taima"]],
  ["4. The War Years | Essays", "Sakaguchi Ango", ["A Personal View of Japanese Culture"]]
]

japanese_index = 0
japanese_groups.each do |section, creator, titles|
  titles.each do |title|
    japanese_index += 1
    match = {}
    if japanese_index == 1
      match = {
        match_status: "matched_current_path",
        matched_work_id: "work_candidate_eastasia_lit_dancing_girl",
        match_method: "title_creator_exact_current_path",
        match_confidence: "0.99",
        notes: "Complete 119 explicit titled TOC rows from Columbia UP Contents; structural headings, form-only labels, and creator-only traditional-form listings omitted. Exact title+creator match to local current-path candidate."
      }
    elsif title == "The Dancing Girl" && creator == "Yosano Akiko"
      match = { notes: "Same English title as Mori Ogai story but creator context is Yosano Akiko; left unmatched." }
    end
    rows << item({
      source_id: "e017_columbia_modern_japanese_lit_v1_2005",
      index: japanese_index,
      raw_title: title,
      raw_creator: creator,
      source_section: section,
      evidence_type: "inclusion",
      supports: "anthology_public_toc",
      match_status: match[:match_status] || "unmatched",
      matched_work_id: match[:matched_work_id] || "",
      match_method: match[:match_method] || "",
      match_confidence: match[:match_confidence] || "",
      notes: match[:notes] || ""
    })
  end
end

raise "expected 238 X021 source items, got #{rows.size}" unless rows.size == 238

source_item_rows = read_tsv(SOURCE_ITEMS_FILE)
source_items_by_id = source_item_rows.to_h { |row| [row["source_item_id"], row] }
rows.each { |row| source_items_by_id[row["source_item_id"]] = row }
write_tsv(SOURCE_ITEMS_FILE, SOURCE_ITEM_HEADERS, source_items_by_id.values, sort_key: "source_item_id")

registry_rows = read_tsv(SOURCE_REGISTRY_FILE)
registry_by_id = registry_rows.to_h { |row| [row["source_id"], row] }
{
  "e013_oxford_latin_american_short_stories_1997" => ["extracted", "Complete 53-story public TOC ingested; matching/evidence generation pending."],
  "e013_oxford_latin_american_poetry_2009" => ["in_progress", "Partial 15-row public TOC pilot ingested from 135 grouped selection rows; full extraction pending."],
  "e013_fsg_20c_latin_american_poetry_2011" => ["in_progress", "Partial 15-row public TOC pilot ingested from 84 author-entry rows; full extraction pending."],
  "columbia_modern_chinese_lit_2e_2007" => ["in_progress", "Partial 14-row public TOC pilot ingested from 166 counted contents entries; full extraction pending."],
  "columbia_traditional_chinese_lit_1996" => ["in_progress", "Partial 22-row public TOC pilot ingested from 278 reported selections; full extraction pending."],
  "e017_columbia_modern_japanese_lit_v1_2005" => ["extracted", "Complete 119 explicit titled public TOC rows ingested; structural headings/form-only labels omitted."]
}.each do |source_id, (status, notes)|
  next unless registry_by_id[source_id]

  registry_by_id[source_id]["extraction_status"] = status
  registry_by_id[source_id]["notes"] = notes
end
write_tsv(SOURCE_REGISTRY_FILE, SOURCE_REGISTRY_HEADERS, registry_by_id.values, sort_key: "source_id")

manifest = YAML.load_file(MANIFEST_FILE)
manifest["status"] = "source_item_batch_x021_e013_e016_e017_ingested"
manifest["artifacts"]["source_items"] = "e001_ingested_x001_x006_pilot_x013_materialized_x020_x021_source_items"
manifest["source_item_extraction_batch_x021"] = {
  "source_items_added_or_updated" => rows.size,
  "sources_touched" => 6,
  "complete_public_toc_sources" => 2,
  "partial_public_toc_sources" => 4,
  "evidence_rows_added" => 0,
  "status" => "source_items_ingested_matching_required",
  "direct_replacements" => 0
}
manifest["current_counts"] ||= {}
manifest["current_counts"]["source_items"] = source_items_by_id.size
manifest["current_counts"]["source_items_matched_candidate"] = source_items_by_id.values.count { |row| row["match_status"] == "matched_candidate" }
manifest["current_counts"]["source_items_represented_by_selection"] = source_items_by_id.values.count { |row| row["match_status"] == "represented_by_selection" }
manifest["current_counts"]["source_items_out_of_scope"] = source_items_by_id.values.count { |row| row["match_status"] == "out_of_scope" }
manifest["current_counts"]["evidence_rows"] ||= 0
File.write(MANIFEST_FILE, manifest.to_yaml)

puts "ingested or updated #{rows.size} X021 E013/E016/E017 source-item rows"
