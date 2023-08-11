'''
creates a mip_ids folder and an allMipsSamplesNames.tab.txt file. extracts mips,
corrects mips, and generates files that can be used to determine sample names as
well as sample names that had extractable data.
'''

configfile: 'wrangler_by_sample.yaml'
nested_output=config['output_folder']+'/'+config['analysis_dir']

rule all:
	input:
		good_samples=nested_output+'/successfully_extracted_samples.txt',
		output_configfile=nested_output+'/snakemake_params/wrangler_by_sample.yaml'

rule copy_files:
	input:
		input_snakefile='wrangler_by_sample.smk',
		input_configfile='wrangler_by_sample.yaml',
		in_scripts='scripts'
	output:
		output_snakefile=nested_output+'/snakemake_params/wrangler_by_sample.smk',
		output_configfile=nested_output+'/snakemake_params/wrangler_by_sample.yaml',
		out_scripts=directory(nested_output+'/snakemake_params/scripts')
	shell:
		'''
		cp {input.input_snakefile} {output.output_snakefile}
		cp {input.input_configfile} {output.output_configfile}
		cp -r {input.in_scripts} {output.out_scripts}
		'''

rule generate_mip_files:
	'''
	given that I'm repackaging miptools wrangler (so wrangler.sh is not needed)
	and that the existing generate_wrangler_scripts.py seems unnecessarily
	convoluted and that only two files are needed by subsequent steps
	(mipArms.txt and allMipsSamplesNames.tab.txt) I wrote my own
	script for this. Input is an arms file and a sample sheet. Output is an arms
	file with rearranged columns and a two column file with names of all mips
	and names of all samples (with no pairing between columns of any given row).
	'''
	input:
		arms_file=config['project_resources']+'/mip_ids/mip_arms.txt',
		sample_sheet=config['input_sample_sheet']
	output:
		mip_arms=nested_output+'/mip_ids/mipArms.txt',
		sample_file=nested_output+'/mip_ids/allMipsSamplesNames.tab.txt',
		sample_sheet=nested_output+'/sample_sheet.tsv'
	script:
		'scripts/generate_mip_files.py'

rule setup_and_extract_by_arm:
	input:
		mip_arms=nested_output+'/mip_ids/mipArms.txt',
		sample_file=nested_output+'/mip_ids/allMipsSamplesNames.tab.txt'
	params:
		output_dir='/opt/analysis/analysis',
		project_resources=config['project_resources'],
		wrangler_dir=nested_output,
		sif_file=config['miptools_sif'],
		fastq_dir=config['fastq_dir']
	output:
		extraction_finished=nested_output+'/logs/extractFromRawLog.json'
	threads: config['cpu_count']
	resources:
		nodes=30,
		mem_mb=200000,
		time_min=2400
	shell:
		'''
		singularity exec \
		-B {params.project_resources}:/opt/project_resources \
		-B {params.wrangler_dir}:/opt/analysis \
		-B {params.fastq_dir}:/opt/data \
		{params.sif_file} \
		MIPWrangler mipSetupAndExtractByArm --mipArmsFilename /opt/analysis/mip_ids/mipArms.txt --mipSampleFile /opt/analysis/mip_ids/allMipsSamplesNames.tab.txt --numThreads {threads} --masterDir {params.output_dir} --dir /opt/data --mipServerNumber 1 --minCaptureLength=30
		'''

#optional: rule below checks for log file for each sample - might implement in
#rule above so snakemake can track
rule get_good_samples:
	input:
		extraction_finished=nested_output+'/logs/extractFromRawLog.json',
		sample_file=nested_output+'/mip_ids/allMipsSamplesNames.tab.txt'
	params:
		nested_output=nested_output
	output:
		good_samples=nested_output+'/successfully_extracted_samples.txt'
	scripts:
		'scripts/get_good_samples.py'
