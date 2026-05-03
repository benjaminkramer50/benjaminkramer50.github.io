# X Batch 24 Report: X040 Source-Backed Candidate Triage

Date: 2026-05-03

Status: metadata and evidence-scope triage completed for the original 8 source-backed candidates; public canon unchanged.

## Summary

X040 cleans up the eight source-backed candidates that predate the X036 boundary-candidate materialization. The goal was to remove avoidable date/taxonomy noise, accept or limit the existing evidence rows, and make the remaining blockers specific.

| Metric | Count |
|---|---:|
| Work candidate rows updated | 8 |
| Source item evidence-scope rows updated | 3 |
| Evidence rows accepted | 8 |
| Candidates moved to insufficient independent support | 5 |
| Candidates kept as selection-only support | 2 |
| Candidate kept as non-scoring identity support only | 1 |
| Score-ready rows | 0 |

## Candidate Outcomes

| Work ID | Title | Evidence result | Remaining blocker |
|---|---|---|---|
| `work_candidate_source_broadview_hrotsvitha_abraham` | Abraham | Accepted as drama-anthology support | Needs additional independent support or waiver |
| `work_candidate_source_aap_harper_bury_me_free_land` | Bury Me in a Free Land | Accepted as poem-level anthology support | Needs additional independent support or waiver |
| `work_candidate_source_loa_brown_narrative` | Narrative of William W. Brown, A Fugitive Slave. Written by Himself | Accepted as authoritative collection support | Needs additional independent support or waiver |
| `work_candidate_source_loa_gronniosaw_narrative` | Narrative of James Albert Ukawsaw Gronniosaw | Accepted as authoritative collection support | Needs additional independent support or waiver |
| `work_candidate_source_loa_nat_turner_confessions` | The Confessions of Nat Turner | Accepted as authoritative collection support | Needs additional independent support or waiver |
| `work_candidate_source_naal_brooks_maud_martha` | Maud Martha | Accepted as anthology selection support only | Complete-novel support or selection policy needed |
| `work_candidate_source_naal_whitehead_nickel_boys` | The Nickel Boys | Accepted as anthology selection support only | Complete-novel support and recent-work corroboration needed |
| `work_candidate_source_philobiblon_curial_e_guelfa` | Curial e Guelfa | Accepted as non-scoring bibliographic identity support only | Canon-support source required |

## Metadata Cleanup

The eight rows now have non-placeholder date, region, language, literary-tradition, period, form, and unit-type fields. Date/sort-year blockers were removed for `Abraham` and `Bury Me in a Free Land`.

## Evidence-Scope Corrections

`Bury Me in a Free Land` was changed from `representative_selection` to `inclusion` because the source item is poem-level support and the poem is the work unit.

`Maud Martha` and `The Nickel Boys` were changed to `representative_selection` because the Norton African American Literature source is an anthology context with many excerpts/selections; those rows should discover candidates but not close complete-novel support.

## Verification Sources

- Hrotsvitha / `Abraham`: Project Gutenberg `The Plays of Roswitha` (`https://www.gutenberg.org/ebooks/59770`) and Encyclopedia.com Hrotsvit (`https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/hrotsvit`).
- `Bury Me in a Free Land`: New American History (`https://resources.newamericanhistory.org/bury-me-in-a-free-land`) and the Guardian (`https://www.theguardian.com/books/booksblog/2017/feb/27/poem-of-the-week-bury-me-in-a-free-land-by-frances-ew-harper`) note first publication in the Anti-Slavery Bugle in 1858.
- William Wells Brown narrative: Library of Congress (`https://www.loc.gov/resource/gdcmassbookdig.narrativeofwilli00lcbrow/`).
- Gronniosaw narrative: Yale Center for British Art (`https://interactive.britishart.yale.edu/slavery-and-portraiture/302/a-narrative-of-the-most-remarkable-particulars-in-the-life-of-james-albert-ukawsaw-gronniosaw-an-african-prince---written-by-himself`) notes first publication in Bath in 1772.
- `The Confessions of Nat Turner`: Britannica (`https://www.britannica.com/topic/The-Confessions-of-Nat-Turner-by-Gray`) and Encyclopedia Virginia (`https://encyclopediavirginia.org/entries/confessions-of-nat-turner-the-1831/`) summarize the 1831 Turner/Thomas R. Gray attribution context.
- `Maud Martha`: National Library of Australia catalog (`https://catalogue.nla.gov.au/catalog/357285`) and EBSCO (`https://www.ebsco.com/research-starters/literature-and-writing/maud-martha-gwendolyn-brooks`) list the 1953 novel.
- `The Nickel Boys`: Penguin Random House (`https://www.penguinrandomhouse.com/books/223161/the-nickel-boys-by-colson-whitehead/`) lists publication on July 16, 2019.
- `Curial e Guelfa`: Enciclopedia.cat (`https://www.enciclopedia.cat/gran-enciclopedia-catalana/curial-e-guelfa`) and Universitat de Valencia (`https://www.uv.es/uvweb/college/en/news-release/a-research-universitat-reveals-author-curial-e-guelfa-is-enyego-d-avalos-camerlengo-alfonso-magnanimous-1285846070123/Noticia.html?id=1285996888956`) support fifteenth-century Catalan chivalric-romance identity.

## Validation

`ruby scripts/canon_validate_build_layer.rb` passed after regenerating source debt, omission queue, and scoring inputs.

## Next Actions

1. Seek additional independent support for the five accepted single-source candidates.
2. Decide whether `Maud Martha` and `The Nickel Boys` should remain novel-level candidates or be recorded only as anthology-selection pressure.
3. Continue high-risk red-cell routing before any public-path replacement proposal.
