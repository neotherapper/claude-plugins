#!/usr/bin/env python3
"""
Initialize a new project with business documentation structure.

Features:
- Create docs/ directory structure
- Generate .business-docs.yaml configuration
- Optionally create placeholder files for selected path
- Set up recommended folder organization

Run: python init-project.py /path/to/project [--path MVP] [--with-placeholders]
     python init-project.py                    # Interactive mode
"""

import sys
from pathlib import Path
from datetime import datetime

# Path definitions
PATHS = {
    'Internal Tool': {
        'documents': [
            ('IDEA-04', 'Problem_Statement'),
            ('IDEA-09', 'Lean_Canvas'),
            ('IDEA-19', 'Feasibility_Assessment'),
            ('PROD-29', 'One_Pager_PRD'),
            ('TECH-02', 'Technical_Design_Document'),
            ('OPS-01', 'README'),
        ],
        'description': 'Streamlined path for internal tools (6 docs, 2-3 weeks)'
    },
    'MVP': {
        'documents': [
            ('IDEA-01', 'Customer_Interviews'),
            ('IDEA-02', 'JTBD_Analysis'),
            ('IDEA-04', 'Problem_Statement'),
            ('IDEA-08', 'Value_Proposition_Canvas'),
            ('IDEA-09', 'Lean_Canvas'),
            ('IDEA-19', 'Feasibility_Assessment'),
            ('PROD-17', 'MVP_Canvas'),
            ('PROD-18', 'Hypothesis_Documentation'),
            ('PROD-09', 'PRD'),
            ('TECH-02', 'Technical_Design_Document'),
        ],
        'description': 'Standard path for external products (10 docs, 8-14 weeks)'
    },
    'Investor': {
        'documents': [
            ('IDEA-01', 'Customer_Interviews'),
            ('IDEA-02', 'JTBD_Analysis'),
            ('IDEA-04', 'Problem_Statement'),
            ('IDEA-05', 'Mission_Statement'),
            ('IDEA-06', 'Vision_Statement'),
            ('IDEA-08', 'Value_Proposition_Canvas'),
            ('IDEA-09', 'Lean_Canvas'),
            ('IDEA-10', 'Business_Model_Canvas'),
            ('IDEA-11', 'TAM_SAM_SOM_Analysis'),
            ('IDEA-14', 'Competitive_Positioning'),
            ('IDEA-15', 'Why_Now_Analysis'),
            ('IDEA-16', 'Pitch_Deck'),
            ('IDEA-19', 'Feasibility_Assessment'),
            ('PROD-17', 'MVP_Canvas'),
            ('PROD-18', 'Hypothesis_Documentation'),
            ('PROD-09', 'PRD'),
            ('TECH-02', 'Technical_Design_Document'),
        ],
        'description': 'Comprehensive path for fundraising (17 docs, 10-16 weeks)'
    }
}

# Gateway documents
GATEWAYS = ['IDEA-04', 'IDEA-09', 'IDEA-16', 'IDEA-19', 'PROD-09', 'TECH-02']

# Document descriptions for placeholders
DOC_DESCRIPTIONS = {
    'IDEA-01': 'Capture customer insights through structured interviews',
    'IDEA-02': 'Define jobs customers are trying to accomplish',
    'IDEA-04': 'Crystallize the specific problem being solved',
    'IDEA-05': 'Define the organization\'s core purpose',
    'IDEA-06': 'Articulate the long-term aspirational goal',
    'IDEA-08': 'Map customer pains/gains to product features',
    'IDEA-09': 'One-page business model overview',
    'IDEA-10': 'Detailed business model with all components',
    'IDEA-11': 'Market size analysis',
    'IDEA-14': 'Competitive landscape positioning',
    'IDEA-15': 'Why this solution matters now',
    'IDEA-16': 'Investor presentation deck',
    'IDEA-19': 'Technical, market, and resource feasibility',
    'IDEA-20': 'Build vs buy analysis for key components',
    'IDEA-21': 'Cross-domain pattern synthesis for platform initiatives',
    'PROD-09': 'Detailed product requirements',
    'PROD-17': 'Minimum viable product definition',
    'PROD-18': 'Testable hypotheses for validation',
    'PROD-29': 'Lightweight PRD for internal tools',
    'TECH-02': 'Technical architecture and design decisions',
    'OPS-01': 'Project README and setup instructions',
}


def generate_config(project_name: str, path_name: str, docs_dir: str = 'docs') -> str:
    """Generate .business-docs.yaml content."""
    return f"""# Business Documentation Framework Configuration
# Generated: {datetime.now().strftime('%Y-%m-%d')}

project_name: {project_name}
path: {path_name}
docs_path: {docs_dir}

# Optional: Override path detection
# force_path: true

# Optional: Custom document naming
# naming_pattern: "[ID]_[Name].md"
"""


def generate_placeholder(doc_id: str, doc_name: str, path_name: str) -> str:
    """Generate placeholder document content."""
    is_gateway = doc_id in GATEWAYS
    gateway_marker = ' ⭐ GATEWAY' if is_gateway else ''
    description = DOC_DESCRIPTIONS.get(doc_id, 'Document description')

    content = f"""# {doc_id}: {doc_name.replace('_', ' ')}{gateway_marker}

**ID:** {doc_id}
**Version:** 0.1
**Status:** Not Started
**Created:** {datetime.now().strftime('%Y-%m-%d')}
**Dependencies:** [To be filled]
**Gateway:** {'Yes' if is_gateway else 'No'}
**Path:** {path_name}

---

## Purpose

{description}

---

## Content

> This is a placeholder document. Use the Business Documentation Framework skill
> to generate the full content, or refer to the generation guide at:
> `references/guides/{doc_id}_{doc_name}.md` in the business-documentation-framework skill

---

## Next Steps

1. Review the generation guide for this document type
2. Gather required inputs from prerequisite documents
3. Generate or write the document content
4. If gateway document: Complete approval section

"""

    if is_gateway:
        content += """---

## Gateway Approval

| Role | Name | Decision | Date |
|------|------|----------|------|
| [Role] | [Name] | Pending | — |

"""

    return content


def interactive_mode() -> tuple[Path, str, bool]:
    """Run interactive setup."""
    print("Business Documentation Framework - Project Initialization")
    print("=" * 60)
    print()

    # Get project path
    default_path = Path.cwd()
    path_input = input(f"Project path [{default_path}]: ").strip()
    project_path = Path(path_input) if path_input else default_path

    print()
    print("Available paths:")
    for i, (name, info) in enumerate(PATHS.items(), 1):
        print(f"  {i}. {name} - {info['description']}")

    while True:
        try:
            choice = input("\nSelect path (1-3): ").strip()
            idx = int(choice) - 1
            if 0 <= idx < len(PATHS):
                path_name = list(PATHS.keys())[idx]
                break
        except ValueError:
            pass
        print("Invalid choice, try again.")

    print()
    placeholders = input("Create placeholder documents? [y/N]: ").strip().lower() == 'y'

    return project_path, path_name, placeholders


def init_project(project_path: Path, path_name: str, with_placeholders: bool = False) -> dict:
    """Initialize project structure."""
    results = {
        'project_path': str(project_path),
        'path': path_name,
        'created': [],
        'skipped': [],
        'errors': []
    }

    # Ensure project path exists
    if not project_path.exists():
        try:
            project_path.mkdir(parents=True)
            results['created'].append(str(project_path))
        except Exception as e:
            results['errors'].append(f"Could not create project directory: {e}")
            return results

    # Create docs directory
    docs_path = project_path / 'docs'
    if not docs_path.exists():
        docs_path.mkdir()
        results['created'].append('docs/')
    else:
        results['skipped'].append('docs/ (already exists)')

    # Create .business-docs.yaml
    config_path = project_path / '.business-docs.yaml'
    if not config_path.exists():
        project_name = project_path.name
        config_content = generate_config(project_name, path_name)
        config_path.write_text(config_content)
        results['created'].append('.business-docs.yaml')
    else:
        results['skipped'].append('.business-docs.yaml (already exists)')

    # Create placeholder documents if requested
    if with_placeholders:
        path_docs = PATHS.get(path_name, PATHS['MVP'])['documents']

        for doc_id, doc_name in path_docs:
            filename = f"{doc_id}_{doc_name}.md"
            file_path = docs_path / filename

            if not file_path.exists():
                content = generate_placeholder(doc_id, doc_name, path_name)
                file_path.write_text(content)
                results['created'].append(f"docs/{filename}")
            else:
                results['skipped'].append(f"docs/{filename} (already exists)")

    return results


def print_results(results: dict):
    """Print initialization results."""
    print()
    print("Initialization Complete")
    print("=" * 60)
    print()
    print(f"Project: {results['project_path']}")
    print(f"Path: {results['path']}")
    print()

    if results['created']:
        print("✅ Created:")
        for item in results['created']:
            print(f"   {item}")
        print()

    if results['skipped']:
        print("⏭️  Skipped (already exist):")
        for item in results['skipped']:
            print(f"   {item}")
        print()

    if results['errors']:
        print("❌ Errors:")
        for error in results['errors']:
            print(f"   {error}")
        print()

    # Next steps
    print("Next Steps:")
    print("  1. Review .business-docs.yaml configuration")
    print("  2. Run: python check-progress.py docs/")
    print("  3. Start with the first document in your path")
    print()

    path_info = PATHS.get(results['path'], PATHS['MVP'])
    first_doc = path_info['documents'][0]
    print(f"  → First document: {first_doc[0]} {first_doc[1].replace('_', ' ')}")


def main():
    args = sys.argv[1:]

    # Help
    if '--help' in args or '-h' in args:
        print("Usage: python init-project.py [project_path] [options]")
        print()
        print("Options:")
        print("  --path <name>       Set documentation path (Internal Tool, MVP, Investor)")
        print("  --with-placeholders Create placeholder files for all documents in path")
        print("  --json              Output results as JSON")
        print()
        print("Examples:")
        print("  python init-project.py                              # Interactive mode")
        print("  python init-project.py ./my-project --path MVP")
        print("  python init-project.py ./my-project --path 'Internal Tool' --with-placeholders")
        sys.exit(0)

    json_output = '--json' in args
    with_placeholders = '--with-placeholders' in args

    # Parse path option
    path_name = None
    for i, arg in enumerate(args):
        if arg == '--path' and i + 1 < len(args):
            path_name = args[i + 1]

    # Get project path from args
    project_path = None
    for arg in args:
        if not arg.startswith('-') and arg not in PATHS.keys() and arg != path_name:
            project_path = Path(arg)
            break

    # Interactive mode if missing required args
    if project_path is None or path_name is None:
        if sys.stdin.isatty():
            project_path, path_name, with_placeholders = interactive_mode()
        else:
            print("Error: Project path and --path required in non-interactive mode")
            sys.exit(1)

    # Validate path name
    if path_name not in PATHS:
        print(f"Error: Invalid path '{path_name}'. Choose from: {', '.join(PATHS.keys())}")
        sys.exit(1)

    # Run initialization
    results = init_project(project_path, path_name, with_placeholders)

    if json_output:
        import json
        print(json.dumps(results, indent=2))
    else:
        print_results(results)

    sys.exit(0 if not results['errors'] else 1)


if __name__ == '__main__':
    main()
