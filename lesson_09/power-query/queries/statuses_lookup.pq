let
    Csv = Csv.Document(File.Contents(lab_root & "\lookup\statuses_lookup.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Csv, [PromoteAllScalars = true]),
    Typed = Table.TransformColumns(Headers, {
        {"status", each Text.Lower(Text.Trim(_)), type text},
        {"status_order", each Int64.From(_, "en-US"), Int64.Type},
        {"is_final", each Logical.FromText(Text.Lower(Text.Trim(_))), type logical}
    }),
    Keys = Typed[status],
    Result = if List.Contains(Keys, "") or List.Contains(Keys, null) or List.Count(Keys) <> List.Count(List.Distinct(Keys))
             then error "Ключи statuses_lookup должны быть непустыми и уникальными" else Typed
in
    Result
