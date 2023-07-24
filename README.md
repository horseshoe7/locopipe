# LocoPipe

LocoPipe is a simple tool that you can use to integrate into a simple Localization pipeline.

The idea is that it takes a TSV file with specific column titles, and converts them into Localizable.strings files, set up in the way that Apple likes them (i.e. the <language>.lproj folder structure.)

Basically you have 2 initial columns (Comments, iOS Localization Key), then any subsequent columns are your language codes (e.g. en, de, en_GB, de_AT, etc.)

usage:

`locopipe Localizable -i ./inputFilename.tsv -o ../../Resources/Localization` 

where `Localizable` is the name of the output files (i.e. Localizable.strings) in the language folders

Caveats:
- It is up to you to manage your table that exports the TSV file.  
- We expect there to be a value for each entry, so perhaps highlight your table cells if cells are empty 

Roadmap:
- Set the first language column to be the reference language
- Any missing entries will use the reference value
- Any empty cells in the reference language will omit that key-value pair in ALL languages

