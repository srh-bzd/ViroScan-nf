#!/usr/bin/env python

import argparse
import json
import re
import sys

"""
USAGE
    ./write_viral_table.py <sample> <json_file> <output_file> <threshold>

DESCRIPTION
    Calculate metrics from breseq summary.json.
"""


def parse_json_file(json_file, threshold):
    """
    Parse input json file, calculate some metrics.
    Returns a list of dicts for each reference above threshold.
    """
    data = json.load(json_file)
    total_reads = data["reads"]["total_reads"]
    total_aligned_reads = data["reads"]["total_aligned_reads"]
    results = []

    for ref_id, ref_info in data["references"]["reference"].items():
        aligned_reads = ref_info["num_reads_mapped_to_reference"]
        percent_reads_mapped = round((aligned_reads / total_reads) * 100, 1) if total_reads else 0
        avg_coverage = round(ref_info.get("coverage_average", 0), 1)
        genome_length = ref_info.get("length", 0)
        num_bases_mapped = ref_info.get("num_bases_mapped_to_reference", 0)
        if genome_length > 0 and avg_coverage > 0:
            percent_genome_covered = round((num_bases_mapped / (genome_length * avg_coverage)) * 100, 1)
        else:
            percent_genome_covered = 0


        if percent_reads_mapped >= threshold:
            results.append({
                "reference_id": ref_id,
                "aligned_reads": aligned_reads,
                "percent_reads_mapped": percent_reads_mapped,
                "avg_coverage": avg_coverage,
                "percent_genome_covered": percent_genome_covered,
                "num_bases_mapped": num_bases_mapped,
                "num_genes": ref_info.get("num_genes", 0),
                "num_features": ref_info.get("num_features", 0),
                "coverage_variance": ref_info.get("coverage_variance", 0)
            })

    return total_reads, total_aligned_reads, results


def natural_sort_key(s):
    """
    Alphanumeric sort key.
    """
    convert = lambda text: int(text) if text.isdigit() else text.lower()
    return [convert(c) for c in re.split('([0-9]+)', s)]


def write_results(sample, total_reads, total_aligned_reads, results, output_file):
    """
    Write enriched table to file.
    """
    # Sort references naturally
    for ref in sorted(results, key=lambda x: natural_sort_key(x["reference_id"])):
        row = [
            sample,
            ref["reference_id"],
            str(total_reads),
            str(ref["aligned_reads"]),
            str(ref["percent_reads_mapped"]),
            str(ref['avg_coverage']),
            str(ref["percent_genome_covered"]),
            str(ref["num_bases_mapped"]),
            str(ref["num_genes"]),
            str(ref["num_features"]),
            str(ref["coverage_variance"])
        ]
        output_file.write("\t".join(row) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate enriched viral alignment table from breseq summary.json"
    )
    parser.add_argument("sample", type=str, help="Sample name")
    parser.add_argument("json_file", type=argparse.FileType("r"), help="breseq summary.json file")
    parser.add_argument("output_file", type=argparse.FileType("w"), help="Output TSV file")
    parser.add_argument("threshold", type=float, help="Minimum % aligned to report")
    args = parser.parse_args()

    total_reads, total_aligned_reads, results = parse_json_file(args.json_file, args.threshold)
    write_results(args.sample, total_reads, total_aligned_reads, results, args.output_file)