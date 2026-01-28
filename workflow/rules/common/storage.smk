storage:
    provider="http",


SMK_DATA_ROOT_URL = "https://avoin.metsakeskus.fi/aineistot"


def gridcell_history_url(wildcards):
    return storage.http(
        f"{SMK_DATA_ROOT_URL}/Historia/Hila/{wildcards.day}_{wildcards.month}_{wildcards.year}/Maakunta/Hila_{wildcards.region}.zip"
    )
