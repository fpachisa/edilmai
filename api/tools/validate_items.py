import argparse
import json
from pathlib import Path
from jsonschema import validate, Draft202012Validator


def main():
    parser = argparse.ArgumentParser(description="Validate Enhanced Item JSON against schema")
    parser.add_argument("file", type=str, help="Path to enhanced item JSON file")
    parser.add_argument("--schema", type=str, default=str(Path(__file__).parents[2] / "schemas" / "enhanced_item_v1.schema.json"))
    args = parser.parse_args()

    schema = json.loads(Path(args.schema).read_text())
    data = json.loads(Path(args.file).read_text())

    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
    if errors:
        print("Validation failed:")
        for e in errors:
            print(f"- {'/'.join(map(str, e.path))}: {e.message}")
        raise SystemExit(1)
    else:
        print("Validation OK")


if __name__ == "__main__":
    main()

