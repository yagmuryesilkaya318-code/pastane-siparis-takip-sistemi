-- Pastane Sipariş Takip Sistemi
-- Business Analyst Mini Project
-- Database Schema & Business Rules

DROP TABLE IF EXISTS odemeler CASCADE;
DROP TABLE IF EXISTS siparis_detay CASCADE;
DROP TABLE IF EXISTS siparisler CASCADE;
DROP TABLE IF EXISTS kampanyalar CASCADE;
DROP TABLE IF EXISTS masalar CASCADE;
DROP TABLE IF EXISTS personel CASCADE;
DROP TABLE IF EXISTS musteriler CASCADE;
DROP TABLE IF EXISTS urun_varyant CASCADE;
DROP TABLE IF EXISTS urunler CASCADE;
DROP TABLE IF EXISTS urun_kategori CASCADE;

DROP FUNCTION IF EXISTS gunluk_ciro(date);


--------------------------------------------------
-- 1) urun_kategori
--------------------------------------------------
CREATE TABLE urun_kategori (
    kategori_id   SERIAL PRIMARY KEY,
    kategori_adi  TEXT NOT NULL UNIQUE
);

--------------------------------------------------
-- 2) urunler
--------------------------------------------------
CREATE TABLE urunler (
    urun_id      SERIAL PRIMARY KEY,
    kategori_id  INT  NOT NULL REFERENCES urun_kategori(kategori_id)
                 ON UPDATE CASCADE ON DELETE RESTRICT,
    urun_adi     TEXT NOT NULL,
    aktif        BOOLEAN NOT NULL DEFAULT TRUE
);

--------------------------------------------------
-- 3) urun_varyant
--------------------------------------------------
CREATE TABLE urun_varyant (
    varyant_id   SERIAL PRIMARY KEY,
    urun_id      INT NOT NULL REFERENCES urunler(urun_id)
                 ON UPDATE CASCADE ON DELETE CASCADE,
    varyant_adi  TEXT NOT NULL,
    fiyat        NUMERIC(10,2) NOT NULL CHECK (fiyat >= 0),
    stok_adet    INT NOT NULL DEFAULT 0 CHECK (stok_adet >= 0)
);

--------------------------------------------------
-- 4) musteriler
--------------------------------------------------
CREATE TABLE musteriler (
    musteri_id  SERIAL PRIMARY KEY,
    ad          TEXT NOT NULL,
    soyad       TEXT NOT NULL,
    telefon     TEXT
);

--------------------------------------------------
-- 5) personel
--------------------------------------------------
CREATE TABLE personel (
    personel_id  SERIAL PRIMARY KEY,
    ad           TEXT NOT NULL,
    soyad        TEXT NOT NULL,
    rol          TEXT NOT NULL CHECK (rol IN ('admin','kasiyer','garson'))
);

--------------------------------------------------
-- 6) masalar
--------------------------------------------------
CREATE TABLE masalar (
    masa_id   SERIAL PRIMARY KEY,
    masa_no   TEXT NOT NULL UNIQUE
);

--------------------------------------------------
-- 7) kampanyalar
--------------------------------------------------
CREATE TABLE kampanyalar (
    kampanya_id     SERIAL PRIMARY KEY,
    kampanya_adi    TEXT NOT NULL,
    aciklama        TEXT,
    indirim_tipi    TEXT NOT NULL CHECK (indirim_tipi IN ('YUZDE','TUTAR')),
    indirim_degeri  NUMERIC(10,2) NOT NULL CHECK (indirim_degeri >= 0),
    aktif           BOOLEAN NOT NULL DEFAULT TRUE
);

--------------------------------------------------
-- 8) siparisler
--------------------------------------------------
CREATE TABLE siparisler (
    siparis_id     SERIAL PRIMARY KEY,
    siparis_tipi   TEXT NOT NULL CHECK (siparis_tipi IN ('MASA','PAKET','ONLINE')),
    masa_id        INT REFERENCES masalar(masa_id)
                   ON UPDATE CASCADE ON DELETE RESTRICT,
    musteri_id     INT REFERENCES musteriler(musteri_id)
                   ON UPDATE CASCADE ON DELETE SET NULL,
    personel_id    INT NOT NULL REFERENCES personel(personel_id)
                   ON UPDATE CASCADE ON DELETE RESTRICT,
    kampanya_id    INT REFERENCES kampanyalar(kampanya_id)
                   ON UPDATE CASCADE ON DELETE SET NULL,
    siparis_tarih  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    durum          TEXT NOT NULL DEFAULT 'ACIK'
                   CHECK (durum IN ('ACIK','ODEME_ALINDI','IPTAL')),
    aciklama       TEXT
);

-- MASA tipi için masa_id zorunlu, diğerlerinde NULL olmalı
ALTER TABLE siparisler
ADD CONSTRAINT chk_siparis_masa_tipi
CHECK (
   (siparis_tipi = 'MASA'   AND masa_id IS NOT NULL) OR
   (siparis_tipi IN ('PAKET','ONLINE') AND masa_id IS NULL)
);

--------------------------------------------------
-- 9) siparis_detay
--------------------------------------------------
