#!/usr/bin/env python3

"""
This script converts a CMU-flavored ICS calendar to standard ICS format.

For usage, run:
$ python3 convert_cmuics_to_ics.py -h

What is CMU-flavored ICS?
CMU's "ICS" format concatenates everything into a single line. For example:
```
BEGIN:VCALENDAR VERSION:2.0 PRODID:-//hacksw/handcal//NONSGML v1.0//EN BEGIN:VEVENT DTSTART:....
```
CMU's SIO often provides ICS files in this format when exporting a calendar.
Some calendar applications (e.g. Google Calendar) have trouble parsing this format.
Hence, you may want to convert it to standard ICS format.
"""

import argparse
import sys
from typing import List, TYPE_CHECKING

if TYPE_CHECKING:
    from typing import List

# Key words used in ICS VCALENDAR and VEVENT
# https://www.ietf.org/rfc/rfc2445.txt
VCALENDAR_KEYWORDS = [
    "BEGIN:VCALENDAR",
    "END:VCALENDAR",
    "VERSION",
    "PRODID",
    "CALSCALE",
]
VEVENT_KEYWORDS = [
    "BEGIN:VEVENT",
    "END:VEVENT",
    "DTSTAMP",
    "DTSTART",
    "DTEND",
    "SUMMARY",
    "LOCATION",
    "DESCRIPTION",
    "RRULE",
    "UID",
]
KEYWORDS = VCALENDAR_KEYWORDS + VEVENT_KEYWORDS

# Key words that indicate a new line before them
KEYWORDS_NEWLINE = ["BEGIN:VEVENT", "END:VCALENDAR"]


def convert_cmuics_to_ics(lines: List[str]) -> List[str]:
    # CMU's "ICS" format concatenates everything into a single line, so if
    # we see more than one line in the input, it's probably not in CMU's
    # "ICS" format.
    if len(lines) > 1:
        print(
            """warning: Input file has more than one line, so it's
              probably not in CMU's \"ICS\" format. Exiting.""",
            file=sys.stderr,
        )
        exit(1)

    # Initialize the output list
    output: List[str] = []

    # Separate the input line by spaces
    tokens: List[str] = lines[0].split(" ")

    # Scan through the tokens and convert them to standard ICS format
    for token in tokens:
        # If the token is a keyword that requires a newline after it,
        # then add an extra newline
        if any(keyword in token for keyword in KEYWORDS_NEWLINE):
            assert (
                output
            ), "Output is empty, but token is a keyword that requires a newline before it."
            output.append("\n")

        # If the beginning of the token contains a keyword, then it's a new line
        if any(keyword in token for keyword in KEYWORDS):
            # First append a newline to the last line if the output is not empty
            if output:
                output[-1] += "\n"
            # Then append the token to the list as a new line
            output.append(token)
        # Otherwise, append the token to the last line
        else:
            assert output, "Output is empty, but token is not a keyword."
            output[-1] += f" {token}"

    return output


def main():
    # Parse command line arguments
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Convert a CMU-flavored ICS calendar to standard ICS format."
    )
    parser.add_argument("-i", "--input", help="Input file path.", required=True)
    parser.add_argument("-o", "--output", help="Output file path.")
    parser.add_argument(
        "--overwrite",
        help="Overwrite the input file. When this flag is specified the output file path is ignored.",
        action="store_true",
    )
    args: argparse.Namespace = parser.parse_args()
    # Validate command line arguments
    if not args.overwrite and not args.output:
        parser.error("Either --output or --overwrite must be specified.")
    if args.overwrite and args.output:
        print(
            f"{parser.prog}: warning: Ignoring --output because --overwrite is specified.",
            file=sys.stderr,
        )

    # Read the input file
    with open(args.input, "r") as file:
        lines: List[str] = file.readlines()
    print(f"Read {len(lines)} line(s) from {args.input}")

    # Convert the input file to standard ICS format
    standard_lines: List[str] = convert_cmuics_to_ics(lines)
    print(f"Converted {len(lines)} line(s) to {len(standard_lines)} line(s)")

    # Write the output file
    output_path: str = args.input if args.overwrite else args.output
    with open(output_path, "w") as file:
        file.writelines(standard_lines)
    print(f"Wrote {len(standard_lines)} line(s) to {output_path}")

    print("Done!")


if __name__ == "__main__":
    main()
