/**
 * When reading data with LOAD DATA, empty or missing columns are updated with ''. 
 * To load a NULL value into a column, use \N in the data file. 
 * The literal word NULL may also be used under some circumstances. 
 * See Section 15.2.9, https://dev.mysql.com/doc/refman/8.4/en/load-data.html.
 */

-- name.basics.tsv.gz - Contains the following information for names:
CREATE TABLE IF NOT EXISTS name_basics (
   nconst VARCHAR(10) PRIMARY KEY,     -- alphanumeric unique identifier of the name/person
   primaryName VARCHAR(255),           -- name by which the person is most often credited
   birthYear VARCHAR(4),               -- in YYYY format
   deathYear VARCHAR(4),               -- in YYYY format if applicable, else '\N'
   primaryProfession VARCHAR(255),     -- the top-3 professions of the person
   knownForTitles VARCHAR(255)         -- titles the person is known for
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- title.basics.tsv.gz - Contains the following information for titles:
CREATE TABLE IF NOT EXISTS title_basics (
   tconst VARCHAR(10) PRIMARY KEY,     -- alphanumeric unique identifier of the title
   titleType VARCHAR(20),              -- the type/format of the title
   primaryTitle VARCHAR(500),          -- the more popular title / the title used by filmmakers on promotional materials at release
   originalTitle VARCHAR(500),         -- original title, in the original language
   isAdult TINYINT(1),                 -- 0: non-adult title; 1: adult title
   startYear VARCHAR(4),               -- represents the release year of a title. In YYYY format
   endYear VARCHAR(4),                 -- TV Series end year. '\N' for all other title types
   runtimeMinutes VARCHAR(10),         -- primary runtime of the title, in minutes
   genres VARCHAR(255)                 -- includes up to three genres associated with the title
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- title.akas.tsv.gz - Contains the following information for titles:
CREATE TABLE IF NOT EXISTS title_akas (
   titleId VARCHAR(10),                -- a tconst, an alphanumeric unique identifier of the title
   ordering INT,                       -- a number to uniquely identify rows for a given titleId
   title VARCHAR(500),                 -- the localized title
   region VARCHAR(4),                  -- the region for this version of the title
   language VARCHAR(4),                -- the language of the title
   types VARCHAR(100),                 -- Enumerated set of attributes for this alternative title
   attributes VARCHAR(255),            -- Additional terms to describe this alternative title
   isOriginalTitle TINYINT(1),         -- 0: not original title; 1: original title
   PRIMARY KEY (titleId, ordering),
   FOREIGN KEY (titleId) REFERENCES title_basics(tconst)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- title.crew.tsv.gz - Contains the director and writer information for all the titles in IMDb
CREATE TABLE IF NOT EXISTS title_crew (
   tconst VARCHAR(10) PRIMARY KEY,     -- alphanumeric unique identifier of the title
   directors TEXT,                     -- director(s) of the given title
   writers TEXT,                       -- writer(s) of the given title
   FOREIGN KEY (tconst) REFERENCES title_basics(tconst)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- title.episode.tsv.gz - Contains the tv episode information. 
CREATE TABLE IF NOT EXISTS title_episode (
   tconst VARCHAR(10),                 -- alphanumeric identifier of episode
   parentTconst VARCHAR(10),           -- alphanumeric identifier of the parent TV Series
   seasonNumber VARCHAR(4),            -- season number the episode belongs to
   episodeNumber VARCHAR(4),           -- episode number of the tconst in the TV series
   PRIMARY KEY (tconst),
   FOREIGN KEY (tconst) REFERENCES title_basics(tconst),
   FOREIGN KEY (parentTconst) REFERENCES title_basics(tconst)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- title.principals.tsv.gz - Contains the principal cast/crew for titles
CREATE TABLE IF NOT EXISTS title_principals (
   tconst VARCHAR(10),                 -- alphanumeric unique identifier of the title
   ordering TINYINT UNSIGNED,          -- a number to uniquely identify rows for a given titleId
   nconst VARCHAR(10),                 -- alphanumeric unique identifier of the name/person
   category VARCHAR(50),               -- the category of job that person was in
   job VARCHAR(255),                   -- the specific job title if applicable, else '\N'
   characters TEXT,                    -- the name of the character played if applicable, else '\N'
   PRIMARY KEY (tconst, ordering),
   FOREIGN KEY (tconst) REFERENCES title_basics(tconst),
   FOREIGN KEY (nconst) REFERENCES name_basics(nconst)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- title.ratings.tsv.gz - Contains the IMDb rating and votes information for titles
CREATE TABLE IF NOT EXISTS title_ratings (
   tconst VARCHAR(10) PRIMARY KEY,     -- alphanumeric unique identifier of the title
   averageRating DECIMAL(3,1),         -- weighted average of all the individual user ratings
   numVotes INT UNSIGNED,              -- number of votes the title has received
   FOREIGN KEY (tconst) REFERENCES title_basics(tconst)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
