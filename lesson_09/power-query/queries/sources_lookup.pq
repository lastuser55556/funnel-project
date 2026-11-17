let
    Csv = Csv.Document(File.Contents(lab_root & "\lookup\sources_lookup.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Csv, [PromoteAllScalars = true]),
    Typed = Table.TransformColumnTypes(Headers, {{"source",type text},{"source_name",type text},{"channel_group",type text}}),
    Normalized = Table.TransformColumns(Typed, {{"source", each Text.Lower(Text.Trim(_)), type text}}),
    Keys = Normalized[source],
    Result = if List.Contains(Keys, "") or List.Contains(Keys, null) or List.Count(Keys) <> List.Count(List.Distinct(Keys))
             then error "Ключи sources_lookup должны быть непустыми и уникальными" else Normalized
in
    Result
