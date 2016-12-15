--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE collections (
    name character varying(255) NOT NULL,
    comp character varying(255) NOT NULL,
    uid character varying(255) NOT NULL
);


ALTER TABLE collections OWNER TO postgres;

--
-- Name: games; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE games (
    id integer NOT NULL,
    comp character varying(255) NOT NULL,
    uid character varying(255) NOT NULL,
    "user" character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    downloads text NOT NULL,
    num_downloads integer DEFAULT 0 NOT NULL,
    screenshots text,
    num_screenshots integer DEFAULT 0 NOT NULL,
    votes_received integer DEFAULT 0 NOT NULL,
    votes_given integer DEFAULT 0 NOT NULL,
    is_jam boolean,
    have_details boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: trash; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE trash (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE trash OWNER TO postgres;

--
-- Name: trash_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE trash_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE trash_id_seq OWNER TO postgres;

--
-- Name: trash_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE trash_id_seq OWNED BY trash.id;


--
-- Name: games id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY games ALTER COLUMN id SET DEFAULT nextval('games_id_seq'::regclass);


--
-- Name: trash id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trash ALTER COLUMN id SET DEFAULT nextval('trash_id_seq'::regclass);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (name, comp, uid);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: trash trash_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trash
    ADD CONSTRAINT trash_pkey PRIMARY KEY (id);


--
-- Name: games_comp_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_comp_title_idx ON games USING btree (comp, title);


--
-- Name: games_comp_uid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX games_comp_uid_idx ON games USING btree (comp, uid);


--
-- Name: games_votes_given_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_votes_given_idx ON games USING btree (votes_given);


--
-- Name: games_votes_received_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX games_votes_received_idx ON games USING btree (votes_received);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
\.


--
-- PostgreSQL database dump complete
--

