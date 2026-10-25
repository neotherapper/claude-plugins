#!/usr/bin/env python3
"""
Check documentation progress against path definitions.

Features:
- Parse all documents in project docs directory
- Match against path definitions from document-registry
- Show completion percentage per path
- Identify next document(s) to create
- Highlight blocked documents (missing prerequisites)
- Show gateway approval status

Run: python check-progress.py [path] [--path MVP|Internal Tool|Investor|Full] [--json]
"""

import sys
import re
import json
from pathlib import Path
from typing import Optional

# ============================================================================
# PATH DEFINITIONS (from document-registry.md)
# ============================================================================

PATHS = {
    'Internal Tool': {
        'sequence': ['IDEA-04', 'IDEA-09', 'IDEA-19', 'PROD-29', 'TECH-02', 'OPS-01'],
        'description': 'Internal tools with known users and tight timelines (6 docs, 2-3 weeks)'
    },
    'MVP': {
        'sequence': ['IDEA-01', 'IDEA-02', 'IDEA-04', 'IDEA-08', 'IDEA-09', 'IDEA-19',
                     'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'],
        'description': 'External product with market validation (10 docs, 8-14 weeks)'
    },
    'Investor': {
        'sequence': ['IDEA-01', 'IDEA-02', 'IDEA-04', 'IDEA-05', 'IDEA-06', 'IDEA-08',
                     'IDEA-09', 'IDEA-10', 'IDEA-11', 'IDEA-14', 'IDEA-15', 'IDEA-16',
                     'IDEA-19', 'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'],
        'description': 'External product seeking funding (17+ docs, 10-16 weeks)'
    },
    'Full': {
        'sequence': [],  # All documents - not tracked as a specific sequence
        'description': 'Enterprise/regulated environments (85 docs, 16-26 weeks)'
    }
}

# Gateway documents that require approval
GATEWAYS = {
    'IDEA-04': 'Problem Statement',
    'IDEA-09': 'Lean Canvas',
    'IDEA-16': 'Pitch Deck',
    'IDEA-19': 'Feasibility Assessment',
    'PROD-01': 'Product Vision',
    'PROD-09': 'PRD',
    'TECH-02': 'Technical Design Document',
    'TECH-05': 'C4 Container Diagram',
    'ML-01': 'Model Card',
    'SEC-01': 'STRIDE Threat Model'
}

# Document names for display
DOCUMENT_NAMES = {
    'IDEA-01': 'Customer Interviews',
    'IDEA-02': 'JTBD Analysis',
    'IDEA-03': '5 Whys Analysis',
    'IDEA-04': 'Problem Statement',
    'IDEA-05': 'Mission Statement',
    'IDEA-06': 'Vision Statement',
    'IDEA-07': 'Company Values',
    'IDEA-08': 'Value Proposition Canvas',
    'IDEA-09': 'Lean Canvas',
    'IDEA-10': 'Business Model Canvas',
    'IDEA-11': 'TAM/SAM/SOM Analysis',
    'IDEA-12': "Porter's Five Forces",
    'IDEA-13': 'PESTEL Analysis',
    'IDEA-14': 'Competitive Positioning',
    'IDEA-15': 'Why Now? Analysis',
    'IDEA-16': 'Pitch Deck',
    'IDEA-17': 'OKRs',
    'IDEA-18': 'Opportunity Solutions Tree',
    'IDEA-19': 'Feasibility Assessment',
    'IDEA-20': 'AI Build vs Buy Decision',
    'IDEA-21': 'Cross-Domain Strategic Synthesis',
    'PROD-01': 'Product Vision',
    'PROD-09': 'PRD',
    'PROD-17': 'MVP Canvas',
    'PROD-18': 'Hypothesis Documentation',
    'PROD-29': 'One-Pager PRD',
    'TECH-02': 'Technical Design Document',
    'OPS-01': 'README'
}

# Dependencies by path (from path-specific rules in registry)
DEPENDENCIES = {
    'Internal Tool': {
        'IDEA-04': [],
        'IDEA-09': ['IDEA-04'],
        'IDEA-19': ['IDEA-09'],
        'PROD-29': ['IDEA-19'],
        'TECH-02': ['PROD-29'],
        'OPS-01': ['TECH-02']
    },
    'MVP': {
        'IDEA-01': [],
        'IDEA-02': ['IDEA-01'],
        'IDEA-04': ['IDEA-02'],
        'IDEA-08': ['IDEA-04'],
        'IDEA-09': ['IDEA-08'],
        'IDEA-19': ['IDEA-09'],
        'PROD-17': ['IDEA-09'],
        'PROD-18': ['PROD-17'],
        'PROD-09': ['IDEA-19', 'PROD-18'],
        'TECH-02': ['PROD-09']
    },
    'Investor': {
        'IDEA-01': [],
        'IDEA-02': ['IDEA-01'],
        'IDEA-04': ['IDEA-02'],
        'IDEA-05': ['IDEA-04'],
        'IDEA-06': ['IDEA-05'],
        'IDEA-08': ['IDEA-04'],
        'IDEA-09': ['IDEA-08'],
        'IDEA-10': ['IDEA-09'],
        'IDEA-11': ['IDEA-09'],
        'IDEA-14': ['IDEA-11'],
        'IDEA-15': ['IDEA-14'],
        'IDEA-16': ['IDEA-10', 'IDEA-15'],
        'IDEA-19': ['IDEA-09'],
        'PROD-17': ['IDEA-09'],
        'PROD-18': ['PROD-17'],
        'PROD-09': ['IDEA-19', 'PROD-18'],
        'TECH-02': ['PROD-09']
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


def parse_document_metadata(content: str) -> dict:
    """Parse document metadata from markdown table or header fields."""
    metadata = {
        'status': None,
        'gateway': False,
        'approved': False,
        'placeholder': False,
        'dependencies': []
    }

    # Check for placeholder markers (from init-project.py)
    if 'This is a placeholder document' in content:
        metadata['placeholder'] = True

    # Check for approval section
    if re.search(r'\bAPPROVED\b', content, re.IGNORECASE):
        metadata['approved'] = True

    # Check for gateway markers
    if '⭐' in content or 'GATEWAY' in content.upper():
        metadata['gateway'] = True

    # Parse status from metadata table
    status_match = re.search(r'\*\*Status\*\*\s*\|\s*(.+?)(?:\s*\||$)', content)
    if status_match:
        metadata['status'] = status_match.group(1).strip()
        # "Not Started" status also indicates placeholder
        if metadata['status'].lower() in ['not started', 'placeholder', 'todo']:
            metadata['placeholder'] = True

    # Parse dependencies
    deps_match = re.search(r'\*\*Dependencies\*\*\s*\|\s*(.+?)(?:\s*\||$)', content)
    if deps_match:
        deps_str = deps_match.group(1).strip()
        # Extract IDEA-XX, PROD-XX style IDs
        metadata['dependencies'] = re.findall(r'[A-Z]+-\d+', deps_str)

    return metadata


def discover_documents(docs_path: Path) -> dict[str, dict]:
    """Discover and parse all business documents."""
    documents = {}

    for file in docs_path.glob('*.md'):
        doc_id = extract_doc_id(file.stem)
        if doc_id:
            content = file.read_text(encoding='utf-8')
            metadata = parse_document_metadata(content)
            metadata['filename'] = file.name
            metadata['path'] = str(file)
            documents[doc_id] = metadata

    return documents


def detect_path(documents: dict[str, dict]) -> str:
    """Detect which path is being followed."""
    doc_ids = set(documents.keys())

    has_prod_29 = 'PROD-29' in doc_ids
    has_prod_09 = 'PROD-09' in doc_ids
    has_idea_01_02 = 'IDEA-01' in doc_ids and 'IDEA-02' in doc_ids
    has_investor_docs = any(d in doc_ids for d in ['IDEA-11', 'IDEA-14', 'IDEA-16'])

    if has_prod_29 and not has_prod_09:
        return 'Internal Tool'
    elif has_investor_docs:
        return 'Investor'
    elif has_idea_01_02:
        return 'MVP'
    elif 'IDEA-04' in doc_ids:
        return 'Internal Tool'
    else:
        return 'MVP'  # Default


def check_progress(docs_path: Path, path_name: Optional[str] = None) -> dict:
    """Check progress against path requirements."""
    documents = discover_documents(docs_path)
    doc_ids = set(documents.keys())

    # Detect or use specified path
    if path_name and path_name in PATHS:
        selected_path = path_name
    else:
        selected_path = detect_path(documents)

    path_def = PATHS.get(selected_path, PATHS['MVP'])
    path_sequence = path_def['sequence']
    path_deps = DEPENDENCIES.get(selected_path, {})

    # Categorize documents
    completed = []
    placeholders = []
    next_up = []
    blocked = []

    # Identify non-placeholder docs for dependency checking
    real_doc_ids = set()
    for doc_id, meta in documents.items():
        if not meta.get('placeholder', False):
            real_doc_ids.add(doc_id)

    for doc_id in path_sequence:
        doc_name = DOCUMENT_NAMES.get(doc_id, doc_id)
        is_gateway = doc_id in GATEWAYS
        deps = path_deps.get(doc_id, [])
        # Check deps against real docs only (not placeholders)
        missing_deps = [d for d in deps if d not in real_doc_ids]

        if doc_id in doc_ids:
            doc_meta = documents[doc_id]
            is_placeholder = doc_meta.get('placeholder', False)

            if is_placeholder:
                # Placeholder file exists but not started
                if missing_deps:
                    blocked.append({
                        'id': doc_id,
                        'name': doc_name,
                        'gateway': is_gateway,
                        'missing_deps': missing_deps,
                        'has_placeholder': True
                    })
                else:
                    placeholders.append({
                        'id': doc_id,
                        'name': doc_name,
                        'gateway': is_gateway,
                        'status': doc_meta.get('status', 'Not Started'),
                        'deps': deps
                    })
            else:
                # Real document with content
                completed.append({
                    'id': doc_id,
                    'name': doc_name,
                    'gateway': is_gateway,
                    'approved': doc_meta.get('approved', False),
                    'status': doc_meta.get('status')
                })
        elif missing_deps:
            blocked.append({
                'id': doc_id,
                'name': doc_name,
                'gateway': is_gateway,
                'missing_deps': missing_deps
            })
        else:
            next_up.append({
                'id': doc_id,
                'name': doc_name,
                'gateway': is_gateway,
                'deps': deps
            })

    # Calculate progress (only count real completed docs, not placeholders)
    if path_sequence:
        required_docs = set(path_sequence)
        completed_doc_ids = set(d['id'] for d in completed)
        completion_pct = len(completed_doc_ids & required_docs) / len(required_docs) * 100
    else:
        # Full path - just count all real docs
        completion_pct = len(real_doc_ids) / 85 * 100  # 85 total documents

    # Find documents outside the selected path (orphans)
    orphans = []
    for doc_id in doc_ids:
        if doc_id not in path_sequence:
            doc_name = DOCUMENT_NAMES.get(doc_id, doc_id)
            orphans.append({
                'id': doc_id,
                'name': doc_name,
                'note': 'Not on selected path'
            })

    return {
        'path': selected_path,
        'path_description': path_def['description'],
        'progress': {
            'completed': len(completed),
            'placeholders': len(placeholders),
            'total': len(path_sequence) if path_sequence else 85,
            'percentage': round(completion_pct, 1)
        },
        'completed': completed,
        'placeholders': placeholders,
        'next_up': next_up,
        'blocked': blocked,
        'orphans': orphans,
        'all_documents': list(doc_ids)
    }


def print_progress(result: dict, docs_path: Path):
    """Print human-readable progress report."""
    print(f"Project: {docs_path.parent.name}")
    print(f"Path: {result['path']} (auto-detected)")

    progress = result['progress']
    placeholder_note = f" (+{progress['placeholders']} placeholders)" if progress.get('placeholders') else ""
    print(f"Progress: {progress['completed']}/{progress['total']} documents ({progress['percentage']}%){placeholder_note}")
    print()

    # Completed
    if result['completed']:
        print("✅ Completed:")
        for doc in result['completed']:
            gateway_mark = ' ⭐' if doc['gateway'] else ''
            approved_mark = ' APPROVED' if doc.get('approved') else ''
            print(f"  {doc['id']} {doc['name']}{gateway_mark}{approved_mark}")
        print()

    # Placeholders (ready to start)
    if result.get('placeholders'):
        print("📝 Ready to Start (placeholder files exist):")
        for doc in result['placeholders']:
            gateway_mark = ' ⭐ (gateway)' if doc['gateway'] else ''
            deps_str = ''
            if doc.get('deps'):
                deps_str = f" — prereqs ready"
            print(f"  → {doc['id']} {doc['name']}{gateway_mark}{deps_str}")
        print()

    # Next up (no file exists)
    if result['next_up']:
        print("⏳ Next Up (no file yet):")
        for doc in result['next_up']:
            gateway_mark = ' ⭐ (gateway)' if doc['gateway'] else ''
            deps_str = ''
            if doc['deps']:
                deps_str = f"\n    Prerequisites: ✅ {', '.join(doc['deps'])}"
            print(f"  → {doc['id']} {doc['name']}{gateway_mark}{deps_str}")
        print()

    # Blocked
    if result['blocked']:
        print("🔒 Blocked:")
        for doc in result['blocked']:
            gateway_mark = ' ⭐' if doc['gateway'] else ''
            missing = ', '.join(doc['missing_deps'])
            placeholder_note = ' (has placeholder)' if doc.get('has_placeholder') else ''
            print(f"  {doc['id']} {doc['name']}{gateway_mark} (needs: {missing}){placeholder_note}")
        print()

    # Orphans (outside path)
    if result['orphans']:
        print("📄 Additional (not on critical path):")
        for doc in result['orphans']:
            print(f"  {doc['id']} {doc['name']}")


def main():
    # Parse arguments
    target_path = Path.cwd()
    path_override = None

    args = sys.argv[1:]
    json_output = '--json' in args or '-j' in args

    for i, arg in enumerate(args):
        if arg == '--path' and i + 1 < len(args):
            path_override = args[i + 1]
        elif not arg.startswith('-') and arg not in ['MVP', 'Internal Tool', 'Investor', 'Full']:
            target_path = Path(arg)

    # Find docs directory (import discover logic)
    if target_path.name == 'docs' and target_path.is_dir():
        docs_path = target_path
    else:
        # Search for docs directory
        # Sibling file is discover-project.py (hyphenated), so load it by path
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "discover_project", Path(__file__).with_name("discover-project.py"))
        discover_project = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(discover_project)
        find_docs_directory = discover_project.find_docs_directory
        find_project_root = discover_project.find_project_root
        project_root = find_project_root(target_path) or target_path
        docs_path = find_docs_directory(project_root)

    if not docs_path or not docs_path.exists():
        print(f"Error: No docs directory found at {target_path}", file=sys.stderr)
        sys.exit(1)

    # Run progress check
    result = check_progress(docs_path, path_override)

    if json_output:
        print(json.dumps(result, indent=2))
    else:
        print_progress(result, docs_path)


if __name__ == '__main__':
    main()
