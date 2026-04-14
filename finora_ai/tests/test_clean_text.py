"""Tests for the _clean_text helper function (RF-14 text normalization)."""

from app import _clean_text


class TestCleanText:
    def test_lowercase(self):
        assert _clean_text("MERCADONA") == "mercadona"

    def test_removes_digits(self):
        result = _clean_text("MERCADONA 234")
        assert "234" not in result
        assert "2" not in result

    def test_removes_accents(self):
        result = _clean_text("CAFÉ")
        assert "é" not in result
        assert "cafe" in result or "caf" in result

    def test_removes_punctuation(self):
        result = _clean_text("NETFLIX.")
        assert "." not in result

    def test_strips_whitespace(self):
        result = _clean_text("  mercadona  ")
        assert result == result.strip()

    def test_empty_string(self):
        result = _clean_text("")
        assert result == ""

    def test_none_returns_empty(self):
        result = _clean_text(None)
        assert result == ""

    def test_numbers_only(self):
        result = _clean_text("12345")
        assert result.strip() == ""

    def test_special_chars(self):
        result = _clean_text("REPSOL/GASOLINERA")
        assert "/" not in result

    def test_stopwords_removed(self):
        result = _clean_text("PAGO DE LA NOMINA")
        tokens = result.split()
        assert "pago" not in tokens
        assert "de" not in tokens
        assert "la" not in tokens

    def test_known_merchant_preserved(self):
        result = _clean_text("MERCADONA")
        assert "mercadona" in result

    def test_short_tokens_removed(self):
        # Tokens of length <= 2 are removed by the clean function
        result = _clean_text("AB CD EFG")
        tokens = result.split()
        for token in tokens:
            assert len(token) > 2, f"Short token '{token}' should be removed"

    def test_sl_stopword_removed(self):
        # 'sl' is in SPANISH_STOPWORDS and also <= 2 chars → removed
        result = _clean_text("EMPRESA SL")
        assert "sl" not in result.split()

    def test_unicode_normalization(self):
        # Spanish accented chars should be normalized
        result = _clean_text("FARMACÍA López")
        assert "á" not in result
        assert "ó" not in result

    def test_hyphen_removed(self):
        result = _clean_text("BANCO-SABADELL")
        assert "-" not in result

    def test_output_is_string(self):
        assert isinstance(_clean_text("MERCADONA"), str)

    def test_multiple_spaces_collapsed(self):
        result = _clean_text("MERCADONA   SUPERMERCADO")
        # After split and rejoin, extra spaces should be collapsed
        assert "  " not in result
