#!/usr/bin/env python3
"""
Extract the Seven Essential Information Categories for business-to-code handoff.

The Seven Categories (from CLAUDE.md):
1. Problem Definition (from IDEA-04)
2. Success Metrics (from PROD-18, PROD-09)
3. Constraints/Appetite (from IDEA-09, PROD-09)
4. Non-Goals/No-Gos (from PROD-09)
5. Key Decisions Made (from TECH-02)
6. User Context (from IDEA-01, IDEA-02)
7. Business Rationale (from IDEA-09)

Run: python extract-seven-categories.py <docs/> [--output handoff.md] [--json]
"""

import sys
import re
import json
from pathlib import Path
from typing import Optional
from datetime import datetime

# The Seven Essential Information Categories
SEVEN_CATEGORIES = {
    'problem_definition': {
        'name': 'Problem Definition',
        'primary_source': 'IDEA-04',
        'secondary_sources': [],
        'patterns': [
            r'One-Sentence Problem.*?\n+\*\*(.+?)\*\*',
            r'Problem Statement.*?Executive Summary.*?\n+(.+?)(?:\n\n|\n###)',
            r'The Problem \(4-Part Format\).*?\n+(.+?)(?:\n\n|\n##)',
            r'##\s*1\.\s*Problem Statement.*?\n+(.+?)(?:\n\n|\n##)',
        ],
        'description': 'The specific user pain being solved'
    },
    'success_metrics': {
        'name': 'Success Metrics',
        'primary_source': 'PROD-18',
        'secondary_sources': ['PROD-09', 'IDEA-04'],
        'patterns': [
            r'\*\*Success Metrics:\*\*\s*\n((?:[-*]\s+.+\n?)+)',
            r'Success Criteria.*?\n\|.*?\n\|[-\s|]+\n((?:\|.+\n?)+)',
            r'Success Metrics.*?\n((?:[-*]\s+.+\n?)+)',
            r'##\s*Success Criteria\s*\n((?:.+\n)+?)(?:\n##|\n---)',
        ],
        'description': 'Quantified outcomes for validation'
    },
    'constraints_appetite': {
        'name': 'Constraints/Appetite',
        'primary_source': 'IDEA-09',
        'secondary_sources': ['PROD-09', 'IDEA-04'],
        'patterns': [
            r'Constraints.*?\n((?:[-*]\s+.+\n?)+)',
            r'Time.*?Budget.*?Scope.*?\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Appetite.*?\n(.+?)(?:\n\n|\n##)',
            r'Boundaries.*?\n((?:[-*]\s+.+\n?)+)',
            r'What the Solution Must Be\s*\n((?:.+\n)+?)(?:\n##|\n---)',
        ],
        'description': 'Time, budget, scope limits'
    },
    'non_goals': {
        'name': 'Non-Goals/No-Gos',
        'primary_source': 'PROD-09',
        'secondary_sources': ['IDEA-04'],
        'patterns': [
            r'Non-Goals.*?\n((?:[-*]\s+.+\n?)+)',
            r'Out of Scope.*?\n((?:[-*]\s+.+\n?)+)',
            r'What the Solution Must NOT Be\s*\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Explicitly Excluded.*?\n((?:[-*]\s+.+\n?)+)',
        ],
        'description': 'Explicitly excluded features'
    },
    'key_decisions': {
        'name': 'Key Decisions Made',
        'primary_source': 'TECH-02',
        'secondary_sources': ['IDEA-19', 'IDEA-20'],
        'patterns': [
            r'Key Decisions.*?\n((?:[-*]\s+.+\n?)+)',
            r'Decisions Made.*?\n((?:[-*]\s+.+\n?)+)',
            r'Technical Decisions.*?\n((?:[-*]\s+.+\n?)+)',
            r'Architecture Decisions.*?\n((?:[-*]\s+.+\n?)+)',
            r'Build vs Buy.*?Decision.*?\n(.+?)(?:\n\n|\n##)',
        ],
        'description': 'Settled technical choices with rationale'
    },
    'user_context': {
        'name': 'User Context',
        'primary_source': 'IDEA-01',
        'secondary_sources': ['IDEA-02', 'IDEA-04', 'PROD-09'],
        'patterns': [
            r'Customer Segment.*?\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Who Experiences This Problem.*?\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Primary User.*?\n(.+?)(?:\n\n|\n##)',
            r'Persona.*?\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Jobs to Be Done.*?\n((?:.+\n)+?)(?:\n##|\n---)',
        ],
        'description': 'Usage environment, expertise level'
    },
    'business_rationale': {
        'name': 'Business Rationale',
        'primary_source': 'IDEA-09',
        'secondary_sources': ['IDEA-04', 'IDEA-19'],
        'patterns': [
            r'Why Now\?.*?\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Unique Value Proposition.*?\n(.+?)(?:\n\n|\n##)',
            r'Business Model.*?\n((?:.+\n)+?)(?:\n##|\n---)',
            r'Strategic Fit.*?\n(.+?)(?:\n\n|\n##)',
            r'Feasibility.*?Assessment.*?\n((?:.+\n)+?)(?:\n##|\n---)',
        ],
        'description': 'Why this solution, strategic fit'
    }
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


def extract_category(content: str, category_config: dict) -> Optional[str]:
    """Extract a category from document content."""
    for pattern in category_config['patterns']:
        match = re.search(pattern, content, re.IGNORECASE | re.DOTALL)
        if match:
            value = match.group(1) if match.groups() else match.group(0)
            value = value.strip()
            # Clean up
            value = re.sub(r'\n{3,}', '\n\n', value)  # Max 2 newlines
            if len(value) > 50:  # Minimum meaningful length
                return value[:2000]  # Limit to 2000 chars
    return None


def extract_seven_categories(docs_path: Path) -> dict:
    """Extract all seven categories from project documents."""
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

    results = {}
    missing = []

    for category_key, category_config in SEVEN_CATEGORIES.items():
        primary = category_config['primary_source']
        secondary = category_config['secondary_sources']

        extracted = None
        source_doc = None

        # Try primary source first
        if primary in documents:
            extracted = extract_category(documents[primary]['content'], category_config)
            if extracted:
                source_doc = primary

        # Fall back to secondary sources
        if not extracted:
            for sec in secondary:
                if sec in documents:
                    extracted = extract_category(documents[sec]['content'], category_config)
                    if extracted:
                        source_doc = sec
                        break

        if extracted:
            results[category_key] = {
                'name': category_config['name'],
                'source': source_doc,
                'expected_source': primary,
                'content': extracted,
                'status': 'complete'
            }
        else:
            missing.append(category_key)
            primary_exists = primary in documents
            results[category_key] = {
                'name': category_config['name'],
                'source': None,
                'expected_source': primary,
                'content': None,
                'status': 'missing',
                'note': f"{primary} {'exists but category not found' if primary_exists else 'not created yet'}"
            }

    return {
        'categories': results,
        'summary': {
            'complete': len(results) - len(missing),
            'missing': len(missing),
            'missing_categories': missing,
            'total': len(SEVEN_CATEGORIES),
            'ready_for_handoff': len(missing) == 0
        },
        'extracted_at': datetime.now().isoformat()
    }


def generate_handoff_markdown(result: dict, project_name: str) -> str:
    """Generate a markdown handoff document."""
    lines = [
        f"# Business-to-Code Handoff: {project_name}",
        f"",
        f"**Generated:** {result['extracted_at'][:10]}",
        f"**Status:** {'Ready for Implementation' if result['summary']['ready_for_handoff'] else 'Incomplete - see missing sections'}",
        f"",
        "---",
        "",
        "## Overview",
        "",
        f"This document contains the Seven Essential Information Categories extracted from business documentation.",
        f"",
        f"- Categories complete: {result['summary']['complete']}/{result['summary']['total']}",
    ]

    if result['summary']['missing_categories']:
        lines.append(f"- Missing: {', '.join(result['summary']['missing_categories'])}")

    lines.extend(["", "---", ""])

    # Add each category
    for category_key, category_config in SEVEN_CATEGORIES.items():
        cat_result = result['categories'][category_key]

        lines.append(f"## {cat_result['name']}")
        lines.append(f"")
        lines.append(f"*{category_config['description']}*")
        lines.append(f"")

        if cat_result['status'] == 'complete':
            lines.append(f"**Source:** {cat_result['source']}")
            lines.append(f"")
            lines.append(cat_result['content'])
        else:
            lines.append(f"⚠️ **MISSING** - {cat_result['note']}")
            lines.append(f"")
            lines.append(f"Expected source: {cat_result['expected_source']}")

        lines.extend(["", "---", ""])

    # Add usage instructions
    lines.extend([
        "## Using This Handoff",
        "",
        "This document should be placed in your project's memory bank or provided to AI agents during implementation:",
        "",
        "1. **Memory Bank:** Copy to `.claude/memory-bank/businessContext.md`",
        "2. **Taskmaster:** Copy to `.taskmaster/docs/` and run `task-master parse-prd`",
        "3. **Claude Code:** Reference in CLAUDE.md or project instructions",
        "",
        "The seven categories ensure AI agents understand:",
        "- **What** problem we're solving (not just features)",
        "- **Who** we're solving it for (not abstract personas)",
        "- **Why** this approach (not alternative designs)",
        "- **How** to measure success (not just completion)",
    ])

    return '\n'.join(lines)


def print_results(result: dict):
    """Print human-readable results."""
    print("Seven Essential Information Categories")
    print("=" * 60)
    print()

    for category_key, cat_result in result['categories'].items():
        status_icon = '✅' if cat_result['status'] == 'complete' else '❌'
        source = f"({cat_result['source']})" if cat_result['source'] else f"(missing: {cat_result['expected_source']})"

        print(f"{status_icon} {cat_result['name']} {source}")

        if cat_result['status'] == 'complete' and cat_result['content']:
            # Show preview
            preview = cat_result['content'][:150].replace('\n', ' ')
            if len(cat_result['content']) > 150:
                preview += '...'
            print(f"   {preview}")
        elif cat_result.get('note'):
            print(f"   Note: {cat_result['note']}")

        print()

    # Summary
    print("-" * 60)
    summary = result['summary']
    print(f"Progress: {summary['complete']}/{summary['total']} categories extracted")

    if summary['ready_for_handoff']:
        print("✅ Ready for business-to-code handoff")
    else:
        print("⚠️ Missing categories:")
        for cat in summary['missing_categories']:
            expected = SEVEN_CATEGORIES[cat]['primary_source']
            print(f"   - {cat} (need {expected})")


def main():
    # Parse arguments
    args = sys.argv[1:]
    json_output = '--json' in args
    output_file = None

    for i, arg in enumerate(args):
        if arg == '--output' and i + 1 < len(args):
            output_file = args[i + 1]

    args = [a for a in args if not a.startswith('-') and a != output_file]

    if not args:
        print("Usage: python extract-seven-categories.py <docs/> [--output handoff.md] [--json]")
        sys.exit(1)

    docs_path = Path(args[0])

    if not docs_path.is_dir():
        print(f"Error: Not a directory: {docs_path}")
        sys.exit(1)

    result = extract_seven_categories(docs_path)

    if json_output:
        print(json.dumps(result, indent=2, default=str))
    elif output_file:
        project_name = docs_path.parent.name
        handoff = generate_handoff_markdown(result, project_name)
        output_path = Path(output_file)
        output_path.write_text(handoff)
        print(f"Handoff document written to: {output_path}")
        print()
        print_results(result)
    else:
        print_results(result)

    # Exit with error if not ready for handoff
    sys.exit(0 if result['summary']['ready_for_handoff'] else 1)


if __name__ == '__main__':
    main()
