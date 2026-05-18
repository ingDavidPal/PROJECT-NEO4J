// ============================================================
// EXERCICI 1 - Importació de dades a Neo4j
// Projecte Neo4j: Padrons
// ============================================================
// Nota sobre els fitxers CSV:
//   - HABITATGES.csv : nodes Habitatge
//   - VIU.csv        : relació VIU (Individu -> Habitatge)
//   - FAMILIA.csv    : relació FAMILIA (Individu -> Individu)
//   - SAME_AS.csv    : relació SAME_AS (Individu -> Individu)
//
// Les propietats dels nodes Individu (nom, cognoms, etc.) provenen
// dels fulls de càlcul de Google Sheets referenciats al fitxer
// veure_cypher.txt. Com que els IDs d'individu (IND) ja estan
// presents a VIU.csv i FAMILIA.csv, els nodes Individu es creen
// primer amb l'ID i s'enriqueixen després des dels Sheets.
// ============================================================


// ------------------------------------------------------------
// 1. CONSTRAINTS I ÍNDEXOS
// ------------------------------------------------------------

// Constraint d'unicitat per a Habitatge: clau composta (Municipi, Any_Padro, Id_Llar)
// Garanteix que no es dupliquen habitatges i crea un índex implícit.
CREATE CONSTRAINT habitatge_unique IF NOT EXISTS
  FOR (h:Habitatge)
  REQUIRE (h.Municipi, h.Any_Padro, h.Id_Llar) IS UNIQUE;

// Constraint d'unicitat per a Individu: l'ID és únic globalment.
CREATE CONSTRAINT individu_unique IF NOT EXISTS
  FOR (i:Individu)
  REQUIRE i.Id IS UNIQUE;

// Índex addicional sobre Individu per accelerar cerques per nom/cognoms.
CREATE INDEX individu_nom IF NOT EXISTS FOR (i:Individu) ON (i.name);
CREATE INDEX individu_surname IF NOT EXISTS FOR (i:Individu) ON (i.surname);

// Índex sobre Habitatge per facilitar filtres per municipi i any.
CREATE INDEX habitatge_municipi IF NOT EXISTS FOR (h:Habitatge) ON (h.Municipi);
CREATE INDEX habitatge_any IF NOT EXISTS FOR (h:Habitatge) ON (h.Any_Padro);


// ------------------------------------------------------------
// 2. CÀRREGA DE NODES Habitatge (des de HABITATGES.csv)
// ------------------------------------------------------------
// S'utilitza MERGE per evitar duplicats en executar el script
// diverses vegades. Es filtren les files amb Municipi null.

LOAD CSV WITH HEADERS FROM 'file:///HABITATGES.csv' AS row
WITH row
WHERE row.Municipi IS NOT NULL
  AND row.Id_Llar IS NOT NULL
  AND row.Any_Padro IS NOT NULL
MERGE (h:Habitatge {
  Municipi:  row.Municipi,
  Any_Padro: toInteger(row.Any_Padro),
  Id_Llar:   toInteger(row.Id_Llar)
})
ON CREATE SET
  h.Carrer = row.Carrer,
  h.Numero = CASE WHEN row.Numero IS NOT NULL THEN toFloat(row.Numero) ELSE null END;


// ------------------------------------------------------------
// 3. CÀRREGA DE NODES Individu (des de VIU.csv)
// ------------------------------------------------------------
// L'ID d'individu és l'únic atribut disponible al CSV local.
// Les propietats (nom, cognoms, etc.) s'afegeixen des dels Sheets.

LOAD CSV WITH HEADERS FROM 'file:///VIU.csv' AS row
WITH row
WHERE row.IND IS NOT NULL
MERGE (i:Individu {Id: toInteger(row.IND)});


// També pot haver individus que apareixen a FAMILIA però no a VIU:
LOAD CSV WITH HEADERS FROM 'file:///FAMILIA.csv' AS row
WITH row
WHERE row.ID_1 IS NOT NULL
MERGE (i:Individu {Id: toInteger(row.ID_1)});

LOAD CSV WITH HEADERS FROM 'file:///FAMILIA.csv' AS row
WITH row
WHERE row.ID_2 IS NOT NULL
MERGE (i:Individu {Id: toInteger(row.ID_2)});


// ------------------------------------------------------------
// 4. ENRIQUIMENT DE NODES Individu (des de Google Sheets)
// ------------------------------------------------------------
// Els fulls de Google Sheets contenen: Id, name, surname,
// second_surname, year (any del padró), ocupació, ingressos, estat civil.
// S'utilitza MERGE sobre l'Id i SET per actualitzar propietats.

// --- Full 1: Individus de Castellví de Rosanes (CR) ---
LOAD CSV WITH HEADERS FROM
  'https://docs.google.com/spreadsheets/d/e/2PACX-1vTfU6oJBZhmhzzkV_0-avABPzHTdXy8851ySDbn2gq32WwaNmYxfiBtCGJGOZsMgCWjzlEGX4Zh1wqe/pub?output=csv'
  AS row
WITH row
WHERE row.Id IS NOT NULL
MERGE (i:Individu {Id: toInteger(row.Id)})
ON CREATE SET
  i.name           = toLower(trim(row.name)),
  i.surname        = toLower(trim(row.surname)),
  i.second_surname = toLower(trim(row.second_surname)),
  i.year           = toInteger(row.Year),
  i.ocupacio       = row.ocupacio,
  i.ingressos      = toFloat(row.ingressos),
  i.estat_civil    = row.estat_civil,
  i.Municipi       = row.Location
ON MATCH SET
  i.name           = toLower(trim(row.name)),
  i.surname        = toLower(trim(row.surname)),
  i.second_surname = toLower(trim(row.second_surname)),
  i.year           = toInteger(row.Year),
  i.ocupacio       = row.ocupacio,
  i.ingressos      = toFloat(row.ingressos),
  i.estat_civil    = row.estat_civil,
  i.Municipi       = row.Location;

// --- Full 2: Individus de Sant Feliu de Llobregat (SFLL) ---
LOAD CSV WITH HEADERS FROM
  'https://docs.google.com/spreadsheets/d/e/2PACX-1vT0ZhR6BSO_M72JEmxXKs6GLuOwxm_Oy-0UruLJeX8_R04KAcICuvrwn2OENQhtuvddU5RSJSclHRJf/pub?output=csv'
  AS row
WITH row
WHERE row.Id IS NOT NULL
MERGE (i:Individu {Id: toInteger(row.Id)})
ON CREATE SET
  i.name           = toLower(trim(row.name)),
  i.surname        = toLower(trim(row.surname)),
  i.second_surname = toLower(trim(row.second_surname)),
  i.year           = toInteger(row.Year),
  i.ocupacio       = row.ocupacio,
  i.ingressos      = toFloat(row.ingressos),
  i.estat_civil    = row.estat_civil,
  i.Municipi       = row.Location
ON MATCH SET
  i.name           = toLower(trim(row.name)),
  i.surname        = toLower(trim(row.surname)),
  i.second_surname = toLower(trim(row.second_surname)),
  i.year           = toInteger(row.Year),
  i.ocupacio       = row.ocupacio,
  i.ingressos      = toFloat(row.ingressos),
  i.estat_civil    = row.estat_civil,
  i.Municipi       = row.Location;

// (Repetir el bloc anterior per a cada full addicional de Google Sheets si n'hi ha més)


// ------------------------------------------------------------
// 5. CÀRREGA DE LA RELACIÓ VIU (des de VIU.csv)
// ------------------------------------------------------------
// Relaciona cada Individu amb el seu Habitatge en un any concret.
// La relació porta l'any del padró com a propietat.

LOAD CSV WITH HEADERS FROM 'file:///VIU.csv' AS row
WITH row
WHERE row.IND IS NOT NULL
  AND row.HOUSE_ID IS NOT NULL
  AND row.Location IS NOT NULL
  AND row.Year IS NOT NULL
MATCH (i:Individu {Id: toInteger(row.IND)})
MATCH (h:Habitatge {
  Municipi:  row.Location,
  Any_Padro: toInteger(row.Year),
  Id_Llar:   toInteger(row.HOUSE_ID)
})
MERGE (i)-[r:VIU]->(h)
ON CREATE SET r.Year = toInteger(row.Year);


// ------------------------------------------------------------
// 6. CÀRREGA DE LA RELACIÓ FAMILIA (des de FAMILIA.csv)
// ------------------------------------------------------------
// Relació de parentesc entre individus que conviuen al mateix habitatge.
// Es guarden la relació original i la harmonitzada.

LOAD CSV WITH HEADERS FROM 'file:///FAMILIA.csv' AS row
WITH row
WHERE row.ID_1 IS NOT NULL
  AND row.ID_2 IS NOT NULL
MATCH (i1:Individu {Id: toInteger(row.ID_1)})
MATCH (i2:Individu {Id: toInteger(row.ID_2)})
MERGE (i1)-[r:FAMILIA]->(i2)
ON CREATE SET
  r.relacio             = row.Relacio,
  r.relacio_harmonitzada = row.Relacio_Harmonitzada;


// ------------------------------------------------------------
// 7. CÀRREGA DE LA RELACIÓ SAME_AS (des de SAME_AS.csv)
// ------------------------------------------------------------
// Indica que dos nodes Individu representen la mateixa persona
// al llarg del temps (possiblement amb variacions lèxiques).

LOAD CSV WITH HEADERS FROM 'file:///SAME_AS.csv' AS row
WITH row
WHERE row.Id_A IS NOT NULL
  AND row.Id_B IS NOT NULL
MATCH (a:Individu {Id: toInteger(row.Id_A)})
MATCH (b:Individu {Id: toInteger(row.Id_B)})
MERGE (a)-[:SAME_AS]-(b);
