-- Table: public.ip_metadata

CREATE TABLE IF NOT EXISTS public.ip_metadata (
    ip_addr VARCHAR(45) PRIMARY KEY,
    status VARCHAR(10) NOT NULL,
    continent_code VARCHAR(5),
    country_code CHAR(2),
    region_name VARCHAR(100),
    city VARCHAR(100),
    zip VARCHAR(20),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    timezone VARCHAR(50),
    isp VARCHAR(150),
    org VARCHAR(150),
    asn VARCHAR(50),
    asname VARCHAR(150),
    mobile BOOLEAN,
    proxy BOOLEAN,
    hosting BOOLEAN
);


-- Table: public.spotify_data

CREATE TABLE IF NOT EXISTS public.spotify_data (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    timestamp_column TIMESTAMPTZ,
    platform VARCHAR(100),
    ms_played INTEGER,
    conn_country VARCHAR(2),
    ip_addr VARCHAR(50),
    track_name VARCHAR(300),
    artist_name VARCHAR(300),
    album_name VARCHAR(300),
    spotify_track_uri VARCHAR(50),
    episode_name VARCHAR(150),
    episode_show_name VARCHAR(100),
    spotify_episode_uri VARCHAR(50),
    audiobook_title VARCHAR(100),
    audiobook_uri VARCHAR(50),
    audiobook_chapter_uri VARCHAR(50),
    audiobook_chapter_title VARCHAR(100),
    reason_start VARCHAR(30),
    reason_end VARCHAR(30),
    shuffle BOOLEAN DEFAULT FALSE,
    skipped BOOLEAN DEFAULT FALSE,
    offline BOOLEAN DEFAULT FALSE,
    offline_timestamp TIMESTAMPTZ,
    incognito_mode BOOLEAN DEFAULT FALSE,
    time_of_day TEXT,
    season TEXT,
    year_played INTEGER,
    CONSTRAINT fk_ip_reference FOREIGN KEY (ip_addr)
        REFERENCES public.ip_metadata (ip_addr)
);


-- Table: public.artists

CREATE TABLE IF NOT EXISTS public.artists (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_name VARCHAR(300),
    genres TEXT[],
    last_updated TIMESTAMPTZ DEFAULT now()
);


CREATE TABLE IF NOT EXISTS public.sd_artists_join (
    artist_name TEXT COLLATE pg_catalog."default",
    sd_id INTEGER NOT NULL,
    artist_id INTEGER NOT NULL,
    CONSTRAINT sd_artist_key PRIMARY KEY (sd_id, artist_id),
    CONSTRAINT sd_artists_join_artist_id_fkey FOREIGN KEY (artist_id)
        REFERENCES public.artists (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT sd_artists_join_sd_id_fkey FOREIGN KEY (sd_id)
        REFERENCES public.spotify_data (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);


-- Indexes for ip_metadata
CREATE INDEX IF NOT EXISTS idx_ip_metadata_asn
    ON public.ip_metadata USING btree
    (asn COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_ip_metadata_city
    ON public.ip_metadata USING btree
    (city COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_ip_metadata_country_code
    ON public.ip_metadata USING btree
    (country_code COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_ip_metadata_isp
    ON public.ip_metadata USING btree
    (isp COLLATE pg_catalog."default" ASC NULLS LAST);


-- Indexes for spotify_data
CREATE INDEX IF NOT EXISTS album_name_idx
    ON public.spotify_data USING btree
    (album_name COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS artist_name_idx
    ON public.spotify_data USING btree
    (artist_name COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS spotify_data_ts_idx
    ON public.spotify_data USING btree
    (timestamp_column ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS spotify_data_year_idx
    ON public.spotify_data USING btree
    (year_played ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS track_name_idx
    ON public.spotify_data USING btree
    (track_name COLLATE pg_catalog."default" ASC NULLS LAST);


-- Indexes for artists
CREATE INDEX IF NOT EXISTS artist_idx
    ON public.artists USING btree
    (id ASC NULLS LAST);


-- Indexes for sd_artists_join
CREATE INDEX IF NOT EXISTS sd_artists_join_artist_idx
    ON public.sd_artists_join USING btree
    (artist_id ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS sd_artists_join_name_idx
    ON public.sd_artists_join USING btree
    (artist_name COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS sd_artists_join_sd_idx
    ON public.sd_artists_join USING btree
    (sd_id ASC NULLS LAST);

-- Confirm all indexes
SELECT *
FROM pg_indexes;


-- Trigger for spotify_data: Automatically populate year_played from timestamp_column
CREATE OR REPLACE FUNCTION update_year_played()
RETURNS TRIGGER AS $$
BEGIN
  NEW.year_played := EXTRACT(YEAR FROM NEW.timestamp_column)::INTEGER;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_year_played
    BEFORE INSERT OR UPDATE 
    ON public.spotify_data
    FOR EACH ROW
    EXECUTE FUNCTION public.update_year_played();


-- Trigger for artists: Automatically update last_updated timestamp
CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_last_updated_timestamp
    BEFORE UPDATE 
    ON public.artists
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_updated_column();


-- Ownership
ALTER TABLE IF EXISTS public.ip_metadata
    OWNER TO postgres;

ALTER TABLE IF EXISTS public.spotify_data
    OWNER TO postgres;

ALTER TABLE IF EXISTS public.artists
    OWNER TO postgres;

ALTER TABLE IF EXISTS public.sd_artists_join
    OWNER TO postgres;


-- Grant full access to postgres on all tables
GRANT ALL ON TABLE public.ip_metadata TO postgres;
GRANT ALL ON TABLE public.spotify_data TO postgres;
GRANT ALL ON TABLE public.artists TO postgres;
GRANT ALL ON TABLE public.sd_artists_join TO postgres;


-- Create role for user. Will fail if user already exists
CREATE ROLE spotify_postgres_user WITH
  LOGIN
  PASSWORD '<db_password>';



-- Grant appropriate user-level privileges to spotify_postgres_user
GRANT ALL ON TABLE public.ip_metadata TO spotify_postgres_user;
GRANT ALL ON TABLE public.spotify_data TO spotify_postgres_user;
GRANT ALL ON TABLE public.artists TO spotify_postgres_user;
GRANT ALL ON TABLE public.sd_artists_join TO spotify_postgres_user;

-- Example of revoking  unnecessary access
--REVOKE ALL ON TABLE public.ip_metadata FROM spotify_postgres_user;
