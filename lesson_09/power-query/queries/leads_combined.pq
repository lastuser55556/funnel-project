let
    Merged = Table.NestedJoin(leads_with_sources, {"status"}, statuses_lookup, {"status"}, "StatusLookup", JoinKind.LeftOuter),
    Result = Table.ExpandTableColumn(Merged, "StatusLookup", {"status_order","is_final"}, {"status_order","is_final"})
in
    Result
