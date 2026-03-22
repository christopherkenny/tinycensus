if (requireNamespace("vcr", quietly = TRUE)) {
  vcr::vcr_configure(
    dir = file.path("fixtures", "vcr_cassettes"),
    record = "once",
    filter_sensitive_data = list(
      "<CENSUS_API_KEY>" = Sys.getenv("CENSUS_API_KEY", "")
    )
  )
}
