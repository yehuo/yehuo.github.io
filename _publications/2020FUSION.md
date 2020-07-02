---
title: "Track-Before-Detect Labeled Multi-Bernoulli Smoothing for Multiple Extended Objects"
collection: publications
permalink: /publications/2020FUSION
date: 2020-07-09
venue: 'IEEE 23rd International Conference on Information Fusion'
;paperurl: 'https://doi.org/10.1080/0951192X.2019.1636406'
---

## Abstract
For the evaluation of autonomous driving systems, this paper provides a new approach of generating reference data for multiple extended object tracking. In our approach, we apply a forward-backward smoother for objects with star-convex shapes based on the Labeled Multi-Bernoulli (LMB) Random Finite Set (RFS) and recursive Gaussian processes. We further propose to combine a robust birth policy with a backward filter to solve the conflict between robustness and completeness of tracking. Thereby, cluster candidates are evaluated based on a quality measure to only initialize objects from more reliable clusters in the forward pass. Missing states will then be recovered by the backward filter through post-processing the unassociated data after the smoothing process. Simulations and real-world experiments demonstrate superior performance of the proposed method in both cardinality and individual state estimation compared to naive LMB filter and smoother for extended objects.

;## Bibtex
;'''
;@article{yu2020track,
;	author = {Boqian Yu and Egon Ye},
;	title = {Track-Before-Detect Labeled Multi-Bernoulli Smoothing for Multiple Extended Objects},
;	journal = {International Journal of Computer Integrated Manufacturing},
;	volume = {32},
;	number = {8},
;	pages = {739-749},
;	year  = {2019},
;	publisher = {Taylor & Francis},
;	doi = {10.1080/0951192X.2019.1636406}
;}
;'''