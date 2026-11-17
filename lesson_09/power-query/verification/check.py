import csv
from datetime import datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


def index(rows, column):
    result = {}
    for row in rows:
        key = row[column].strip().lower()
        if not key or key in result:
            raise ValueError(f"Пустой или повторный ключ: {key}")
        result[key] = row
    return result


def inspect(files, sources, statuses):
    rows = []
    missing = []
    for file in sorted(files):
        for row in read(file):
            datetime.strptime(row["created_at"], "%Y-%m-%d %H:%M:%S")
            source = sources.get(row["utm_source"].strip().lower())
            status = statuses[row["status"].strip().lower()]
            row = {"Source.Name": file.name, **row}
            if source is None:
                missing.append(row.copy())
                source = {"source_name": "", "channel_group": ""}
            row.update(source_name=source["source_name"], channel_group=source["channel_group"],
                       status_order=status["status_order"], is_final=status["is_final"])
            rows.append(row)
    return rows, missing


def write(path, rows):
    with path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    base = sorted((root / "incoming").glob("leads_*.csv"))
    later = sorted((root / "later").glob("leads_*.csv"))
    sources = index(read(root / "lookup" / "sources_lookup.csv"), "source")
    statuses = index(read(root / "lookup" / "statuses_lookup.csv"), "status")
    updated = {**sources, "tiktok": {"source_name": "TikTok", "channel_group": "social"}}
    cases = (
        (base, sources, 9, ["REQ-108"]),
        (base + later[:1], sources, 12, ["REQ-108"]),
        (base + later[:1], updated, 12, []),
        (base + later[:2], updated, 13, []),
        (base + later, updated, 14, ["REQ-121"]),
    )
    for files, refs, expected, ids in cases:
        combined, missing = inspect(files, refs, statuses)
        assert len(combined) == expected and all(len(row) == 13 for row in combined)
        assert [r["request_id"] for r in missing] == ids
        assert len({r["request_id"] for r in combined}) == expected
        print(f"{len(files)} файлов | {len(combined)} записей | без пары: {', '.join(ids) or '—'}")
    by_id = {row["request_id"]: row for row in combined}
    assert by_id["REQ-108"]["source_name"] == "TikTok"
    assert by_id["REQ-120"]["source_name"] == "Email"
    assert by_id["REQ-120"]["status_order"] == "2"
    assert by_id["REQ-121"]["source_name"] == ""
    assert by_id["REQ-121"]["is_final"] == "false"
    write(root / "verification" / "expected_leads_combined.csv", combined)
    write(root / "verification" / "expected_unmatched_sources.csv", missing)
