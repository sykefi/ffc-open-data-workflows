storage:
    provider="http",


SMK_DATA_ROOT_URL = "https://avoin.metsakeskus.fi/aineistot"


def gridcell_history_url(wildcards):
    return storage.http(
        f"{SMK_DATA_ROOT_URL}/Historia/Hila/{wildcards.day}_{wildcards.month}_{wildcards.year}/Maakunta/Hila_{wildcards.region}.zip"
    )


def kemera_url(wildcards):
    return storage.http(
        f"{SMK_DATA_ROOT_URL}/Kemera/Maakunta/Kemera_{wildcards.region}.zip"
    )


def forest_use_declaration_url(wildcards):
    return storage.http(
        f"{SMK_DATA_ROOT_URL}/Metsankayttoilmoitukset/Maakunta/MKI_{wildcards.region}.zip"
    )


def stand_url(wildcards):
    return storage.http(
        f"{SMK_DATA_ROOT_URL}/Historia/Metsavarakuviot/{wildcards.day}_{wildcards.month}_{wildcards.year}/Maakunta/MV_{wildcards.region}.zip"
    )
