let
    Missing = Table.NestedJoin(leads_raw, {"utm_source"}, sources_lookup, {"source"}, "SourceLookup", JoinKind.LeftAnti),
    Result = Table.RemoveColumns(Missing, {"SourceLookup"})
in
    Result
