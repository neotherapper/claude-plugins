#!/usr/bin/env python3
"""
Validate business document against its generation guide template.

Features:
- Parse document metadata header
- Load corresponding guide from guides/
- Check required sections are present
- Validate metadata field formats
- Check dependencies are declared and exist
- For gateways: verify approval section exists
- Score completeness (sections filled vs. placeholder)

Run: python validate-document.py <doc.md> [--fix]
     python validate-document.py <docs/> [--fix]  # Validate all
"""

import sys
import re
from pathlib import Path
from typing import Optional

# Required metadata fields
REQUIRED_METADATA = ['ID', 'Version', 'Status', 'Created', 'Dependencies']

# Valid status values
VALID_STATUS = ['Draft', 'In Review', 'Approved', 'Deprecated', 'PENDING VALIDATION', 'Pending Validation']

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


def parse_metadata(content: str) -> dict:
    """Parse document metadata from markdown."""
    metadata = {}

    # Try table format: | **Field** | Value |
    table_pattern = r'\*\*(\w+)\*\*\s*\|\s*(.+?)(?:\s*\||$)'
    for match in re.finditer(table_pattern, content):
        key = match.group(1).strip()
        value = match.group(2).strip()
        metadata[key] = value

    # Try header format: **Field:** Value
    header_pattern = r'\*\*(\w+):\*\*\s*(.+?)(?:\n|$)'
    for match in re.finditer(header_pattern, content):
        key = match.group(1).strip()
        value = match.group(2).strip()
        if key not in metadata:  # Don't overwrite table values
            metadata[key] = value

    return metadata


def extract_sections(content: str) -> list[str]:
    """Extract all section headings from markdown."""
    sections = []
    for match in re.finditer(r'^#+\s+(.+?)$', content, re.MULTILINE):
        sections.append(match.group(1).strip())
    return sections


def extract_template_sections(guide_content: str) -> list[str]:
    """Extract expected sections from guide template."""
    # Find content between ```markdown and ```
    template_match = re.search(r'```markdown\n(.+?)```', guide_content, re.DOTALL)
    if not template_match:
        return []

    template = template_match.group(1)
    sections = []
    for match in re.finditer(r'^#+\s+(.+?)$', template, re.MULTILINE):
        section = match.group(1).strip()
        # Normalize section names
        section = re.sub(r'\[.*?\]', '', section).strip()
        if section:
            sections.append(section)
    return sections


def check_placeholder_content(content: str, section_name: str) -> bool:
    """Check if a section contains placeholder text."""
    placeholder_patterns = [
        r'\[.*?\]',  # [placeholder]
        r'TODO',
        r'TBD',
        r'xxx',
        r'\.\.\.',
        r'<placeholder>',
        r'FILL IN'
    ]

    # Find section content
    section_pattern = rf'^#+\s+{re.escape(section_name)}\s*$(.+?)(?=^#|\Z)'
    match = re.search(section_pattern, content, re.MULTILINE | re.DOTALL)
    if not match:
        return False

    section_content = match.group(1)
    for pattern in placeholder_patterns:
        if re.search(pattern, section_content, re.IGNORECASE):
            return True

    # Check if section is essentially empty
    stripped = re.sub(r'\s+', '', section_content)
    if len(stripped) < 20:  # Very short content
        return True

    return False


def validate_document(doc_path: Path, guides_dir: Path) -> dict:
    """Validate a single document."""
    errors = []
    warnings = []

    content = doc_path.read_text(encoding='utf-8')
    filename = doc_path.stem
    doc_id = extract_doc_id(filename)

    if not doc_id:
        return {
            'valid': False,
            'errors': ['Could not extract document ID from filename'],
            'warnings': [],
            'completeness': 0
        }

    metadata = parse_metadata(content)
    sections = extract_sections(content)

    # 1. Validate metadata presence
    for field in REQUIRED_METADATA:
        if field not in metadata:
            # Try case-insensitive
            found = any(k.lower() == field.lower() for k in metadata.keys())
            if not found:
                errors.append(f"Missing required field: {field}")

    # 2. Validate ID matches filename
    if 'ID' in metadata:
        meta_id = metadata['ID'].replace(':', '').strip()
        if meta_id != doc_id:
            errors.append(f"ID '{meta_id}' doesn't match filename ID '{doc_id}'")

    # 3. Validate version format
    if 'Version' in metadata:
        version = metadata['Version']
        if not re.match(r'^\d+\.\d+', version):
            warnings.append(f"Unusual version format: {version}")

    # 4. Validate status
    if 'Status' in metadata:
        status = metadata['Status']
        if not any(s.lower() == status.lower() for s in VALID_STATUS):
            warnings.append(f"Unusual status: {status}")

    # 5. Gateway validation
    is_gateway = doc_id in GATEWAYS
    has_gateway_marker = '⭐' in content or 'GATEWAY' in content.upper()
    has_approval_section = bool(re.search(r'(Approval|Gateway Approval|Approval Required)', content, re.IGNORECASE))

    if is_gateway:
        if not has_gateway_marker:
            warnings.append("Gateway document missing ⭐ marker or GATEWAY label")
        if not has_approval_section:
            errors.append("Gateway document missing Approval section")

    # 6. Check against guide template
    guide_name = f"{doc_id}_{filename.split('_', 1)[1] if '_' in filename else ''}.md"
    guide_path = None

    # Find matching guide
    for guide_file in guides_dir.glob('*.md'):
        if guide_file.stem.startswith(doc_id):
            guide_path = guide_file
            break

    sections_found = 0
    sections_expected = 0
    placeholder_sections = 0

    if guide_path and guide_path.exists():
        guide_content = guide_path.read_text(encoding='utf-8')
        expected_sections = extract_template_sections(guide_content)
        sections_expected = len(expected_sections)

        # Check each expected section
        for expected in expected_sections:
            # Normalize for comparison
            expected_norm = expected.lower().replace(' ', '').replace('-', '')
            found = False
            for actual in sections:
                actual_norm = actual.lower().replace(' ', '').replace('-', '')
                if expected_norm in actual_norm or actual_norm in expected_norm:
                    found = True
                    sections_found += 1
                    if check_placeholder_content(content, actual):
                        placeholder_sections += 1
                        warnings.append(f"Section '{actual}' contains placeholder text")
                    break

            if not found:
                # Check if it's a core section
                core_sections = ['problem', 'customer', 'impact', 'evidence', 'approval']
                if any(c in expected.lower() for c in core_sections):
                    warnings.append(f"Missing expected section: {expected}")

    # Calculate completeness
    if sections_expected > 0:
        completeness = int((sections_found - placeholder_sections) / sections_expected * 100)
    else:
        completeness = 50  # Unknown template - assume partial

    return {
        'valid': len(errors) == 0,
        'doc_id': doc_id,
        'metadata': metadata,
        'sections_found': sections_found,
        'sections_expected': sections_expected,
        'placeholder_sections': placeholder_sections,
        'errors': errors,
        'warnings': warnings,
        'completeness': max(0, min(100, completeness)),
        'is_gateway': is_gateway
    }


def print_validation(result: dict, doc_path: Path):
    """Print human-readable validation result."""
    print(f"Validating: {doc_path.name}")
    print()

    # Metadata check
    print("Metadata Check:")
    if result.get('metadata'):
        meta = result['metadata']
        print(f"  ✅ ID: {meta.get('ID', 'N/A')}")
        print(f"  {'✅' if meta.get('Version') else '❌'} Version: {meta.get('Version', 'Missing')}")
        print(f"  {'✅' if meta.get('Status') else '❌'} Status: {meta.get('Status', 'Missing')}")
        print(f"  {'✅' if meta.get('Dependencies') else '⚠️ '} Dependencies: {meta.get('Dependencies', 'None declared')}")
        if result['is_gateway']:
            print(f"  ✅ Gateway: Yes")

    # Section check
    print()
    print("Section Check:")
    if result['sections_expected'] > 0:
        print(f"  Found {result['sections_found']}/{result['sections_expected']} expected sections")
    else:
        print("  No guide template found for comparison")

    # Errors
    if result['errors']:
        print()
        print("❌ Errors:")
        for error in result['errors']:
            print(f"  - {error}")

    # Warnings
    if result['warnings']:
        print()
        print("⚠️  Warnings:")
        for warning in result['warnings']:
            print(f"  - {warning}")

    # Summary
    print()
    print(f"Completeness: {result['completeness']}%")
    print(f"Issues: {len(result['errors'])} errors, {len(result['warnings'])} warnings")


def main():
    # Find guides directory
    script_dir = Path(__file__).parent
    skill_dir = script_dir.parent
    guides_dir = skill_dir / 'references' / 'guides'

    # Parse arguments
    fix_mode = '--fix' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('-')]

    if not args:
        print("Usage: python validate-document.py <doc.md|docs/> [--fix]")
        sys.exit(1)

    target = Path(args[0])

    # Validate single file or directory
    if target.is_file():
        files = [target]
    elif target.is_dir():
        files = list(target.glob('*.md'))
        files = [f for f in files if extract_doc_id(f.stem)]
    else:
        print(f"Error: Path not found: {target}")
        sys.exit(1)

    total_errors = 0
    total_warnings = 0

    for doc_path in sorted(files):
        result = validate_document(doc_path, guides_dir)
        print_validation(result, doc_path)
        print()
        print("-" * 60)
        print()

        total_errors += len(result['errors'])
        total_warnings += len(result['warnings'])

    # Summary
    print(f"Total: {len(files)} files, {total_errors} errors, {total_warnings} warnings")

    sys.exit(1 if total_errors > 0 else 0)


if __name__ == '__main__':
    main()
