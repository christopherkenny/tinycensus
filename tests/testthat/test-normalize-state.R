test_that("state normalization accepts names abbreviations and fips", {
  expect_equal(tinycensus:::normalize_state("NY"), "36")
  expect_equal(tinycensus:::normalize_state("New York"), "36")
  expect_equal(tinycensus:::normalize_state("36"), "36")
  expect_equal(tinycensus:::normalize_state(c("NY", "Delaware")), c("36", "10"))
})

test_that("state matching helpers return fips", {
  expect_equal(tinycensus:::match_state_abb("DE"), "10")
  expect_equal(tinycensus:::match_state_name("Delaware"), "10")
  expect_equal(tinycensus:::match_state_fips("10"), "10")
})

test_that("invalid state values error clearly", {
  expect_error(
    tinycensus:::normalize_state("NotAState"),
    "Could not match state"
  )
})
