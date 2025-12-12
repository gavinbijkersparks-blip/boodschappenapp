# Overzicht van app-features

## Boodschappenlijsten
- Meerdere lijsten aanmaken en beheren vanuit de hoofdnavigatie, inclusief teller voor actieve producten en swipe-to-delete.
- Detailweergave per lijst met scrollbare dagindeling, acties voor toevoegen, favorieten, maaltijden kiezen en barcode scannen.
- Totaalindicatie voor geschatte kosten en mogelijkheid om afgevinkte items te verbergen.

## Productbeheer
- Producten toevoegen met naam, categorie, aantal, favorietstatus, optionele dagplanning en prijsindicatie.
- Producten afvinken, verplaatsen tussen dagen, hoeveelheid aanpassen en verwijderen of deactiveren.
- Ongeplande producten apart tonen en in bulk suggesties opvragen op basis van huidige items.

## Favorieten
- Producten als favoriet markeren en automatisch opslaan in een herbruikbare catalogus.
- Favorieten bewerken of verwijderen en vanuit de catalogus opnieuw toevoegen aan een lijst.

## Maaltijden
- Maaltijdsjablonen aanmaken met naam en bijhorende items, inclusief categorie-suggesties tijdens invoer.
- Bestaande maaltijden bewerken of verwijderen en maaltijden inplannen op een dag in een specifieke lijst.

## Barcode- en productinfo
- Barcodezoekfunctie met caching en fallback op eerder opgehaalde resultaten.
- Demo-barcodeviewer met sluitknop die kan worden vervangen door een echte scanner.

## Slimme suggesties en AI-hulp
- Automatische categorietips op basis van geheugen en een AI-categoriedienst.
- AI-prijsschatting voor producten via een externe endpoint.
- Receptsuggesties per dag op basis van ingeplande ingrediënten en taalspecificatie (NL), met fallbackmock bij API-problemen.

## Persistentie
- Alle lijsten, favorieten, barcodes, maaltijden en categoriegeheugen worden lokaal opgeslagen in een JSON-bestand in de documentenmap.
