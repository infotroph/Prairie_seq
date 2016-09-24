
## Methods

### Experimental site

Our experimental site is the University of Illinois Energy Farm (Urbana, Illinois, USA: 40.06N, 88.19W, elevation 220 m), a bioenergy research facility founded to compare the ecological and economic impacts of perennial grasses against those of conventional row crops when both are grown as feedstocks for fuel production. Four cropping systems (Maize-soybean rotation, monocultures of *Miscanthus* $\x$ *giganteus* and *Panicum virgatum*, and the prairies decribed below) are grown side-by-side in a randomized complete-block design with five replicates: Four blocks of 0.7 Ha plots and a fifth block of 3.8 Ha plots that is instrumented for eddy-covariance measurements of carbon and water exchange balance. For this experiment we were interested in multispecies root communities and therefore sampled only from the prairie treatment.

The site has a continental climate with a mean annual temperature of 11°C and approximately 1 m of precipitation annually. It is established on deep, highly fertile Mollisol soils (Argiudolls, mapped as Dana, Flanagan and Blackberry silt loam) and was used for agriculture for at least 100 years before establishment of the current experiment. In 2008, the prairie plots were seeded with a mix of 28 species native to Illinois (Pizzo and Associates, Leland IL), treated with a mycorrhizal inoculum ("AM 120"; Reforestation Technologies International; Gilroy CA) that is primarily *Glomus intraradices* (Neal Anderson, RTI Inc.; personal communication), and overseeded with a spring oat (*Avena sativa*) cover crop. The plots were mowed after senescence each year and the above-ground biomass was baled and removed. For futher details on the establishment and management of the site, see previous work by [@Zeri:2011er; @Smith:2013cj; @Masters:2016kw].


### Sample collection

To characterize the spatial distribution of species with depth, we collected mixed root samples on July 15-18 of 2013, after most late-season grasses were well emerged but before most early-season plants began to senesce. At 120 locations (one in each quadrant of each 0.7 Ha plot, two in each quadrant of the 3.8 Ha plot), we used an 8 cm bucket auger to collect roots and soil from 3 cores within a 2 meter area. We pooled all three cores from each location by depth increment (0-10, 10-30, 30-50, 50-75, and 75-100 cm), collected a ~0.5-1 kg subsample of mixed roots and soil from each depth, and returned the remaining material to the holes. Samples were stored on ice in 1-gallon Ziplok bags for transport to the laboratory, then frozen at -80 °C the same day and stored until further analysis.

To characterize the genetic diversity of our target species and generate a mock community for use as a sequencing control, we collected voucher specimens on August 31 and September 1, 2013. For each of the 33 plant species present in aboveground surveys( X. Feng, unpublished data), we located 3-5 individual genets, identified them to species by leaf and flower morphology, and used a trowel to extract known single-species roots still attached to their well-identified crown. We pooled all roots from each species, placed them in Ziplok bags, placed them on ice for transport to the laboratory, and froze them at -80 °C the same day for storage until further analysis.


### Root recovery

To separate roots, rhizosphere soil, and bulk soil, we thawed mixed samples overnight at 4 °C, then screened them through a 2 mm sieve followed by manually picking all visible roots using forceps. We considered any soil that remained attached to root hairs, was not chunky enough to break off with forcepts, and was not removed by a gentle shake, to be rhizosphere soil. The remaining material after all visible roots were removed was considered bulk soil. The picking process took about 30-90 minutes per sample and all sieves, forceps, and gloves were wiped with ethanol immediately before use to minimize contamination by non-sample DNA.

We then rinsed all roots in two changes of sterile water, recovered the rhizosphere soil by centrifugation, further cleaned the root surfaces by sonication in sterile water for 10 minutes and discarded the wash water, then lyophilized all three compoments (root, rhizosphere, and a 50-mL subsample of the bulk soil) and stored them at room temperature. Single-species root voucher samples were treated identically to the mixed root samples with the exception that all bulk soil had been removed at collection time, so no sieving or hand-picking steps were necessary.


### DNA extraction and amplification

To maximize extraction from tough root tissue, we ground all samples once in a dry mortar and pestle at room temperature, then again in liquid nitrogen to a very fine powder. We then weighed ~100 mg of tissue from each sample and extracted whole DNA using a Powersoil-htp isolation kit (Mo Bio Laboratories, Carlsbad CA) according to the manufacturer's directions, including an optional initial bead-beating step. We then performed a post-extraction cleanup using materials from the same kit (E. Adams, Mo Bio; personal communication): We diluted the DNA to  a volume of 100 µL with DNAse-free water, added 50 µL of bead beating solution and inverted to mix, then added 25 µL each of solutions C2 and C3, inverted to mix, and centrifuged at 10000 xg for 2 minutes. We then collected the supernatant, added 2 volumes of solution C4, vortexed, and loaded the sample onto a spin filter. Finally, we washed with 500 µL of solution C5 and eluted with 50 µL of C6.

TK this paragraph needs many details TK: 
After extraction, we submitted whole DNA to the W.M. Keck Center (Urbana, IL, USA) for amplification and sequencing. In addition to DNA extracted from roots and rhizosphere soil, we included nominally-pure extracts of root DNA from four species with high aboveground abundance [*Andropogon gerardii*, *Sorghastrum nutans*, *Silphium perfoliatum*, and *Elymus nutans*; @Feng:2014wv], water extractions as a negative control on the DNA extraction + PCR + sequencing process taken as a whole, and a mock community of DNA from 31 species combined in equimolar quantity. Each sample was amplified by microfluidic PCR using the Fluidigm Access Array chip to create amplicons from five primer sets targeting different regions of the ribosomal RNA genes of diverse phylogenetic groups: Bacterial 16S V4 [cite TK], fungal ITS [cite TK], SSU of Glomeromycota (arbuscular mycorrhizal fungi) [@VanGeel:2014ht], eukaryotic 18S [cite TK], and plant ITS2 [@Chen:2010il]). The resulting amplicons were then barcoded [TK: Do we need to present full linker constructs?] and sequenced by synthesis for 2x301 paired-end cycles (MiSeq, V3 chemistry, Illumina Inc, San Diego CA).
For the remainder of this paper, we discuss only the results obtained from root samples using the plant ITS2 primers S2F (5'-ATGCGATACTTGGTGTGAAT) and S3R (5'-GACGCTTCTCCAGACTACAAT) [@Chen:2010il].


### Data processing

The raw Illumina read files were separated into one file from each primer set and PhiX reference reads were removed using CASAVA 1.8. We then used cutadapt 1.8.1 [@Martin:2011eu] to trim primers, discard all reads that did not begin with the expected primer, and trim 3' bases with a Phred quality score below 20. We then joined the overlapping ends of each read using using the RDP maximum likelihood algorithm [@Cole:2013jw] as implemented in Pandaseq 2.10 [@Masella:2012fc] using a minimum alignment quality of 0.8, a minimum assembled length of 25 bases, and a minimum overlap of at least 20 "bits saved" [corresponds to ~10 bases; see @Cole:2013jw].

We then used the `split_libraries.py` script in QIIME 1.9.1 [@Caporaso:2010jf] to assign barcodes to sequence identities. We then dereplicated sequences and removed singletons and suspected PCR chimeras using VSEARCH 2.0.4 [@Rognes:2016hy], extracted full-length ITS2 variable regions using ITSx 1.0.11 [@BengtssonPalme:2013fn], clustered OTUs using VSEARCH with a similarity threshold of 99%, and assigned taxonomy using BLAST+ [@Camacho:2009fc] against the GenBank `nt` database. After taxonomy assignment, we collapsed all OTUs assigned as the same phylotype (species, genus, or family depending on the analysis of interest) into single taxon groups, then removed taxa with a mean abundance of less than 1% of the reads per sample.

Full analysis scripts and raw sequence data are available online at (Dryad URL TK).

### Statistical analysis: This section still TK.

Two possible approaches: rarefy samples to even depth and report fraction of reads observed in each sample (this throws away a lot of information and systematically understates variance), or alternately model raw counts with a negative binomial distribution to account for overdispersion (conceptually straightforward, computationally finicky).


