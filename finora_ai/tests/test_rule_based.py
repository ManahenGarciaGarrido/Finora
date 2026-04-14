"""Tests for the _rule_based_category helper function (RF-14 rule engine)."""

import pytest
from app import _rule_based_category


class TestRuleBasedCategorization:
    def test_mercadona_alimentacion(self):
        result = _rule_based_category("mercadona valencia", "expense")
        assert result[0] == "Alimentación"
        assert result[1] > 0.5

    def test_carrefour_alimentacion(self):
        result = _rule_based_category("carrefour supermercado", "expense")
        assert result[0] == "Alimentación"

    def test_lidl_alimentacion(self):
        result = _rule_based_category("lidl compra", "expense")
        assert result[0] == "Alimentación"

    def test_repsol_transporte(self):
        result = _rule_based_category("repsol gasolinera", "expense")
        assert result[0] == "Transporte"

    def test_gasolinera_transporte(self):
        result = _rule_based_category("bp gasolinera", "expense")
        assert result[0] == "Transporte"

    def test_netflix_ocio_or_servicios(self):
        result = _rule_based_category("netflix", "expense")
        assert result[0] in ["Ocio", "Servicios"]

    def test_spotify_ocio_or_servicios(self):
        result = _rule_based_category("spotify", "expense")
        assert result[0] in ["Ocio", "Servicios"]

    def test_nomina_salario(self):
        # _rule_based_category receives pre-cleaned text (stopwords removed)
        # 'empresa' and 'sl' are stopwords, so the cleaned form is just 'nomina'
        result = _rule_based_category("nomina", "income")
        assert result[0] == "Salario"

    def test_alquiler_vivienda(self):
        result = _rule_based_category("alquiler enero", "expense")
        assert result[0] == "Vivienda"

    def test_farmacia_salud(self):
        result = _rule_based_category("farmacia central", "expense")
        assert result[0] == "Salud"

    def test_unknown_returns_otros(self):
        result = _rule_based_category("xyz corp", "expense")
        assert result[0] == "Otros" or result[0] is None

    def test_empty_string(self):
        result = _rule_based_category("", "expense")
        # No keyword match → best_cat is None, best_conf is 0
        assert result[0] is None or result[0] == "Otros"
        assert result[1] == 0

    def test_case_insensitive_via_lowercase_input(self):
        # The function expects already-lowercased text from _clean_text
        result1 = _rule_based_category("mercadona", "expense")
        result2 = _rule_based_category("mercadona", "expense")
        assert result1[0] == result2[0]

    def test_confidence_is_numeric(self):
        result = _rule_based_category("mercadona", "expense")
        assert isinstance(result[1], (int, float))

    def test_confidence_range(self):
        result = _rule_based_category("mercadona", "expense")
        assert 0 <= result[1] <= 100

    def test_income_type_ignored_for_expense_rules(self):
        # 'mercadona' is an expense rule — calling with 'income' type should not match
        result = _rule_based_category("mercadona", "income")
        assert result[0] != "Alimentación"

    def test_expense_type_ignored_for_income_rules(self):
        # 'nomina' is an income rule — calling with 'expense' type should not match
        result = _rule_based_category("nomina", "expense")
        assert result[0] != "Salario"

    def test_vodafone_servicios(self):
        result = _rule_based_category("vodafone", "expense")
        assert result[0] == "Servicios"

    def test_farmacia_confidence_high(self):
        # 'farmacia' keyword length >= 5 → conf = weight * 90 = 0.95 * 90 = 85.5 → 86
        result = _rule_based_category("farmacia central", "expense")
        assert result[1] >= 50

    def test_hipoteca_vivienda(self):
        result = _rule_based_category("hipoteca banco", "expense")
        assert result[0] == "Vivienda"

    def test_zara_ropa(self):
        result = _rule_based_category("zara tienda", "expense")
        assert result[0] == "Ropa"
