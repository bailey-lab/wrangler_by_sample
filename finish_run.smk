configfile: 'wrangler_by_sample.yaml'
nested_output=config['output_folder']+'/'+config['analysis_dir']
good_samples=nested_output+'/successfully_extracted_samples.txt'

rule all:
	input:
		population_output='/path/to/final/allInfo.tab.txt'
		
rule mip_barcode_correction_multiple:
	output:
		correction_finished=nested_output+'/correction_finished.txt'
	params:
		output_dir='/opt/analysis/analysis',
		wrangler_dir=nested_output,
		sif_file=config['miptools_sif'],
	threads: config['cpu_count']
	shell:
		'''
		singularity exec \
		-B {params.wrangler_dir}:/opt/analysis \
		{params.sif_file} \
		MIPWrangler mipBarcodeCorrectionMultiple --keepIntermediateFiles --masterDir {params.output_dir} --numThreads {threads} --overWriteDirs --overWriteLog --logFile mipBarcodeCorrecting_run1 --allowableErrors 6
		touch {output.correction_finished}
		'''

rule mip_barcode_correction:
	input:
		analysis_dir=nested_output+'/logs/extractFromRawLog.json'
	resources:
		nodes=10,
		mem_mb=20000,
		time_min=2400
	output:
		barcode_corrections_finished=nested_output+'/{sample}/{sample}_mipBarcodeCorrection/barcodeFilterStats.tab.txt'
	shell:
		

#sftp://mouse/nfs/jbailey5/baileyweb/asimkin/miptools/miptools_by_sample_prototyping/output/analysis/analysis/D10-JJJ-44/D10-JJJ-44_mipExtraction/extractInfoSummary.txt


#MIPWrangler mipCorrectForContamWithSameBarcodesMultiple --masterDir {params.output_dir} --numThreads {threads} --overWriteDirs --overWriteLog --logFile mipCorrectForContamWithSameBarcodes_run1
rule correct_for_same_barcode_contam:
	input:
		expand('/nfs/jbailey5/baileyweb/asimkin/miptools/miptools_by_sample_prototyping/output/analysis/analysis/{sample}/{sample}_mipBarcodeCorrection/barcodeFilterStats.tab.txt', sample=good_samples)
	output:
		#name is controlled by --logFile
		corrected_barcode_marker='/nfs/jbailey5/baileyweb/asimkin/miptools/miptools_by_sample_prototyping/output/analysis/analysis/logs/mipCorrectForContamWithSameBarcodes_run1.json'

rule mip_clustering:
	input:
		corrected_barcode_marker='/nfs/jbailey5/baileyweb/asimkin/miptools/miptools_by_sample_prototyping/output/analysis/analysis/logs/mipCorrectForContamWithSameBarcodes_run1.json'
	output:
		mip_cluster_finished='/path/to/logs/{sample}/mip_clustering_finished.txt'
	script:
		'scripts/mip_clustering.py'

#need to tell snakemake that target files (for rule below) have been generated somehow

rule pop_cluster_target:
	input:
		mip_cluster_files=expand(mip_cluster_finished='/path/to/logs/{sample}/mip_clustering_finished.txt', sample=[good_samples])
	output:
		target_file='/nfs/jbailey5/baileyweb/asimkin/miptools/miptools_by_sample_prototyping/output/analysis/analysis/populationClustering/{target}/analysis/selectedClustersInfo.tab.txt.gz'
	script:
		'scripts/pop_cluster_target.py'

rule output_final_table:
	'''
	cat together output files of previous step into a final file, do a "natural sort" to sort things similar to how Nick's are output
	gzip it
	'''
	input:
		target_file=expand('/nfs/jbailey5/baileyweb/asimkin/miptools/miptools_by_sample_prototyping/output/analysis/analysis/populationClustering/{target}/analysis/selectedClustersInfo.tab.txt.gz', target=config['targets'])
#		final_sample_outputs=expand('/path/to/sample/outputs/{sample}.something', sample=sample_list)
	output:
		population_output='/path/to/final/allInfo.tab.txt'
	script:
		'scripts/output_table.py'
