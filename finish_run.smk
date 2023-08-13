configfile: 'wrangler_by_sample.yaml'
nested_output=config['output_folder']+'/'+config['analysis_dir']
good_samples=[line.strip() for line in open(nested_output+'/successfully_extracted_samples.txt')]
all_targets=[line.strip().split('\t')[0] for line in open(nested_output+'/mip_ids/allMipsSamplesNames.tab.txt')][1:]
rule all:
	input:
		pop_clustered=expand(nested_output+'/pop_clustering_status/{target}_pop_clustering_finished.txt', target=all_targets)
#		pop_clustered=expand(nested_output+'/analysis/populationClustering/{target}/analysis/selectedClustersInfo.tab.txt', target=all_targets)
#		mip_cluster_files=expand(nested_output+'/clustering_status/{sample}_mip_clustering_finished.txt', sample=good_samples)
#		corrected_barcode_marker=nested_output+'/analysis/logs/mipCorrectForContamWithSameBarcodes_run1.json'
#		all_corrected=expand(nested_output+'/analysis/{sample}/{sample}_mipBarcodeCorrection/barcodeFilterStats.tab.txt', sample=good_samples)
#		population_output='/path/to/final/allInfo.tab.txt'

rule mip_barcode_correction:
	input:
		good_samples=nested_output+'/successfully_extracted_samples.txt'
	params:
		output_dir='/opt/analysis/analysis',
		wrangler_dir=nested_output,
		sif_file=config['miptools_sif']
	resources:
		mem_mb=20000,
		time_min=20
	output:
		barcode_corrections_finished=nested_output+'/analysis/{sample}/{sample}_mipBarcodeCorrection/barcodeFilterStats.tab.txt'
	shell:
		'''
		singularity exec \
		-B {params.wrangler_dir}:/opt/analysis \
		{params.sif_file} \
		MIPWrangler mipBarcodeCorrection --masterDir {params.output_dir} --overWriteDirs --sample {wildcards.sample}
		'''

rule correct_for_same_barcode_contam:
	input:
		all_corrected=expand(nested_output+'/analysis/{sample}/{sample}_mipBarcodeCorrection/barcodeFilterStats.tab.txt', sample=good_samples)
	params:
		output_dir='/opt/analysis/analysis',
		wrangler_dir=nested_output,
		sif_file=config['miptools_sif'],
	resources:
		mem_mb=40000,
		time_min=1440,
		nodes=20
	threads: 20
	output:
		#name is controlled by --logFile
		corrected_barcode_marker=nested_output+'/analysis/logs/mipCorrectForContamWithSameBarcodes_run1.json'
	shell:
		'''
		singularity exec \
		-B {params.wrangler_dir}:/opt/analysis \
		{params.sif_file} \
		MIPWrangler mipCorrectForContamWithSameBarcodesMultiple --masterDir {params.output_dir} --numThreads {threads} --overWriteDirs --overWriteLog --logFile mipCorrectForContamWithSameBarcodes_run1
		'''

rule mip_clustering:
	input:
		corrected_barcode_marker=nested_output+'/analysis/logs/mipCorrectForContamWithSameBarcodes_run1.json',
		#sample_dir=nested_output+'/analysis/{sample}'
	params:
		output_dir='/opt/analysis/analysis',
		wrangler_dir=nested_output,
		sif_file=config['miptools_sif']
	resources:
		mem_mb=16000,
		time_min=60,
	output:
		mip_clustering=nested_output+'/clustering_status/{sample}_mip_clustering_finished.txt'
	shell:
		'''
		singularity exec \
		-B {params.wrangler_dir}:/opt/analysis \
		{params.sif_file} \
		MIPWrangler mipClustering --masterDir {params.output_dir} --overWriteDirs --par /opt/resources/clustering_pars/illumina_collapseHomoploymers.pars.txt --countEndGaps --sample {wildcards.sample}
		touch {output.mip_clustering}
		'''

rule pop_cluster_target:
	input:
		mip_cluster_files=expand(nested_output+'/clustering_status/{sample}_mip_clustering_finished.txt', sample=good_samples)
	params:
		output_dir='/opt/analysis/analysis',
		wrangler_dir=nested_output,
		sif_file=config['miptools_sif']
	resources:
		mem_mb=16000,
		time_min=60,
	output:
		pop_clustering=nested_output+'/pop_clustering_status/{target}_pop_clustering_finished.txt'
	shell:
		'''
		singularity exec \
		-B {params.wrangler_dir}:/opt/analysis \
		{params.sif_file} \
		MIPWrangler mipPopulationClustering --keepIntermediateFiles --masterDir {params.output_dir} --overWriteDirs --cutoff 0 --countEndGaps --fraccutoff 0.005 --mipName {wildcards.target}
		touch {output.pop_clustering}
		'''
