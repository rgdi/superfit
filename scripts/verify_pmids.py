#!/usr/bin/env python3
"""
Verifica que los PMIDs citados en research/05_referencias_bibliograficas.md
existen en PubMed y obtienen el paper esperado.

Uso:
    python3 scripts/verify_pmids.py
"""

import re
import sys
import urllib.request
import urllib.parse
import time
import json
from pathlib import Path

PUBMED_EUTILS = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"
TIMEOUT = 10
USER_AGENT = "SuperFit-Research-Audit/1.0 (contact: superfit-app@local)"

# PMIDs verificados el 9 jul 2026 + títulos esperados (substring match)
EXPECTED_PMIDS = {
    "27805470": "dose-response",  # Schoenfeld 2017 volumen
    "27102172": "frequency",      # Schoenfeld 2016 frecuencia
    "30335577": "stimuli",        # Wackerhage 2019
    "28933024": "rest interval",  # Grgic 2018 descanso
    "37967832": "repetitions-in-reserve",  # Refalo 2023
    "36580280": "maximizing strength",  # Spiering 2023
    "20199119": "training periodization",  # Issurin 2010
    "19691365": "rest interval",  # de Salles 2009
    "24864135": "bodybuilding",  # Helms 2014
    "26332783": "undulating",  # Zourdos 2016
}


def verify_pmid(pmid: str, expected_keyword: str) -> dict:
    """Consulta NCBI y verifica que el título contiene la keyword esperada."""
    params = urllib.parse.urlencode({
        "db": "pubmed",
        "id": pmid,
        "retmode": "json",
    })
    url = f"{PUBMED_EUTILS}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            j = json.loads(resp.read().decode("utf-8"))
            result = j.get("result", {})
            pmid_data = result.get(pmid, {})
            if "error" in pmid_data:
                return {"pmid": pmid, "valid": False, "error": pmid_data["error"]}
            title = pmid_data.get("title", "").lower()
            match = expected_keyword.lower() in title
            return {
                "pmid": pmid,
                "valid": match,
                "title": pmid_data.get("title", "—")[:90],
                "authors": ", ".join(a.get("name", "") for a in pmid_data.get("authors", [])[:3]),
                "source": pmid_data.get("source", ""),
                "pubdate": pmid_data.get("pubdate", ""),
                "expected_keyword": expected_keyword,
            }
    except Exception as e:
        return {"pmid": pmid, "valid": False, "error": str(e)}


def main():
    print(f"Verificando {len(EXPECTED_PMIDS)} PMIDs contra PubMed...\n")
    ok = 0
    fail = 0
    for pmid, kw in EXPECTED_PMIDS.items():
        r = verify_pmid(pmid, kw)
        if r["valid"]:
            print(f"  OK   PMID {pmid}: {r['title']}")
            print(f"       {r['authors']} | {r['source']} ({r['pubdate']})")
            ok += 1
        else:
            print(f"  FAIL PMID {pmid}: {r.get('error', '?')} | title='{r.get('title','')}' expected '{kw}'")
            fail += 1
        time.sleep(0.4)  # respetar rate limit NCBI (3 req/s sin API key)
    print(f"\nResultado: {ok}/{len(EXPECTED_PMIDS)} válidos ({fail} fallan).")
    if fail:
        sys.exit(1)


if __name__ == "__main__":
    main()
