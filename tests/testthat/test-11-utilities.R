context("Check utilities")

test_that("check modalvalue", {
  xx <- c(1, 2, 3, 4, 5, 4, 3, 2, 1, 2)
  expect_equal(modalvalue(xx), 2)
  expect_error(modalvalue("ok"))
})

test_that("check document_weights", {
  data(rodents)
  lda_data <- rodents$document_term_table
  doc_weights <- document_weights(lda_data)
  expect_equal(round(mean(doc_weights), 3), 1)
  expect_equal(round(max(doc_weights), 3), 3.543)
  expect_equal(round(min(doc_weights), 3), 0.151)
  expect_equal(length(doc_weights), 436)
  expect_error(document_weights("ok"))
})

test_that("check qprint", {
  expect_error(qprint())
  expect_error(qprint("ok"))
  expect_error(qprint("ok", ""))
  expect_output(qprint("ok", "", quiet = FALSE))
  expect_silent(qprint("ok", "", quiet = TRUE))
})

test_that("check mirror_vcov", {
  y <- 1:10
  x <- 101:110
  mod <- lm(y ~ x)
  vcv <- mirror_vcov(mod)  
  expect_equal(isSymmetric(vcv), TRUE)
  expect_error(mirror_vcov("ok"))

  data(rodents)
  lda_data <- rodents$document_term_table
  document_term_table <- rodents$document_term_table
  document_covariate_table <- rodents$document_covariate_table
  topics <- 2
  nseeds <- 1
  formulas <- ~ newmoon
  nchangepoints <- 2
  weights <- document_weights(document_term_table)
  control <- LDA_TS_controls_list()
  LDAs <- LDA_set(document_term_table, topics, nseeds, control$LDA_control)
  LDA_models <- select_LDA(LDAs, control$LDA_control)
  control <- TS_controls_list(nit = 1e2, seed = 1)
  mods <- expand_TS(LDA_models, formulas, nchangepoints)
  formula <- mods$formula[[1]]
  nchangepoints <- mods$nchangepoints[1]
  data <- prep_TS_data(document_covariate_table, LDA_models, mods, 1)
  rho_dist <- est_changepoints(data, formula, nchangepoints, weights, control)
  mod <- multinom_TS(data, formula, changepoints = NULL, weights, control)
  expect_equal(isSymmetric(vcov(mod[[1]][[1]])), FALSE)
  expect_equal(isSymmetric(mirror_vcov(mod[[1]][[1]])), TRUE)

})

test_that("check normalize", {
  xx <- c(1, 2, 3, 4, 5, 4, 3, 2, 1, 2)
  expect_equal(mean(normalize(xx)), 0.425)
  expect_equal(normalize(xx)[1], 0)
  xx <- -1000:100
  expect_equal(mean(normalize(xx)), 0.5)
  expect_equal(round(sd(normalize(xx)), 3), 0.289)
  expect_error(normalize("ok"))
})

test_that("check memoise_fun", {
  expect_is(memoise_fun(sum, TRUE), "memoised")
  expect_is(memoise_fun(sum, FALSE), "function")  
  expect_error(memoise_fun(1, TRUE))
  expect_error(memoise_fun(sum, 1))
})

test_that("check check_control", {
  expect_silent(check_control(TS_controls_list(), "TS_controls"))
  expect_silent(check_control(LDA_TS_controls_list(), "LDA_TS_controls"))
  expect_silent(check_control(LDA_controls_list(), "LDA_controls"))
  expect_error(check_control(TS_controls_list(), "LDA_controls"))
  expect_error(check_control(LDA_controls_list(), "TS_controls"))
  expect_error(check_control(LDA_TS_controls_list(), "LDA_controls"))
})


test_that("check error catching of check_document_term_table", {
  dtt <- "a"
  expect_error(check_document_term_table(dtt))
  dtt <- matrix(1:100, 10, 10)
  expect_error(check_document_term_table(dtt, NA))
  dtt <- data.frame("dummy" = 1:100)
  expect_error(check_document_term_table(dtt, NA))
})

test_that("check error catching of check_topics", {
  expect_error(check_topics("a"))
  expect_error(check_topics(1.5))
  expect_error(check_topics(1))
  expect_error(check_topics(2), NA)
  expect_error(check_topics(c(2, 3, 4)), NA)
  expect_silent(check_topics(5))
  expect_silent(check_topics(2:5))
})

test_that("check error catching of check_seeds", {
  expect_error(check_seeds("a"))
  expect_error(check_seeds(1.5))
  expect_error(check_seeds(2), NA)
  expect_error(check_seeds(c(2, 3, 4)), NA)
  expect_silent(check_seeds(5))
  expect_silent(check_seeds(1:5))
})

