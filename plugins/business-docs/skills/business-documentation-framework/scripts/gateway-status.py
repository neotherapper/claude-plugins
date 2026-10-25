#!/usr/bin/env python3
"""
Track gateway document approval status.

Features:
- Identify all gateway documents in project
- Parse approval sections for signatures
- Calculate quality scores where present
- Show approval history
- Alert on unsigned gateways blocking progress

Run: python gateway-status.py <docs/> [--pending]
"""

import sys
import re
from pathlib import Path
from typing import Optional
from datetime import datetime

# Gateway documents with their phase and required approvers
GATEWAYS = {
    'IDEA-04': {'name': 'Problem Statement', 'phase': 'Ideation', 'approvers': ['Sponsor', 'PM']},
    'IDEA-09': {'name': 'Lean Canvas', 'phase': 'Ideation', 'approvers': ['Founding Team']},
    'IDEA-16': {'name': 'Pitch Deck', 'phase': 'Ideation', 'approvers': ['Investors']},
    'IDEA-19': {'name': 'Feasibility Assessment', 'phase': 'Ideation', 'approvers': ['Sponsor', 'Tech Lead']},
    'PROD-01': {'name': 'Product Vision', 'phase': 'Product', 'approvers': ['CPO', 'CEO']},
    'PROD-09': {'name': 'PRD', 'phase': 'Product', 'approvers': ['PM', 'Eng Lead']},
    'TECH-02': {'name': 'Technical Design', 'phase': 'Technical', 'approvers': ['Tech Lead', 'Security']},
    'TECH-05': {'name': 'C4 Container Diagram', 'phase': 'Technical', 'approvers': ['Architect']},
    'ML-01': {'name': 'Model Card', 'phase': 'ML/AI', 'approvers': ['ML Lead']},
    'SEC-01': {'name': 'STRIDE Threat Model', 'phase': 'Security', 'approvers': ['Security Lead']}
}

# Path-specific gateway sequences
PATH_GATEWAYS = {
    'Internal Tool': ['IDEA-04', 'IDEA-19', 'TECH-02'],
    'MVP': ['IDEA-04', 'IDEA-09', 'IDEA-19', 'PROD-09', 'TECH-02'],
    'Investor': ['IDEA-04', 'IDEA-09', 'IDEA-16', 'IDEA-19', 'PROD-09', 'TECH-02'],
    'Full': list(GATEWAYS.keys())
}


def extract_doc_id(filename: str) -> Optional[str]:
    """Extract document ID from filename."""
    patterns = [r'^(IDEA-\d+)', r'^(PROD-\d+)', r'^(TECH-\d+)', r'^(OPS-\d+)',
                r'^(MKT-\d+)', r'^(FUND-\d+)', r'^(ML-\d+)', r'^(SEC-\d+)']
    for pattern in patterns:
        match = re.match(pattern, filename)
        if match:
            return match.group(1)
    return None


def parse_approval_info(content: str) -> dict:
    """Extract approval information from document."""
    info = {
        'approved': False,
        'approvers': [],
        'date': None,
        'quality_score': None,
        'notes': []
    }

    # Check for explicit APPROVED status
    if re.search(r'\*\*APPROVED\*\*|\bAPPROVED\b', content, re.IGNORECASE):
        info['approved'] = True

    # Look for approval table
    # Pattern: | Name | Role | Decision/Status | Date |
    approval_table = re.findall(
        r'\|\s*([^|]+?)\s*\|\s*([^|]*?)\s*\|\s*\*?\*?APPROVED\*?\*?\s*\|\s*([^|]+?)\s*\|',
        content, re.IGNORECASE
    )
    if approval_table:
        for name, role, date in approval_table:
            name = name.strip()
            role = role.strip()
            date = date.strip()
            if name and name != '—' and not name.startswith('---'):
                info['approvers'].append({
                    'name': name,
                    'role': role,
                    'date': date
                })
                if date and date != '—':
                    info['date'] = date
        if info['approvers']:
            info['approved'] = True

    # Also check for single-line approval patterns
    single_approval = re.search(
        r'\|\s*Product Owner\s*\|\s*(\w+)\s*\|\s*\*\*APPROVED\*\*\s*\|\s*([^|]+)\s*\|',
        content
    )
    if single_approval:
        info['approved'] = True
        info['approvers'].append({
            'name': single_approval.group(1),
            'role': 'Product Owner',
            'date': single_approval.group(2).strip()
        })
        info['date'] = single_approval.group(2).strip()

    # Look for quality score
    score_match = re.search(r'(\d+)/(\d+)', content)
    if score_match:
        numerator = int(score_match.group(1))
        denominator = int(score_match.group(2))
        if denominator == 25:  # Quality score format is typically X/25
            info['quality_score'] = f"{numerator}/{denominator}"

    # Look for approval notes
    notes_match = re.search(r'\*\*Approval Notes:\*\*\s*\n((?:[-*]\s+.+\n?)+)', content)
    if notes_match:
        notes = notes_match.group(1)
        info['notes'] = [line.strip('- *\n') for line in notes.split('\n') if line.strip()]

    return info


def detect_path(doc_ids: set) -> str:
    """Detect which path is being followed."""
    has_prod_29 = 'PROD-29' in doc_ids
    has_prod_09 = 'PROD-09' in doc_ids
    has_investor_docs = any(d in doc_ids for d in ['IDEA-11', 'IDEA-14', 'IDEA-16'])

    if has_prod_29 and not has_prod_09:
        return 'Internal Tool'
    elif has_investor_docs:
        return 'Investor'
    else:
        return 'MVP'


def check_gateway_status(docs_path: Path) -> dict:
    """Check status of all gateway documents."""
    # Discover all documents
    documents = {}
    for file in docs_path.glob('*.md'):
        doc_id = extract_doc_id(file.stem)
        if doc_id:
            content = file.read_text(encoding='utf-8')
            documents[doc_id] = {
                'path': file,
                'content': content,
                'approval': parse_approval_info(content) if doc_id in GATEWAYS else None
            }

    # Detect path
    detected_path = detect_path(set(documents.keys()))
    relevant_gateways = PATH_GATEWAYS.get(detected_path, PATH_GATEWAYS['MVP'])

    # Build status report
    gateway_status = []
    blocking = []

    for gateway_id in relevant_gateways:
        gateway_def = GATEWAYS[gateway_id]

        if gateway_id in documents:
            doc = documents[gateway_id]
            approval = doc['approval']

            gateway_status.append({
                'id': gateway_id,
                'name': gateway_def['name'],
                'phase': gateway_def['phase'],
                'exists': True,
                'approved': approval['approved'],
                'approvers': approval['approvers'],
                'date': approval['date'],
                'quality_score': approval['quality_score'],
                'notes': approval['notes']
            })

            if not approval['approved']:
                blocking.append({
                    'id': gateway_id,
                    'reason': 'Document exists but not approved',
                    'required_approvers': gateway_def['approvers']
                })
        else:
            gateway_status.append({
                'id': gateway_id,
                'name': gateway_def['name'],
                'phase': gateway_def['phase'],
                'exists': False,
                'approved': False,
                'approvers': [],
                'date': None,
                'quality_score': None,
                'notes': []
            })
            blocking.append({
                'id': gateway_id,
                'reason': 'Document missing',
                'required_approvers': gateway_def['approvers']
            })

    approved_count = sum(1 for g in gateway_status if g['approved'])
    total_count = len(gateway_status)

    return {
        'path': detected_path,
        'gateways': gateway_status,
        'summary': {
            'approved': approved_count,
            'total': total_count,
            'percentage': round(approved_count / total_count * 100) if total_count > 0 else 0
        },
        'blocking': blocking
    }


def print_status(result: dict, docs_path: Path, pending_only: bool = False):
    """Print human-readable gateway status."""
    print(f"Gateway Status: {docs_path.parent.name}")
    print(f"Path: {result['path']}")
    print()

    # Table header
    print("| Gateway | Status | Quality Score | Approvers | Date |")
    print("|---------|--------|---------------|-----------|------|")

    for g in result['gateways']:
        if pending_only and g['approved']:
            continue

        if g['exists'] and g['approved']:
            status = '✅ Approved'
        elif g['exists']:
            status = '⏳ Pending'
        else:
            status = '❌ Missing'

        score = g['quality_score'] or '—'

        if g['approvers']:
            approvers = ', '.join(f"{a['name']} ({a['role']})" if a['role'] else a['name']
                                  for a in g['approvers'])
        else:
            approvers = '—'

        date = g['date'] or '—'

        print(f"| {g['id']} | {status} | {score} | {approvers} | {date} |")

    print()

    # Summary
    print(f"Progress: {result['summary']['approved']}/{result['summary']['total']} gateways approved ({result['summary']['percentage']}%)")

    # Blocking issues
    if result['blocking']:
        print()
        print("🔒 Blocking Progress:")
        for b in result['blocking']:
            required = ', '.join(b['required_approvers'])
            print(f"  → {b['id']}: {b['reason']}")
            print(f"    Required approvers: {required}")


def main():
    # Parse arguments
    args = sys.argv[1:]
    pending_only = '--pending' in args
    json_output = '--json' in args
    args = [a for a in args if not a.startswith('-')]

    if not args:
        print("Usage: python gateway-status.py <docs/> [--pending] [--json]")
        sys.exit(1)

    docs_path = Path(args[0])

    if not docs_path.is_dir():
        print(f"Error: Not a directory: {docs_path}")
        sys.exit(1)

    result = check_gateway_status(docs_path)

    if json_output:
        import json
        # Remove content from output
        for g in result['gateways']:
            if 'content' in g:
                del g['content']
        print(json.dumps(result, indent=2, default=str))
    else:
        print_status(result, docs_path, pending_only)

    # Exit with error if any blocking issues
    sys.exit(0 if not result['blocking'] else 1)


if __name__ == '__main__':
    main()
