library("rgrass")

gisbase <- system2("grass", args = c("--config", "path"), stdout = TRUE)
template <- terra::rast(matrix(), crs = "epsg:3067")
invisible(initGRASS(gisBase = gisbase, home = tempdir(), SG = template))

input_xyz <- snakemake@input[["raster"]]
output_field <- snakemake@wildcards[["gridcell_field"]]

field_type <- snakemake@params[["field_type"]]
resolution <- snakemake@params[["resolution"]]

if (field_type == "category") {
    grass_type <- "CELL"
    gdal_type <- "Byte"
    gdal_nodata <- 0
    geotiff_predictor <- 2
    nbits <- NULL
} else if (field_type %in% c("integer", "date")) {
    grass_type <- "CELL"
    if (substr(output_field, 1, 9) == "stemcount") {
        gdal_type <- "UInt32"
        gdal_nodata <- 2^20 - 1
        nbits <- "NBITS=20"
        geotiff_predictor <- 1
    } else {
        gdal_type <- "UInt16"
        gdal_nodata <- 2^16 - 1
        nbits <- NULL
        geotiff_predictor <- 2
    }
} else if (field_type == "real") {
    grass_type <- "FCELL"
    gdal_type <- "Float32"
    gdal_nodata <- -65504
    geotiff_predictor <- 3
    nbits <- "NBITS=16"
}

extent <- execGRASS(
    "r.in.xyz",
    flags = c("g", "s"),
    input = input_xyz,
    separator = "tab",
    skip = 1,
    intern = TRUE
)

extent <- strsplit(strsplit(extent, " ", fixed = TRUE)[[1]][1:4], "=")

extent <- setNames(
    lapply(extent, "[", i = 2),
    lapply(extent, "[", i = 1)
)

execGRASS(
    "g.region",
    parameters = c(extent, res = as.character(resolution))
)

execGRASS(
    "g.region",
    n = paste0("n+", resolution / 2),
    s = paste0("s-", resolution / 2),
    w = paste0("w-", resolution / 2),
    e = paste0("e+", resolution / 2)
)

execGRASS(
    "r.in.xyz",
    input = input_xyz,
    output = output_field,
    separator = "tab",
    skip = 1,
    type = grass_type
)

execGRASS(
    "r.out.gdal",
    flags = c("c"),
    input = output_field,
    output = snakemake@output[[1]],
    type = gdal_type,
    nodata = gdal_nodata,
    createopt = c("COMPRESS=LZW", paste0("PREDICTOR=", geotiff_predictor), nbits, "TILED=YES", "BIGTIFF=YES")
)
