#!/usr/bin/env python3
"""
Discover business documentation location for a project.

Features:
- Search for docs/ or documentation/ directories containing IDEA-* or PROD-* files
- Detect project root via .git, package.json, pyproject.toml, etc.
- Support explicit configuration via .business-docs.yaml in project root
- Output project context as JSON for other scripts

Run from project root: python discover-project.py [path]
"""

import sys
import json
import re
from pathlib import Path
from typing import Optional

# Project root markers
PROJECT_MARKERS = ['.git', 'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'pom.xml']

# Common docs directory names
DOCS_DIRS = ['docs', 'documentation', 'doc', 'business-docs']

# Business document patterns
BUSINESS_DOC_PATTERNS = [
    r'^IDEA-\d+',
    r'^PROD-\d+',
    r'^TECH-\d+',
    r'^OPS-\d+',
    r'^MKT-\d+',
    r'^FUND-\d+',
    r'^ML-\d+',
    r'^SEC-\d+'
]

# Path definitions (from document-registry.md)
PATH_DEFINITIONS = {
    'Internal Tool': {
        'required': ['IDEA-04', 'IDEA-09', 'IDEA-19', 'PROD-29', 'TECH-02', 'OPS-01'],
        'doc_count': 6
    },
    'MVP': {
        'required': ['IDEA-01', 'IDEA-02', 'IDEA-04', 'IDEA-08', 'IDEA-09', 'IDEA-19',
                     'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'],
        'doc_count': 10
    },
    'Investor': {
        'required': ['IDEA-01', 'IDEA-02', 'IDEA-04', 'IDEA-05', 'IDEA-06', 'IDEA-08',
                     'IDEA-09', 'IDEA-10', 'IDEA-11', 'IDEA-14', 'IDEA-15', 'IDEA-16',
                     'IDEA-19', 'IDEA-20', 'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'],
        'doc_count': 18
    },
    'Full': {
        'required': [],  # All 85 documents
        'doc_count': 85
    }
}


def parse_yaml_config(content: str) -> dict:
    """Simple YAML parsing for .business-docs.yaml (no external deps)."""
    config = {}
    for line in content.strip().split('\n'):
        if ':' in line and not line.startswith('#'):
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if value:
                config[key] = value
    return config


def find_project_root(start_path: Path) -> Optional[Path]:
    """Find project root by looking for marker files."""
    current = start_path.resolve()
    while current != current.parent:
        for marker in PROJECT_MARKERS:
            if (current / marker).exists():
                return current
        current = current.parent
    return None


def find_docs_directory(project_root: Path) -> Optional[Path]:
    """Find docs directory containing business documents."""
    # Check explicit config first
    config_path = project_root / '.business-docs.yaml'
    if config_path.exists():
        config = parse_yaml_config(config_path.read_text())
        if 'docs_path' in config:
            docs_path = project_root / config['docs_path']
            if docs_path.exists():
                return docs_path

    # Search common locations
    for docs_name in DOCS_DIRS:
        docs_path = project_root / docs_name
        if docs_path.is_dir():
            # Check if it contains business documents
            if has_business_documents(docs_path):
                return docs_path

    # Search one level deep in projects/
    projects_dir = project_root / 'projects'
    if projects_dir.is_dir():
        for project_subdir in projects_dir.iterdir():
            if project_subdir.is_dir():
                for docs_name in DOCS_DIRS:
                    docs_path = project_subdir / docs_name
                    if docs_path.is_dir() and has_business_documents(docs_path):
                        return docs_path

    return None


def has_business_documents(docs_path: Path) -> bool:
    """Check if directory contains business documents."""
    for file in docs_path.glob('*.md'):
        for pattern in BUSINESS_DOC_PATTERNS:
            if re.match(pattern, file.stem):
                return True
    return False


def extract_doc_id(filename: str) -> Optional[str]:
    """Extract document ID from filename (e.g., 'IDEA-04' from 'IDEA-04_Problem_Statement.md')."""
    for pattern in BUSINESS_DOC_PATTERNS:
        match = re.match(pattern, filename)
        if match:
            return match.group(0)
    return None


def discover_documents(docs_path: Path) -> list[str]:
    """Find all business documents in a directory."""
    documents = []
    for file in docs_path.glob('*.md'):
        doc_id = extract_doc_id(file.stem)
        if doc_id:
            documents.append(file.name)
    return sorted(documents)


def detect_path(documents: list[str]) -> str:
    """Detect which documentation path is being followed based on existing documents."""
    doc_ids = set()
    for doc in documents:
        doc_id = extract_doc_id(doc)
        if doc_id:
            doc_ids.add(doc_id)

    # Check for path indicators
    has_prod_29 = 'PROD-29' in doc_ids
    has_prod_09 = 'PROD-09' in doc_ids
    has_idea_01_02 = 'IDEA-01' in doc_ids and 'IDEA-02' in doc_ids
    has_investor_docs = any(d in doc_ids for d in ['IDEA-11', 'IDEA-14', 'IDEA-16'])

    # Detection logic
    if has_prod_29 and not has_prod_09:
        return 'Internal Tool'
    elif has_investor_docs:
        return 'Investor'
    elif has_idea_01_02 and has_prod_09:
        return 'MVP'
    elif len(doc_ids) > 20:
        return 'Full'
    elif has_idea_01_02:
        return 'MVP'
    elif 'IDEA-04' in doc_ids:
        return 'Internal Tool'
    else:
        return 'Unknown'


def discover_project(path: Path) -> dict:
    """Main discovery function. Returns project context as dict."""
    # Find project root
    project_root = find_project_root(path)
    if not project_root:
        project_root = path.resolve()

    # Check for explicit config
    config_path = project_root / '.business-docs.yaml'
    config_source = 'auto-detected'
    explicit_path = None

    if config_path.exists():
        config = parse_yaml_config(config_path.read_text())
        config_source = '.business-docs.yaml'
        explicit_path = config.get('path')

    # Find docs directory
    docs_path = find_docs_directory(project_root)

    if not docs_path:
        return {
            'project_root': str(project_root),
            'docs_path': None,
            'documents_found': [],
            'detected_path': 'Unknown',
            'config_source': config_source,
            'error': 'No docs directory found with business documents'
        }

    # Discover documents
    documents = discover_documents(docs_path)

    # Detect or use explicit path
    detected_path = explicit_path or detect_path(documents)

    return {
        'project_root': str(project_root),
        'docs_path': str(docs_path),
        'documents_found': documents,
        'document_count': len(documents),
        'detected_path': detected_path,
        'config_source': config_source
    }


def main():
    # Parse arguments
    if len(sys.argv) > 1:
        target_path = Path(sys.argv[1])
    else:
        target_path = Path.cwd()

    if not target_path.exists():
        print(f"Error: Path not found: {target_path}", file=sys.stderr)
        sys.exit(1)

    # Run discovery
    result = discover_project(target_path)

    # Output format based on flags
    if '--json' in sys.argv or '-j' in sys.argv:
        print(json.dumps(result, indent=2))
    else:
        # Human-readable output
        print(f"Project Root: {result['project_root']}")
        print(f"Docs Path:    {result.get('docs_path', 'Not found')}")
        print(f"Config:       {result['config_source']}")
        print(f"Path:         {result['detected_path']}")

        if result.get('error'):
            print(f"\n⚠️  {result['error']}")
        elif result.get('documents_found'):
            print(f"\nDocuments Found ({result['document_count']}):")
            for doc in result['documents_found']:
                print(f"  - {doc}")

    # Exit with error if no docs found
    sys.exit(0 if result.get('docs_path') else 1)


if __name__ == '__main__':
    main()
