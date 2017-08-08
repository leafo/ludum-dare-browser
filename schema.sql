--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: collection_games; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE collection_games (
    name character varying(255) NOT NULL,
    event_id integer NOT NULL,
    game_id integer NOT NULL
);


ALTER TABLE collection_games OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE events (
    id integer NOT NULL,
    slug character varying(255),
    type smallint NOT NULL,
    key character varying(255),
    name text NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    games_count integer,
    last_refreshed_at timestamp without time zone
);


ALTER TABLE events OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE events_id_seq OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: game_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE game_data (
    game_id integer NOT NULL,
    data json
);


ALTER TABLE game_data OWNER TO postgres;

--
-- Name: game_data_game_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE game_data_game_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE game_data_game_id_seq OWNER TO postgres;

--
-- Name: game_data_game_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE game_data_game_id_seq OWNED BY game_data.game_id;


--
-- Name: games; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE games (
    id integer NOT NULL,
    comp character varying(255),
    uid character varying(255) NOT NULL,
    "user" text NOT NULL,
    url character varying(255) NOT NULL,
    title text NOT NULL,
    downloads json,
    num_downloads integer DEFAULT 0 NOT NULL,
    screenshots json,
    num_screenshots integer DEFAULT 0 NOT NULL,
    votes_received integer DEFAULT 0 NOT NULL,
    votes_given integer DEFAULT 0 NOT NULL,
    is_jam boolean,
    have_details boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    event_id integer,
    user_url character varying(255)
);


ALTER TABLE games OWNER TO postgres;

--
-- Name: games_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE games_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE games_id_seq OWNER TO postgres;

--
-- Name: games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE games_id_seq OWNED BY games.id;


--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE lapis_migrations OWNER TO postgres;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: game_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY game_data ALTER COLUMN game_id SET DEFAULT nextval('game_data_game_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY games ALTER COLUMN id SET DEFAULT nextval('games_id_seq'::regclass);


--
-- Name: collection_games_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY collection_games
    ADD CONSTRAINT collection_games_pkey PRIMARY KEY (name, game_id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: game_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY game_data
    ADD CONSTRAINT game_data_pkey PRIMARY KEY (game_id);


--
-- Name: games_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: collection_games_event_id_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collection_games_event_id_name_idx ON collection_games USING btree (event_id, name);


--
-- Name: collection_games_game_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collection_games_game_id_idx ON collection_games USING btree (game_id);


--
-- Name: events_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX events_slug_idx ON events USING btree (slug);


--
-- Name: games_comp_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_comp_title_idx ON games USING btree (comp, title);


--
-- Name: games_comp_uid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX games_comp_uid_idx ON games USING btree (comp, uid);


--
-- Name: games_event_id_uid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX games_event_id_uid_idx ON games USING btree (event_id, uid);


--
-- Name: games_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_title ON games USING gin (title gin_trgm_ops);


--
-- Name: games_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_user ON games USING gin ("user" gin_trgm_ops);


--
-- Name: games_votes_given_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_votes_given_idx ON games USING btree (votes_given);


--
-- Name: games_votes_received_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_votes_received_idx ON games USING btree (votes_received);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY lapis_migrations (name) FROM stdin;
1
2
3
4
5
6
7
8
9
\.


--
-- PostgreSQL database dump complete
--

