---
layout: post
title: "What 200 Million Health Records Can Tell Us"
author: Benjamin Kramer
subtitle: Some thoughts on working with large-scale claims data.
tags: research
---

I work with a dataset of over 200 million de-identified patient records at UChicago, spanning years of diagnoses, procedures, and prescriptions. The goal of the work is to find structure in this data, with a particular focus on whether birth order is associated with health outcomes across the phenome. This is the project I have spent the most time on.

The scale is what makes it possible. A lot of epidemiological studies are underpowered for rare conditions or subtle effects. When you have nine figures of patients, you can start asking questions that would be unanswerable in a cohort of a few thousand. I find this to be one of the most interesting aspects of the work. However, scale also introduces its own problems. Artifacts in billing codes can look like biological signal. Administrative patterns can masquerade as disease clusters. I have found that you have to be constantly skeptical of your own results, which is harder in practice than it sounds when you have a finding that looks clean and statistically significant.

One thing I have noticed from this work is that the associations that surprised us the most were the ones that sent us back to the literature. More often than not, there was a biological mechanism we had not considered. This was useful as a validation of the approach, however it also meant that the results which confirmed our priors were less informative than the ones that did not.

I will write more about specific projects as they get closer to publication. Claims data is not as well known as genomics in computational biology, however I believe it is one of the most underutilized resources in biomedical research, and I think more people should be working with it.
