#!/usr/bin/env python3
"""
Cross-document consistency validator.

Features:
- Extract "traceable fields" from each document
- Compare across all project documents
- Flag inconsistencies (different wording, contradictions)
- Suggest canonical version from earliest source

Traceable fields:
- Customer segment definition
- Problem statement
- Success metrics
- Key terminology

Run: python check-consistency.py <docs/> [--field customer_segment] [--verbose]
"""

import sys
import re
from pathlib import Path
from typing import Optional
from difflib import SequenceMatcher

# Fields to track and their source documents
TRACEABLE_FIELDS = {
    'customer_segment': {
        'canonical_source': 'IDEA-04',
        'patterns': [
            r'Customer Segment.*?(?:Who|Primary User)[:\s]*(.+?)(?:\n|$)',
            r'\*\*Primary User:\*\*\s*(.+?)(?:\n|$)',
            r'\*\*Who:\*\*\s*(.+?)(?:\n|$)',
            r'\[([^\]]+?)\]\s*struggles with',
            r'Technical leads.*?on small teams.*?\([^)]+\)',
        ],
        'aliases': ['target customer', 'user persona', 'who experiences']
    },
    'problem_statement': {
        'canonical_source': 'IDEA-04',
        'patterns': [
            r'One-Sentence Problem.*?\n+\*\*(.+?)\*\*',
            r'Problem Statement.*?Executive Summary.*?\n+(.+?)(?:\n\n|\n###)',
            r'\[([^\]]+?)\]\s*struggles with\s*\[([^\]]+?)\]',
        ],
        'aliases': ['problem', 'pain point', 'challenge']
    },
    'success_metrics': {
        'canonical_source': 'PROD-18',
        'patterns': [
            r'Success Metrics:.*?\n((?:[-*]\s+.+\n?)+)',
            r'Success Criteria.*?\n((?:[-*]\s+.+\n?)+)',
            r'\*\*Success Metrics:\*\*.*?\n((?:[-*]\s+.+\n?)+)',
        ],
        'aliases': ['metrics', 'KPIs', 'outcomes']
    },
    'value_proposition': {
        'canonical_source': 'IDEA-08',
        'patterns': [
            r'Unique Value Proposition.*?\n(.+?)(?:\n\n|\n##)',
            r'Value Proposition.*?\n(.+?)(?:\n\n|\n##)',
        ],
        'aliases': ['value prop', 'benefit']
    }
}

# Document priority order (earlier = more authoritative)
DOCUMENT_PRIORITY = [
    'IDEA-01', 'IDEA-02', 'IDEA-03', 'IDEA-21', 'IDEA-04', 'IDEA-08', 'IDEA-09', 'IDEA-19',
    'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'
]


def extract_doc_id(filename: str) -> Optional[str]:
    """Extract document ID from filename."""
    patterns = [r'^(IDEA-\d+)', r'^(PROD-\d+)', r'^(TECH-\d+)', r'^(OPS-\d+)',
                r'^(MKT-\d+)', r'^(FUND-\d+)', r'^(ML-\d+)', r'^(SEC-\d+)']
    for pattern in patterns:
        match = re.match(pattern, filename)
        if match:
            return match.group(1)
    return None


def extract_field(content: str, field_config: dict) -> Optional[str]:
    """Extract a traceable field from document content."""
    for pattern in field_config['patterns']:
        match = re.search(pattern, content, re.IGNORECASE | re.DOTALL)
        if match:
            # Get the first captured group, or full match if no groups
            value = match.group(1) if match.groups() else match.group(0)
            # Clean up the value
            value = value.strip()
            value = re.sub(r'\s+', ' ', value)  # Normalize whitespace
            value = value[:500]  # Limit length
            if len(value) > 20:  # Minimum meaningful length
                return value
    return None


def similarity_score(s1: str, s2: str) -> float:
    """Calculate similarity between two strings."""
    # Normalize
    s1 = s1.lower().strip()
    s2 = s2.lower().strip()
    return SequenceMatcher(None, s1, s2).ratio()


def check_consistency(docs_path: Path, target_field: Optional[str] = None, verbose: bool = False) -> dict:
    """Check consistency of traceable fields across documents."""
    # Load all documents
    documents = {}
    for file in docs_path.glob('*.md'):
        doc_id = extract_doc_id(file.stem)
        if doc_id:
            content = file.read_text(encoding='utf-8')
            documents[doc_id] = {
                'content': content,
                'filename': file.name
            }

    # Extract fields from each document
    results = {}
    fields_to_check = [target_field] if target_field else list(TRACEABLE_FIELDS.keys())

    for field_name in fields_to_check:
        if field_name not in TRACEABLE_FIELDS:
            continue

        field_config = TRACEABLE_FIELDS[field_name]
        canonical_source = field_config['canonical_source']

        extractions = {}
        for doc_id in DOCUMENT_PRIORITY:
            if doc_id not in documents:
                continue
            value = extract_field(documents[doc_id]['content'], field_config)
            if value:
                extractions[doc_id] = value

        # Determine canonical value
        canonical_value = None
        canonical_doc = None

        if canonical_source in extractions:
            canonical_value = extractions[canonical_source]
            canonical_doc = canonical_source
        elif extractions:
            # Use earliest document as canonical
            for doc_id in DOCUMENT_PRIORITY:
                if doc_id in extractions:
                    canonical_value = extractions[doc_id]
                    canonical_doc = doc_id
                    break

        # Compare all extractions to canonical
        comparisons = []
        for doc_id, value in extractions.items():
            if doc_id == canonical_doc:
                comparisons.append({
                    'doc_id': doc_id,
                    'value': value[:200] + '...' if len(value) > 200 else value,
                    'status': 'canonical',
                    'similarity': 1.0
                })
            else:
                sim = similarity_score(canonical_value, value) if canonical_value else 0
                if sim > 0.9:
                    status = 'matches'
                elif sim > 0.7:
                    status = 'similar'
                else:
                    status = 'different'

                comparisons.append({
                    'doc_id': doc_id,
                    'value': value[:200] + '...' if len(value) > 200 else value,
                    'status': status,
                    'similarity': round(sim, 2)
                })

        inconsistencies = [c for c in comparisons if c['status'] in ['similar', 'different']]

        results[field_name] = {
            'canonical_source': canonical_doc,
            'canonical_value': canonical_value[:200] + '...' if canonical_value and len(canonical_value) > 200 else canonical_value,
            'extractions': comparisons,
            'inconsistencies': len(inconsistencies),
            'documents_checked': len(extractions)
        }

    # Summary
    total_inconsistencies = sum(r['inconsistencies'] for r in results.values())
    total_warnings = sum(1 for r in results.values()
                        for c in r['extractions']
                        if c['status'] == 'similar')

    return {
        'fields': results,
        'summary': {
            'inconsistencies': total_inconsistencies,
            'warnings': total_warnings,
            'fields_checked': len(results)
        }
    }


def print_results(result: dict, verbose: bool = False):
    """Print human-readable results."""
    print("Consistency Check")
    print("=" * 60)
    print()

    for field_name, field_result in result['fields'].items():
        print(f"{field_name.replace('_', ' ').title()}:")

        if field_result['canonical_source']:
            print(f"  Source: {field_result['canonical_source']} (canonical)")
            if verbose and field_result['canonical_value']:
                print(f"  Definition: \"{field_result['canonical_value']}\"")
        else:
            print("  Source: Not found")
            print()
            continue

        print()
        for comp in field_result['extractions']:
            if comp['status'] == 'canonical':
                continue

            if comp['status'] == 'matches':
                icon = '✅'
            elif comp['status'] == 'similar':
                icon = '⚠️ '
            else:
                icon = '❌'

            sim_pct = int(comp['similarity'] * 100)
            print(f"  {icon} {comp['doc_id']}: {comp['status']} ({sim_pct}% similar)")

            if verbose and comp['status'] != 'matches':
                print(f"      \"{comp['value']}\"")

        if not any(c for c in field_result['extractions'] if c['status'] != 'canonical'):
            if field_result['documents_checked'] > 1:
                print(f"  ✅ All {field_result['documents_checked']} documents consistent")
            elif field_result['documents_checked'] == 1:
                print("  Only found in canonical source")

        print()

    # Summary
    print("-" * 60)
    print(f"Summary: {result['summary']['inconsistencies']} inconsistencies, "
          f"{result['summary']['warnings']} warnings")


def main():
    # Parse arguments
    args = sys.argv[1:]
    verbose = '--verbose' in args or '-v' in args
    json_output = '--json' in args

    target_field = None
    for i, arg in enumerate(args):
        if arg == '--field' and i + 1 < len(args):
            target_field = args[i + 1]

    args = [a for a in args if not a.startswith('-') and a != target_field]

    if not args:
        print("Usage: python check-consistency.py <docs/> [--field customer_segment] [--verbose]")
        print()
        print("Available fields:")
        for field in TRACEABLE_FIELDS:
            print(f"  - {field}")
        sys.exit(1)

    docs_path = Path(args[0])

    if not docs_path.is_dir():
        print(f"Error: Not a directory: {docs_path}")
        sys.exit(1)

    result = check_consistency(docs_path, target_field, verbose)

    if json_output:
        import json
        print(json.dumps(result, indent=2))
    else:
        print_results(result, verbose)

    # Exit with error if inconsistencies found
    sys.exit(0 if result['summary']['inconsistencies'] == 0 else 1)


if __name__ == '__main__':
    main()
