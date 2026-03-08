-- 全国地方公共団体コードマスタテーブル
CREATE TABLE core.municipality_codes (
    code            VARCHAR(6) PRIMARY KEY,
    prefecture_code VARCHAR(2) NOT NULL,
    prefecture_name VARCHAR(10) NOT NULL,
    city_name       VARCHAR(100) NOT NULL,
    full_name       VARCHAR(110) NOT NULL,
    prefecture_kana VARCHAR(20),
    city_kana       VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    effective_from  DATE,
    effective_to    DATE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_municipality_codes_code_length CHECK (length(code) = 6),
    CONSTRAINT chk_municipality_codes_prefecture_code_length CHECK (length(prefecture_code) = 2),
    CONSTRAINT chk_municipality_codes_dates CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

-- インデックス
CREATE INDEX idx_municipality_codes_prefecture ON core.municipality_codes(prefecture_code);
CREATE INDEX idx_municipality_codes_active ON core.municipality_codes(is_active);
CREATE INDEX idx_municipality_codes_full_name ON core.municipality_codes(full_name);

-- コメント
COMMENT ON TABLE core.municipality_codes IS '全国地方公共団体コードマスタ（全テナント共通）';
COMMENT ON COLUMN core.municipality_codes.code IS '全国地方公共団体コード（6桁）';
COMMENT ON COLUMN core.municipality_codes.prefecture_code IS '都道府県コード（JIS X 0401）';

-- 初期データ（主要自治体のみ）
INSERT INTO core.municipality_codes (code, prefecture_code, prefecture_name, city_name, full_name, prefecture_kana, city_kana, effective_from) VALUES
('010006', '01', '北海道', '札幌市', '北海道札幌市', 'ホッカイドウ', 'サッポロシ', '1972-04-01'),
('011002', '01', '北海道', '札幌市中央区', '北海道札幌市中央区', 'ホッカイドウ', 'サッポロシチュウオウク', '1972-04-01'),
('140007', '14', '神奈川県', '横浜市', '神奈川県横浜市', 'カナガワケン', 'ヨコハマシ', '1889-04-01'),
('141003', '14', '神奈川県', '横浜市鶴見区', '神奈川県横浜市鶴見区', 'カナガワケン', 'ヨコハマシツルミク', '1927-10-01'),
('141011', '14', '神奈川県', '横浜市神奈川区', '神奈川県横浜市神奈川区', 'カナガワケン', 'ヨコハマシカナガワク', '1927-10-01'),
('141305', '14', '神奈川県', '横浜市港北区', '神奈川県横浜市港北区', 'カナガワケン', 'ヨコハマシコウホクク', '1939-04-01'),
('141500', '14', '神奈川県', '川崎市', '神奈川県川崎市', 'カナガワケン', 'カワサキシ', '1924-07-01'),
('142018', '14', '神奈川県', '相模原市', '神奈川県相模原市', 'カナガワケン', 'サガミハラシ', '1954-11-20'),
('131016', '13', '東京都', '千代田区', '東京都千代田区', 'トウキョウト', 'チヨダク', '1947-03-15'),
('271004', '27', '大阪府', '大阪市北区', '大阪府大阪市北区', 'オオサカフ', 'オオサカシキタク', '1889-04-01'),
('401005', '40', '福岡県', '福岡市東区', '福岡県福岡市東区', 'フクオカケン', 'フクオカシヒガシク', '1972-04-01');
