let
    ExpectedHeaders = {"request_id","created_at","name","direction","utm_source","utm_medium","utm_campaign","status"},
    FolderSource = Folder.Contents(lab_root & "\incoming"),
    Eligible = Table.SelectRows(FolderSource, each [Extension] <> null and Text.Lower([Extension]) = ".csv" and Text.StartsWith([Name], "leads_")),
    ParseCSV = (file as binary, name as text) as table =>
        let
            Parsed = Csv.Document(file, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
            Promoted = Table.PromoteHeaders(Parsed, [PromoteAllScalars = true]),
            Checked = if Table.ColumnNames(Promoted) = ExpectedHeaders then Promoted
                      else error Error.Record("Структура CSV", "Неожиданные заголовки", name),
            Tagged = Table.AddColumn(Checked, "Source.Name", each name, type text)
        in
            Tagged,
    Parts = Table.AddColumn(Eligible, "Rows", each ParseCSV([Content], [Name]), type table),
    Combined = if Table.IsEmpty(Parts) then error "В incoming нет подходящих CSV" else Table.Combine(Parts[Rows]),
    WithTypes = Table.TransformColumns(Combined, {
        {"created_at", each DateTime.FromText(_, [Format = "yyyy-MM-dd HH:mm:ss", Culture = "en-US"]), type datetime},
        {"utm_source", each Text.Lower(Text.Trim(_)), type text},
        {"status", each Text.Lower(Text.Trim(_)), type text}
    }),
    TextColumns = Table.TransformColumnTypes(WithTypes, List.Transform({"request_id","name","direction","utm_medium","utm_campaign"}, each {_, type text})),
    Ordered = Table.ReorderColumns(TextColumns, {"Source.Name"} & ExpectedHeaders)
in
    Ordered
