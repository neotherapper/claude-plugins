#!/usr/bin/env python3
"""
Validate dependency declarations and detect issues.

Features:
- Build dependency graph from all documents
- Detect circular dependencies
- Find missing prerequisites
- Identify orphan documents (not part of any path)
- Visualize dependency tree (ASCII or Mermaid)
- Path-aware: apply correct dependency rules per path

Run: python check-dependencies.py <docs/> [--path MVP] [--graph mermaid|ascii]
"""

import sys
import re
from pathlib import Path
from typing import Optional
from collections import defaultdict

# Path definitions with dependencies (from document-registry.md)
PATH_DEPENDENCIES = {
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

# Standard dependencies (used for Full path and validation)
STANDARD_DEPENDENCIES = {
    'IDEA-01': [],
    'IDEA-02': ['IDEA-01'],
    'IDEA-03': ['IDEA-01'],
    'IDEA-04': ['IDEA-02'],
    'IDEA-05': ['IDEA-04'],
    'IDEA-06': ['IDEA-05'],
    'IDEA-07': ['IDEA-06'],
    'IDEA-08': ['IDEA-04'],
    'IDEA-09': ['IDEA-08'],
    'IDEA-10': ['IDEA-09'],
    'IDEA-11': ['IDEA-09'],
    'IDEA-12': ['IDEA-11'],
    'IDEA-13': ['IDEA-11'],
    'IDEA-14': ['IDEA-12'],
    'IDEA-15': ['IDEA-14'],
    'IDEA-16': ['IDEA-10', 'IDEA-15'],
    'IDEA-17': ['IDEA-09'],
    'IDEA-18': ['IDEA-09'],
    'IDEA-19': ['IDEA-09'],
    'IDEA-20': ['IDEA-19'],
    'IDEA-21': ['IDEA-03'],  # Cross-Domain Synthesis depends on multiple IDEA-03 analyses
    'PROD-01': ['IDEA-06'],
    'PROD-09': ['IDEA-19', 'PROD-18'],
    'PROD-17': ['IDEA-09'],
    'PROD-18': ['PROD-17'],
    'PROD-29': ['IDEA-19'],
    'TECH-02': ['PROD-09'],
    'OPS-01': ['TECH-02']
}

# Gateway documents
GATEWAYS = ['IDEA-04', 'IDEA-09', 'IDEA-16', 'IDEA-19', 'PROD-01', 'PROD-09',
            'TECH-02', 'TECH-05', 'ML-01', 'SEC-01']


def extract_doc_id(filename: str) -> Optional[str]:
    """Extract document ID from filename."""
    patterns = [r'^(IDEA-\d+)', r'^(PROD-\d+)', r'^(TECH-\d+)', r'^(OPS-\d+)',
                r'^(MKT-\d+)', r'^(FUND-\d+)', r'^(ML-\d+)', r'^(SEC-\d+)']
    for pattern in patterns:
        match = re.match(pattern, filename)
        if match:
            return match.group(1)
    return None


def parse_declared_dependencies(content: str) -> list[str]:
    """Extract declared dependencies from document metadata."""
    deps = []

    # Look for Dependencies field in metadata
    deps_match = re.search(r'\*\*Dependencies\*\*[:\s]*\|?\s*(.+?)(?:\||$|\n)', content)
    if deps_match:
        deps_str = deps_match.group(1)
        # Extract IDEA-XX, PROD-XX style IDs
        deps = re.findall(r'[A-Z]+-\d+', deps_str)

    return deps


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


def find_circular_deps(deps: dict) -> list[list[str]]:
    """Find circular dependencies using DFS."""
    cycles = []
    visited = set()
    rec_stack = []

    def dfs(node: str, path: list):
        if node in rec_stack:
            cycle_start = rec_stack.index(node)
            cycle = rec_stack[cycle_start:] + [node]
            if cycle not in cycles:
                cycles.append(cycle)
            return

        if node in visited:
            return

        visited.add(node)
        rec_stack.append(node)

        for dep in deps.get(node, []):
            dfs(dep, path + [node])

        rec_stack.pop()

    for node in deps:
        visited.clear()
        rec_stack.clear()
        dfs(node, [])

    return cycles


def check_dependencies(docs_path: Path, path_name: Optional[str] = None) -> dict:
    """Check dependency graph for issues."""
    # Discover documents and their declared deps
    documents = {}
    declared_deps = {}

    for file in docs_path.glob('*.md'):
        doc_id = extract_doc_id(file.stem)
        if doc_id:
            content = file.read_text(encoding='utf-8')
            documents[doc_id] = file.name
            declared_deps[doc_id] = parse_declared_dependencies(content)

    doc_ids = set(documents.keys())

    # Detect or use specified path
    if path_name and path_name in PATH_DEPENDENCIES:
        selected_path = path_name
    else:
        selected_path = detect_path(doc_ids)

    expected_deps = PATH_DEPENDENCIES.get(selected_path, STANDARD_DEPENDENCIES)
    path_docs = set(expected_deps.keys())

    # Analysis
    issues = []
    warnings = []

    # 1. Check for circular dependencies
    cycles = find_circular_deps(declared_deps)
    for cycle in cycles:
        issues.append({
            'type': 'circular',
            'description': f"Circular dependency: {' → '.join(cycle)}"
        })

    # 2. Check declared vs expected
    for doc_id, declared in declared_deps.items():
        expected = expected_deps.get(doc_id, STANDARD_DEPENDENCIES.get(doc_id, []))

        # Missing expected deps
        for exp_dep in expected:
            if exp_dep not in declared:
                # Check if it's declared with different formatting
                declared_normalized = [d.replace('_', '-').upper() for d in declared]
                if exp_dep.upper() not in declared_normalized:
                    warnings.append({
                        'type': 'missing_expected',
                        'doc': doc_id,
                        'description': f"{doc_id} missing expected dependency: {exp_dep}"
                    })

        # Undeclared dependencies
        for decl_dep in declared:
            if decl_dep not in expected and decl_dep in doc_ids:
                # Not an issue if doc exists - might be intentional
                pass

    # 3. Check for missing prerequisites
    missing_prereqs = {}
    for doc_id in doc_ids:
        expected = expected_deps.get(doc_id, [])
        missing = [dep for dep in expected if dep not in doc_ids]
        if missing:
            missing_prereqs[doc_id] = missing

    # 4. Find orphan documents (not on path)
    orphans = []
    for doc_id in doc_ids:
        if doc_id not in path_docs:
            orphans.append(doc_id)

    # Build dependency graph for visualization
    graph = {}
    for doc_id in doc_ids:
        deps = expected_deps.get(doc_id, [])
        graph[doc_id] = [d for d in deps if d in doc_ids]

    return {
        'path': selected_path,
        'documents': list(doc_ids),
        'graph': graph,
        'issues': issues,
        'warnings': warnings,
        'missing_prerequisites': missing_prereqs,
        'orphans': orphans,
        'valid': len(issues) == 0
    }


def generate_mermaid(graph: dict, gateways: list) -> str:
    """Generate Mermaid diagram of dependency graph."""
    lines = ['graph TD']

    # Add nodes with gateway styling
    for doc_id in sorted(graph.keys()):
        if doc_id in GATEWAYS:
            lines.append(f'    {doc_id}["{doc_id}⭐"]')
        else:
            lines.append(f'    {doc_id}["{doc_id}"]')

    # Add edges
    for doc_id, deps in sorted(graph.items()):
        for dep in deps:
            lines.append(f'    {dep} --> {doc_id}')

    # Gateway styling
    gateway_nodes = [d for d in graph.keys() if d in GATEWAYS]
    if gateway_nodes:
        lines.append(f'    classDef gateway fill:#f9f,stroke:#333,stroke-width:2px')
        lines.append(f'    class {",".join(gateway_nodes)} gateway')

    return '\n'.join(lines)


def generate_ascii_graph(graph: dict, path: str) -> str:
    """Generate ASCII representation of dependency graph."""
    # Simplified ASCII representation for common paths
    if path == 'MVP':
        return """
IDEA-01 → IDEA-02 → IDEA-04⭐ → IDEA-08 → IDEA-09⭐
                                              ↓
                              PROD-17 → PROD-18 → ─┐
                                                  │
                              IDEA-19⭐ ──────────┼→ PROD-09⭐ → TECH-02⭐
"""
    elif path == 'Internal Tool':
        return """
IDEA-04⭐ → IDEA-09 → IDEA-19⭐ → PROD-29 → TECH-02⭐ → OPS-01
"""
    else:
        # Generic graph
        lines = []
        for doc_id in sorted(graph.keys()):
            deps = graph[doc_id]
            gateway = '⭐' if doc_id in GATEWAYS else ''
            if deps:
                lines.append(f"{', '.join(deps)} → {doc_id}{gateway}")
            else:
                lines.append(f"(start) → {doc_id}{gateway}")
        return '\n'.join(lines)


def print_results(result: dict, graph_type: Optional[str] = None):
    """Print human-readable results."""
    print(f"Dependency Analysis")
    print(f"Path: {result['path']}")
    print()

    # Graph visualization
    if graph_type == 'mermaid':
        print("```mermaid")
        print(generate_mermaid(result['graph'], GATEWAYS))
        print("```")
    else:
        print("Graph:")
        print(generate_ascii_graph(result['graph'], result['path']))

    print()

    # Validation results
    print("Validation:")
    if result['valid']:
        print("  ✅ No circular dependencies")
    else:
        for issue in result['issues']:
            print(f"  ❌ {issue['description']}")

    if result['missing_prerequisites']:
        print()
        print("Missing Prerequisites:")
        for doc_id, missing in result['missing_prerequisites'].items():
            print(f"  {doc_id} needs: {', '.join(missing)}")

    if result['orphans']:
        print()
        print(f"⚠️  Documents not on {result['path']} path:")
        for orphan in result['orphans']:
            print(f"  - {orphan}")

    if result['warnings']:
        print()
        print("Warnings:")
        for w in result['warnings']:
            print(f"  ⚠️  {w['description']}")


def main():
    # Parse arguments
    args = sys.argv[1:]
    graph_type = None
    path_override = None

    for i, arg in enumerate(args):
        if arg == '--graph' and i + 1 < len(args):
            graph_type = args[i + 1]
        elif arg == '--path' and i + 1 < len(args):
            path_override = args[i + 1]

    json_output = '--json' in args
    args = [a for a in args if not a.startswith('-') and a not in ['mermaid', 'ascii', 'MVP', 'Internal Tool', 'Investor', 'Full']]

    if not args:
        print("Usage: python check-dependencies.py <docs/> [--path MVP] [--graph mermaid|ascii]")
        sys.exit(1)

    docs_path = Path(args[0])

    if not docs_path.is_dir():
        print(f"Error: Not a directory: {docs_path}")
        sys.exit(1)

    result = check_dependencies(docs_path, path_override)

    if json_output:
        import json
        print(json.dumps(result, indent=2))
    else:
        print_results(result, graph_type)

    sys.exit(0 if result['valid'] else 1)


if __name__ == '__main__':
    main()
