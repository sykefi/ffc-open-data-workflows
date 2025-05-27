library("rgrass")

gisbase <- system2("grass", args = c("--config", "path"), stdout = TRUE)
template <- terra::rast(matrix(), crs = "epsg:3067")
invisible(initGRASS(gisBase = gisbase, home = tempdir(), SG = template))

input_rasters <- snakemake@input

output_field <- snakemake@wildcards[["gridcell_field"]]

field_type <- snakemake@params[["field_type"]]
resolution <- snakemake@params[["resolution"]]


if (field_type == "category") {
    gdal_type <- "Byte"
    gdal_nodata <- 0
    geotiff_predictor <- 2
    nbits <- NULL
} else if (field_type %in% c("integer", "date")) {
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
    gdal_type <- "Float32"
    gdal_nodata <- -65504
    geotiff_predictor <- 3
    nbits <- "NBITS=16"
}

r_seq <- seq_along(input_rasters)

for (r in r_seq) {
    r_name <- paste0("r.", r)

    execGRASS(
        "r.in.gdal",
        flags = c("o"),
        input = input_rasters[[r]],
        output = r_name
    )
}

r_seq <- paste0("r.", r_seq)

execGRASS(
    "g.region",
    raster = r_seq
)

execGRASS(
    "r.patch",
    input=r_seq,
    output=output_field
)

if (output_field == "developmentclass") {
    category_file <- tempfile()

    writeLines(
        c("1:A0", "2:S0", "3:T1", "4:T2", "5:Y1", "6:ER", "7:02", "8:03", "9:04", "10:05"),
        con = category_file
    )

    execGRASS(
        "r.category",
        map=output_field,
        separator=":",
        rules=category_file
    )

    flags <- c("t")
} else {
    flags <- NULL
}

execGRASS(
    "r.out.gdal",
    flags = c("c", "f", flags),
    input = output_field,
    output = snakemake@output[[1]],
    type = gdal_type,
    nodata = gdal_nodata,
    createopt = c("COMPRESS=LZW", paste0("PREDICTOR=", geotiff_predictor), nbits, "TILED=YES", "BIGTIFF=YES")
)
