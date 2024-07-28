-- Ερώτημα 1
-- Create Table basics (tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres)
create table basics
(
	tconst	character varying(20) primary key,
	titleType character varying(20),
	primaryTitle character varying(500),
	originalTitle character varying(500),
	isAdult	character varying(10),
	startYear integer,
	endYear integer,
	runtimeMinutes integer,
	genres character varying(400)
)

--Import basics on PSQL Tool
\copy public.basics (tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres) FROM 'C:/IMDB/basics.tsv' DELIMITER E'\t' NULL '\N' QUOTE E'\b' csv header;

-- Create Table ratings (tconst, averageRating, numVotes)
create table ratings
(
	tconst character varying(20) primary key,
	averageRating float,
	numVotes integer
)

--Import ratings on PSQL Tool
\copy public.ratings (tconst, averagerating, numvotes) FROM 'C:/IMDB/ratings.tsv' DELIMITER E'\t' NULL '\N' QUOTE E'\b' csv header;

-- Create Table namebasics (nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles)
create table namebasics
(
	nconst character varying(20) primary key,
	primaryName	character varying(500),
	birthYear integer,
	deathYear character varying(20),
	primaryProfession character varying(400),
	knownForTitles character varying(500)
)

--Import namebasics on PSQL Tool
\copy public.namebasics (nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles) FROM 'C:/IMDB/namebasics.tsv' DELIMITER E'\t' NULL '\N' QUOTE E'\b' csv header;


--Ερώτημα 2

-- a) Βρείτε τους σκηνοθέτες (δεν πρέπει να συμπεριληφθούν βοηθοί σκηνοθέτη κτλ.) που γεννήθηκαν το 1939 και εκτυπώστε τα ονόματα τους.

select primaryname, birthyear, primaryProfession 
from namebasics 
where birthYear = 1939 and primaryProfession similar to '(director%|%,director%)';

-- b) Βρείτε τις 6 παραγωγές (ταινίες, σειρές, οτιδήποτε) Thriller (το “Thriller” περιέχεται στο genres) που έχουν την μεγαλύτερη βαθμολογία και τουλάχιστον 1 εκ. βαθμολογήσεις. Να εμφανίσετε τον τίτλο και την βαθμολογία τους (όχι αριθμό βαθμολογήσεων) σε φθίνουσα σειρά.

Select primaryTitle, genres, averageRating
from basics 
Natural join ratings
where numvotes >= 1000000 and genres like '%Thriller%'
order by averageRating desc;

-- c) Βρείτε τις 10 μακροβιότερες τηλεοπτικές σειρές (tvSeries) με τουλάχιστον 100 χιλιάδες βαθμολογήσεις και εκτυπώστε τον τίτλο, την “ηλικία” (σε φθίνουσα σειρά) και το αν παίζουν ακόμα

select basics.originalTitle,
case when( cast(basics.startYear as varchar) <>'\N')
	then case when ( cast(basics.endYear as varchar) ='\N' or  basics.endYear is null)
			   then 2021 - basics.startYear
			   else basics.endYear - basics.startYear end end as Series_Years,
	
case when cast(basics.endYear as varchar) ='\N' or basics.endYear is NULL
	then 'Still Play' else 'No Longer Plays' end as Plays
	
from basics, ratings

where basics.titleType like ('%tvSeries%')
and basics.tconst = ratings.tconst
and ratings.numVotes >= 100000
order by Series_Years desc limit 10

-- d) Βρείτε τους ηθοποιούς (ανεξαρτήτως φύλου) με τουλάχιστον 4 παραγωγές για τις οποίες είναι γνωστοί, και να υπολογίσετε τον Μ.Ο βαθμολογιών τους για τις παραγωγές τους που έχουν τουλάχιστον 1.5 εκατομμύρια βαθμολογήσεις.
-- Να εμφανίσετε τα ονόματα, και την μέση βαθμολογία (σε φθίνουσα σειρά) όσων έχουν Μ.Ο πάνω από 9.

select
namebasics.primaryName, 
avg(ratings.averageRating) as MesosOros

from namebasics,ratings

where array_length(string_to_array(namebasics.knownForTitles,','),1) >=4
and (namebasics.primaryProfession like '%actress%' or namebasics.primaryProfession like '%actor%')
and ratings.tconst = any (string_to_array(namebasics.knownForTitles,',')) 
and ratings.numVotes >= 1500000

group by namebasics.primaryName
having avg(ratings.averageRating )>9 
order by MesosOros desc


-- Ερώτημα 3

--α)
create index namebasics_birthyear_index
on namebasics(birthyear);-----Query returned successfully in 4 secs 790 msec.

explain analyze select primaryname, birthyear, primaryProfession 
from namebasics 
where birthYear = 1939 and primaryProfession similar to '(director%|%,director%)';

------ execution time 105.8 ms and scanned 6526 rows

--b
create index ratings_averageRating_index on ratings(averageRating);
create index basics_genres_index on basics(genres);

explain analyze select primaryTitle, genres, averageRating
from basics 
Natural join ratings
where numvotes >= 1000000 and genres like '%Thriller%'
order by averageRating desc;

----execution time 145 ms

--c
create index basics_SeriesYear_index on basics(startYear,endYear);
create index ratings_numVotes_index on ratings(numVotes);

explain analyze select basics.originalTitle,
case when( cast(basics.startYear as varchar) <>'\N')
	then case when ( cast(basics.endYear as varchar) ='\N' or  basics.endYear is null)
			   then 2021 - basics.startYear
			   else basics.endYear - basics.startYear end end as Series_Years,
	
case when cast(basics.endYear as varchar) ='\N' or basics.endYear is NULL
	then 'Still Play' else 'No Longer Plays' end as Plays
	
from basics, ratings

where basics.titleType like ('%tvSeries%')
and basics.tconst = ratings.tconst
and ratings.numVotes >= 100000
order by Series_Years desc limit 10

--d 
create index namebasics_knownForTitles_index on namebasics(knownForTitles);

explain analyze select namebasics.primaryName, avg(ratings.averageRating) as MesosOros

from namebasics,ratings

where array_length(string_to_array(namebasics.knownForTitles,','),1) >=4
and (namebasics.primaryProfession like '%actress%' or namebasics.primaryProfession like '%actor%')
and ratings.tconst = any (string_to_array(namebasics.knownForTitles,',')) 
and ratings.numVotes >= 1500000

group by namebasics.primaryName
having avg(ratings.averageRating )>9 
order by MesosOros desc