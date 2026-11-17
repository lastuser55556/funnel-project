let
    Merged = Table.NestedJoin(leads_raw, {"utm_source"}, sources_lookup, {"source"}, "SourceLookup", JoinKind.LeftOuter),
    Result = Table.ExpandTableColumn(Merged, "SourceLookup", {"source_name","channel_group"}, {"source_name","channel_group"})
in
    Result
