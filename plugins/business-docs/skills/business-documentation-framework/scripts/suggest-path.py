#!/usr/bin/env python3
"""
Recommend documentation path based on project characteristics.

Features:
- Interactive questionnaire (or accept answers as flags)
- Recommend path with rationale
- Show document count and estimated time
- Show what's skipped vs included

Run: python suggest-path.py                    # Interactive mode
     python suggest-path.py --internal         # Internal tool
     python suggest-path.py --external --no-investment --timeline 4weeks
"""

import sys
from typing import Optional

# Path definitions
PATHS = {
    'Internal Tool': {
        'documents': ['IDEA-04', 'IDEA-09', 'IDEA-19', 'PROD-29', 'TECH-02', 'OPS-01'],
        'doc_count': 6,
        'timeline': '2-3 weeks',
        'description': 'Streamlined path for internal tools with known users',
        'skips': ['Customer interviews', 'JTBD analysis', 'Market validation', 'Full PRD', 'MVP Canvas'],
        'includes': ['Problem Statement', 'Lean Canvas (lite)', 'Feasibility', 'One-Pager PRD', 'Technical Design', 'README'],
        'adaptations': [
            'IDEA-04: Informal validation acceptable (no 10+ interviews required)',
            'IDEA-09: Focus on Problem, Solution, Key Metrics, Cost Structure only',
            'IDEA-19: Market Feasibility → "Internal Demand Assessment"'
        ]
    },
    'MVP': {
        'documents': ['IDEA-01', 'IDEA-02', 'IDEA-04', 'IDEA-08', 'IDEA-09', 'IDEA-19',
                      'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'],
        'doc_count': 10,
        'timeline': '8-14 weeks',
        'description': 'Standard path for external products needing market validation',
        'skips': ['Market analysis', 'Investor materials', 'Extensive roadmap'],
        'includes': ['Customer research', 'JTBD', 'Problem Statement', 'Value Prop Canvas', 'Lean Canvas',
                    'Feasibility', 'MVP Canvas', 'Hypothesis Docs', 'Full PRD', 'Technical Design'],
        'adaptations': []
    },
    'Investor': {
        'documents': ['IDEA-01', 'IDEA-02', 'IDEA-04', 'IDEA-05', 'IDEA-06', 'IDEA-08',
                      'IDEA-09', 'IDEA-10', 'IDEA-11', 'IDEA-14', 'IDEA-15', 'IDEA-16',
                      'IDEA-19', 'PROD-17', 'PROD-18', 'PROD-09', 'TECH-02'],
        'doc_count': 17,
        'timeline': '10-16 weeks',
        'description': 'Comprehensive path for external products seeking investment',
        'skips': ['Some operational docs'],
        'includes': ['Full MVP path', 'Mission/Vision', 'Business Model Canvas', 'TAM/SAM/SOM',
                    'Competitive Positioning', 'Why Now', 'Pitch Deck'],
        'adaptations': []
    },
    'Full': {
        'documents': [],  # All 85
        'doc_count': 85,
        'timeline': '16-26 weeks',
        'description': 'Complete documentation for enterprise/regulated environments',
        'skips': [],
        'includes': ['All 85 document types across all phases'],
        'adaptations': []
    }
}

# Decision matrix
DECISION_QUESTIONS = [
    {
        'question': 'Is this an internal tool or external product?',
        'options': [
            ('Internal', 'Tool for your team or company only'),
            ('External', 'Product for external customers/users')
        ],
        'flag': '--internal'
    },
    {
        'question': 'Are you seeking investment?',
        'options': [
            ('Yes', 'Preparing for investor pitch'),
            ('No', 'Self-funded or already funded')
        ],
        'flag': '--investment',
        'condition': 'external'  # Only ask if external
    },
    {
        'question': 'Are you in a regulated industry (healthcare, finance, etc.)?',
        'options': [
            ('Yes', 'Subject to compliance requirements'),
            ('No', 'Standard software product')
        ],
        'flag': '--regulated',
        'condition': 'external'
    },
    {
        'question': 'What\'s your target timeline for first release?',
        'options': [
            ('2-4 weeks', 'MVP as fast as possible'),
            ('1-3 months', 'Standard product development'),
            ('3+ months', 'Thorough planning acceptable')
        ],
        'flag': '--timeline'
    },
    {
        'question': 'Team size?',
        'options': [
            ('1-3', 'Solo or tiny team'),
            ('4-10', 'Small team'),
            ('10+', 'Larger team')
        ],
        'flag': '--team-size'
    }
]


def interactive_mode() -> dict:
    """Run interactive questionnaire."""
    answers = {}

    print("Path Recommendation Questionnaire")
    print("=" * 40)
    print()

    for q in DECISION_QUESTIONS:
        # Check condition
        if 'condition' in q:
            if q['condition'] == 'external' and answers.get('type') == 'Internal':
                continue

        print(q['question'])
        for i, (opt, desc) in enumerate(q['options'], 1):
            print(f"  {i}. {opt} - {desc}")

        while True:
            try:
                choice = input("Enter choice (1-{}): ".format(len(q['options'])))
                idx = int(choice) - 1
                if 0 <= idx < len(q['options']):
                    answers[q['flag'].lstrip('-')] = q['options'][idx][0]
                    if q['flag'] == '--internal':
                        answers['type'] = q['options'][idx][0]
                    break
            except ValueError:
                pass
            print("Invalid choice, try again.")

        print()

    return answers


def recommend_path(answers: dict) -> str:
    """Determine recommended path based on answers."""
    is_internal = answers.get('internal') == 'Internal' or answers.get('type') == 'Internal'
    wants_investment = answers.get('investment') == 'Yes'
    is_regulated = answers.get('regulated') == 'Yes'
    timeline = answers.get('timeline', '1-3 months')
    team_size = answers.get('team_size', '1-3')

    # Decision logic
    if is_internal:
        return 'Internal Tool'
    elif is_regulated:
        return 'Full'
    elif wants_investment:
        return 'Investor'
    elif timeline == '2-4 weeks' or team_size == '1-3':
        return 'Internal Tool'  # Recommend lighter path for fast timelines
    else:
        return 'MVP'


def print_recommendation(path_name: str, answers: dict):
    """Print detailed recommendation."""
    path = PATHS[path_name]

    print("Path Recommendation")
    print("=" * 60)
    print()

    print(f"Based on your inputs:")
    for key, value in answers.items():
        if key != 'type':
            print(f"  - {key.replace('_', ' ').replace('-', ' ').title()}: {value}")
    print()

    print(f"Recommended: **{path_name} Path**")
    print()
    print(f"Documents: {path['doc_count']}")
    print(f"Estimated time: {path['timeline']}")
    print()
    print(f"Description: {path['description']}")
    print()

    # Path sequence
    print("Path Sequence:")
    if path['documents']:
        sequence = ' → '.join(path['documents'][:6])
        if len(path['documents']) > 6:
            sequence += ' → ...'
        print(f"  {sequence}")
    else:
        print("  All 85 documents in dependency order")
    print()

    # What's included
    print("Includes:")
    for item in path['includes']:
        print(f"  ✓ {item}")
    print()

    # What's skipped
    if path['skips']:
        print("Skips:")
        for item in path['skips']:
            print(f"  ✗ {item}")
        print()

    # Adaptations
    if path['adaptations']:
        print("Path Adaptations:")
        for adaptation in path['adaptations']:
            print(f"  • {adaptation}")
        print()

    # Alternative paths
    print("Alternative Paths:")
    for alt_name, alt_path in PATHS.items():
        if alt_name != path_name:
            print(f"  - {alt_name}: {alt_path['doc_count']} docs, {alt_path['timeline']}")


def main():
    args = sys.argv[1:]

    # Check for flag mode
    if any(arg.startswith('--') for arg in args):
        # Parse flags
        answers = {}
        if '--internal' in args:
            answers['internal'] = 'Internal'
            answers['type'] = 'Internal'
        elif '--external' in args:
            answers['type'] = 'External'

        if '--investment' in args:
            answers['investment'] = 'Yes'
        elif '--no-investment' in args:
            answers['investment'] = 'No'

        if '--regulated' in args:
            answers['regulated'] = 'Yes'

        for i, arg in enumerate(args):
            if arg == '--timeline' and i + 1 < len(args):
                answers['timeline'] = args[i + 1]
            if arg == '--team-size' and i + 1 < len(args):
                answers['team_size'] = args[i + 1]

    elif '--help' in args or '-h' in args:
        print("Usage: python suggest-path.py [flags]")
        print()
        print("Interactive mode (no flags):")
        print("  python suggest-path.py")
        print()
        print("Flag mode:")
        print("  --internal          Internal tool (known users)")
        print("  --external          External product")
        print("  --investment        Seeking investment")
        print("  --no-investment     Not seeking investment")
        print("  --regulated         Regulated industry")
        print("  --timeline <X>      2-4 weeks, 1-3 months, or 3+ months")
        print("  --team-size <X>     1-3, 4-10, or 10+")
        print()
        print("Example:")
        print("  python suggest-path.py --internal --timeline 2-4weeks")
        sys.exit(0)
    else:
        # Interactive mode
        try:
            answers = interactive_mode()
        except (EOFError, KeyboardInterrupt):
            print("\nCancelled.")
            sys.exit(0)

    # Get recommendation
    path_name = recommend_path(answers)

    # Print recommendation
    print_recommendation(path_name, answers)


if __name__ == '__main__':
    main()
