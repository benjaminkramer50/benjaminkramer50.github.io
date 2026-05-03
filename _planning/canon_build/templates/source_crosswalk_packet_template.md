# Source-Crosswalk Packet Template

Packet ID:

Packet Scope:

Extraction Denominator:

- complete:
- partial:
- metadata_only:
- context_only:
- blocked:
- sampled:
- unknown:

Source Class / Evidence Role:

- source_class:
- source_subclass:
- evidence_role:
- access_class:
- provenance_level:
- counts_for_canon_score: yes/no/pending

Source Registry Rows:

```tsv
source_id	source_title	source_type	source_scope	source_date	source_citation	edition	editors_or_authors	publisher	coverage_limits	extraction_method	packet_ids	extraction_status	notes
```

Source Item Rows:

```tsv
source_id	source_item_id	raw_title	raw_creator	raw_date	source_rank	source_section	source_url	source_citation	matched_work_id	match_method	match_confidence	evidence_type	evidence_weight	supports	match_status	notes
```

Item-Scope Rules:

- complete_work:
- substantial_selection:
- excerpt:
- poem_or_story:
- author_heading:
- context_material:
- edition_or_volume:
- corpus_witness:
- access_metadata:

Evidence Rows:

```tsv
evidence_id	work_id	source_id	source_item_id	evidence_type	evidence_strength	page_or_section	quote_or_note	packet_id	supports_tier	supports_boundary_policy_id	reviewer_status	notes
```

Coverage Summary:

- source_items_checked:
- matched_current_path:
- represented_by_selection:
- unmatched_source_items:
- duplicate_or_variant:
- out_of_scope:
- unresolved:

High-Confidence Gaps To Test:

- 

False Positives / Already Represented:

- 

Duplicate, Alias, Or Relation Repairs:

- 

Boundary Or Policy Issues:

- 

Access Limits:

- 

Coordinator Decision:

- status:
- next_action:
