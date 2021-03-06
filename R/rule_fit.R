#' General Interface for RuleFit Models
#'
#' [rule_fit()] is a way to generate a _specification_ of a model
#'  before fitting. The main arguments for the model are:
#' \itemize{
#'   \item \code{mtry}: The number of predictors that will be
#'   randomly sampled at each split when creating the tree models.
#'   \item \code{trees}: The number of trees contained in the ensemble.
#'   \item \code{min_n}: The minimum number of data points in a node
#'   that are required for the node to be split further.
#'   \item \code{tree_depth}: The maximum depth of the tree (i.e. number of
#'  splits).
#'   \item \code{learn_rate}: The rate at which the boosting algorithm adapts
#'   from iteration-to-iteration.
#'   \item \code{loss_reduction}: The reduction in the loss function required
#'   to split further.
#'   \item \code{sample_size}: The amount of data exposed to the fitting routine.
#' }
#' These arguments are converted to their specific names at the
#'  time that the model is fit. Other options and argument can be
#'  set using [parsnip::set_engine()]. If left to their defaults
#'  here (`NULL`), the values are taken from the underlying model
#'  functions. If parameters need to be modified, `update()` can be used
#'  in lieu of recreating the object from scratch.
#' @param mode A single character string for the type of model.
#'  Possible values for this model are "unknown", "regression", or
#'  "classification".
#' @param mtry An number for the number (or proportion) of predictors that will
#'  be randomly sampled at each split when creating the tree models.
#' @param trees An integer for the number of trees contained in
#'  the ensemble.
#' @param min_n An integer for the minimum number of data points
#'  in a node that are required for the node to be split further.
#' @param tree_depth An integer for the maximum depth of the tree (i.e. number
#'  of splits).
#' @param learn_rate A number for the rate at which the boosting algorithm adapts
#'   from iteration-to-iteration.
#' @param loss_reduction A number for the reduction in the loss function required
#'   to split further .
#' @param sample_size An number for the number (or proportion) of data that is
#'  exposed to the fitting routine.
#' @param penalty L1 regularization parameter.
#' @details
#' The RuleFit model creates a regression model of rules in two stages. The
#'  first stage uses a tree-based model that is used to generate a set of rules
#'  that can be filtered, modified, and simplified. These rules are then added
#'  as predictors to a regularized generalized linear model that can also
#'  conduct feature selection during model training.
#'
#' For the `xrf` engine, the `xgboost` package is used to create the rule set
#'  that is then added to a `glmnet` model.
#'
#' The only available engine is `"xrf"`. Not that, per the documentation in
#' `?xrf`, transformations of the response variable are not supported. To
#' use these with `rule_fit()`, we recommend using a recipe instead of the
#' formula method.
#'
#' @return An updated `parsnip` model specification.
#' @seealso [parsnip::fit()], [parsnip::fit_xy()], [xrf::xrf.formula()]
#' @references Friedman, J. H., and Popescu, B. E. (2008). "Predictive learning
#' via rule ensembles." _The Annals ofApplied Statistics_, 2(3), 916-954.
#' @examples
#' rule_fit()
#' # Parameters can be represented by a placeholder:
#' rule_fit(trees = 7)
#'
#' # ------------------------------------------------------------------------------
#'
#' set.seed(6907)
#' rule_fit_rules <-
#'   rule_fit(trees = 3, penalty = 0.1) %>%
#'   set_mode("classification") %>%
#'   fit(Species ~ ., data = iris)
#'
#' @export
#' @importFrom purrr map_lgl
rule_fit <-
  function(mode = "unknown",
           mtry = NULL, trees = NULL, min_n = NULL,
           tree_depth = NULL, learn_rate = NULL,
           loss_reduction = NULL,
           sample_size = NULL,
           penalty = NULL) {

    args <- list(
      mtry = enquo(mtry),
      trees = enquo(trees),
      min_n = enquo(min_n),
      tree_depth = enquo(tree_depth),
      learn_rate = enquo(learn_rate),
      loss_reduction = enquo(loss_reduction),
      sample_size = enquo(sample_size),
      penalty = enquo(penalty)
    )


    new_model_spec(
      "rule_fit",
      args = args,
      eng_args = NULL,
      mode = mode,
      method = NULL,
      engine = "xrf"
    )
  }

#' @export
print.rule_fit <- function(x, ...) {
  cat("RuleFit Model Specification (", x$mode, ")\n\n", sep = "")
  parsnip::model_printer(x, ...)

  if (!is.null(x$method$fit$args)) {
    cat("Model fit template:\n")
    print(parsnip::show_call(x))
  }

  invisible(x)
}


# ------------------------------------------------------------------------------

#' @param object A `rule_fit` model specification.
#' @examples
#' # ------------------------------------------------------------------------------
#'
#' model <- rule_fit(trees = 10, min_n = 2)
#' model
#' update(model, trees = 1)
#' update(model, trees = 1, fresh = TRUE)
#' @method update rule_fit
#' @rdname rule_fit
#' @inheritParams update.C5_rules
#' @export
update.rule_fit <-
  function(object,
           parameters = NULL,
           mtry = NULL, trees = NULL, min_n = NULL,
           tree_depth = NULL, learn_rate = NULL,
           loss_reduction = NULL, sample_size = NULL,
           penalty = NULL,
           fresh = FALSE, ...) {
    update_dot_check(...)

    if (!is.null(parameters)) {
      parameters <- check_final_param(parameters)
    }

    args <- list(
      mtry = enquo(mtry),
      trees = enquo(trees),
      min_n = enquo(min_n),
      tree_depth = enquo(tree_depth),
      learn_rate = enquo(learn_rate),
      loss_reduction = enquo(loss_reduction),
      sample_size = enquo(sample_size),
      penalty = enquo(penalty)
    )

    args <- update_main_parameters(args, parameters)

    if (fresh) {
      object$args <- args
    } else {
      null_args <- map_lgl(args, null_value)
      if (any(null_args))
        args <- args[!null_args]
      if (length(args) > 0)
        object$args[names(args)] <- args
    }

    new_model_spec(
      "rule_fit",
      args = object$args,
      eng_args = object$eng_args,
      mode = object$mode,
      method = NULL,
      engine = object$engine
    )
  }


# ------------------------------------------------------------------------------

#' @export
#' @keywords internal
#' @rdname rules-internal
xrf_fit <-
  function(formula,
           data,
           max_depth = 6,
           nrounds = 15,
           eta  = 0.3,
           colsample_bytree = 1,
           min_child_weight = 1,
           gamma = 0,
           subsample = 1,
           lambda = 0.1,
           ...) {
    args <- list(object = formula,
                 data = expr(data),
                 xgb_control =
                   list(
                     nrounds = nrounds,
                     max_depth = max_depth,
                     eta = eta,
                     colsample_bytree = colsample_bytree,
                     min_child_weight = min_child_weight,
                     gamma = gamma,
                     subsample = subsample
                   )
    )
    dots <- rlang::enquos(...)
    if (!any(names(dots) == "family")) {
      info <- get_family(formula, data)
      args$family <- info$fam
      if (info$fam == "multinomial") {
        args$xgb_control$num_class <- info$classes
      }
    }
    if (length(dots) > 0) {
      args <- c(args, dots)
    }
    cl <- rlang::call2(.fn = "xrf", .ns = "xrf",!!!args)
    res <- rlang::eval_tidy(cl)
    res$lambda  <- lambda
    res$family <- args$family
    res
  }

get_family <- function(formula, data) {
  m <- model.frame(formula, head(data))
  y <- model.response(m)
  if (is.numeric(y)) {
    if (is.integer(y)) {
      res <- "poisson"
    } else {
      res <-  "gaussian"
    }
    lvl <- NA
  } else {
    if (is.character(y)) {
      y <- factor(y)
    }
    lvl <- levels(y)
    if (length(lvl) > 2) {
      res <- "multinomial"
    } else {
      res <- "binomial"
    }
  }
  list(fam = res, classes = length(lvl))
}

get_glmnet_type <- function(x, type) {
  fam <- x$fit$family
  if (fam %in% c("binomial", "multinomial")) {
    if (rlang::is_missing(type)) {
      type <- "response"
    } else {
      if (type == "prob") {
        type <- "response"
      }
    }
  } else {
    type <- "response"
  }
  type
}


#' @export
#' @keywords internal
#' @rdname rules-internal
xrf_pred <- function(object, new_data, lambda = object$fit$lambda, type, ...) {

  lambda <- sort(lambda)

  res <- predict(object$fit, new_data, lambda = lambda, type = "response")
  if (type != "prob") {
    res <- organize_xrf_multi_pred(res, object, lambda, object$fit$family)
  } else {
    res <- organize_xrf_multi_prob(res, object, lambda, object$fit$family)
  }
  res
}

#' @rdname multi_predict
#' @export
#' @param penalty Non-negative penalty values.
#' @param ... Not currently used.
multi_predict._xrf <-
  function(object, new_data, type = NULL, penalty = NULL, ...) {
    if (any(names(enquos(...)) == "newdata")) {
      rlang::abort("Did you mean to use `new_data` instead of `newdata`?")
    }
    if (is.null(penalty)) {
      penalty <- object$fit$lambda
    }

    if (is.null(type)) {
      fam <- object$fit$family
      if (fam %in% c("binomial", "multinomial")) {
        type <- "class"
      } else {
        type <- "numeric"
      }
    }

    res <- xrf_pred(object, new_data, lambda = penalty, type = type, ...)
    res
  }

# ------------------------------------------------------------------------------

organize_xrf_pred <- function(x, object) {
  res <- dplyr::pull(x, .pred)
  res <- unname(res)
}

organize_xrf_class_pred <- function(x, object) {
  x <- tidyr::unnest(x, cols = c(.pred))
  lams <- unique(x$penalty)
  if (length(lams) > 1) {
    x$penalty <- NULL
  }
  x
}

organize_xrf_class_prob <- function(x, object) {
  if (!inherits(x, "array")) {
    x <- x[,1]
    x <- tibble(v1 = 1 - x, v2 = x)
  } else {
    x <- x[,,1]
    x <- as_tibble(x)
  }
  colnames(x) <- object$lvl
  x
}

organize_xrf_multi_pred <- function(x, object, penalty, fam) {
  if (fam %in% c("gaussian", "poisson")) {
    if (ncol(x) == 1) {
      res <- tibble(penalty = rep(penalty, nrow(x)), .pred = unname(x[,1]))
    } else {
      res <-
        tibble::as_tibble(x) %>%
        dplyr::mutate(.row_number = 1:nrow(x)) %>%
        tidyr::pivot_longer(cols = c(-.row_number), values_to = ".pred") %>%
        dplyr::mutate(penalty = rep(penalty, nrow(x))) %>%
        dplyr::select(-name) %>%
        dplyr::group_by(.row_number) %>%
        tidyr::nest() %>%
        dplyr::ungroup() %>%
        dplyr::select(-.row_number) %>%
        setNames(".pred")
    }
  } else {
    if (fam == "binomial") {

      res <-
        tibble::as_tibble(x) %>%
        dplyr::mutate(.row_number = 1:nrow(x)) %>%
        tidyr::pivot_longer(cols = c(-.row_number), values_to = ".pred_class")  %>%
        dplyr::select(-name) %>%
        dplyr::mutate(
          .pred_class = ifelse(.pred_class >= .5, object$lvl[2], object$lvl[1]),
          .pred_class = factor(.pred_class, levels = object$lvl)
        )

      if (length(penalty) == 1) {
        # predict
        res <- dplyr::pull(res, .pred_class)
      } else {
        # multipredict
        res <-
          res %>%
          dplyr::mutate(penalty = rep(penalty, nrow(x))) %>%
          dplyr::group_by(.row_number) %>%
          tidyr::nest() %>%
          dplyr::ungroup() %>%
          dplyr::select(-.row_number) %>%
          setNames(".pred")
      }

    } else {
      # fam = "multinomial"
      res <-
        apply(x, 3, function(x) apply(x, 1, which.max)) %>%
        tibble::as_tibble() %>%
        dplyr::mutate(.row_number = 1:nrow(x)) %>%
        tidyr::pivot_longer(cols = c(-.row_number), values_to = ".pred_class") %>%
        dplyr::select(-name) %>%
        dplyr::mutate(
          .pred_class = object$lvl[.pred_class],
          .pred_class = factor(.pred_class, levels = object$lvl)
        )
      if (length(penalty) == 1) {
        # predict
        res <- dplyr::pull(res, .pred_class)
      } else {
        # multi-predict
        res <-
          res %>%
          dplyr::mutate(penalty = rep(penalty, nrow(x))) %>%
          dplyr::group_by(.row_number) %>%
          tidyr::nest() %>%
          dplyr::ungroup() %>%
          dplyr::select(-.row_number) %>%
          setNames(".pred")
      }
    }
  }
  res
}

organize_xrf_multi_prob <- function(x, object, penalty, fam) {

  if (fam == "binomial") {

    res <-
      tibble::as_tibble(x) %>%
      dplyr::mutate(.row_number = 1:nrow(x)) %>%
      tidyr::pivot_longer(cols = c(-.row_number), values_to = ".pred_2") %>%
      dplyr::mutate(penalty = rep(penalty, nrow(x))) %>%
      dplyr::select(-name) %>%
      dplyr::mutate(.pred_1 = 1 - .pred_2) %>%
      dplyr::select(.row_number, penalty, .pred_1, .pred_2)

    if (length(penalty) == 1) {
      # predict
      res <-
        res %>%
        setNames(c(".row_number", "penalty", object$lvl)) %>%
        dplyr::select(-.row_number, -penalty)
    } else {
      # multi_predict
      res <-
        res %>%
        setNames(c(".row_number", "penalty", paste0(".pred_", object$lvl))) %>%
        dplyr::group_by(.row_number) %>%
        tidyr::nest() %>%
        dplyr::ungroup() %>%
        dplyr::select(-.row_number) %>%
        setNames(".pred")
    }

  } else {
    # fam = "multinomial"
    res <-
      apply(x, 3, as_tibble) %>%
      bind_rows() %>%
      setNames(object$lvl)

    # good format for predict()
    if (length(penalty) > 1) {
      # multi_predict
      res <-
        res %>%
        dplyr::mutate(.row_number = rep(1:nrow(x), length(penalty))) %>%
        dplyr::mutate(penalty = rep(penalty, each = nrow(x))) %>%
        dplyr::group_by(.row_number) %>%
        tidyr::nest() %>%
        dplyr::ungroup() %>%
        dplyr::select(-.row_number) %>%
        setNames(".pred")
    }
  }
  res
}

#' @export
#' @keywords internal
#' @rdname rules-internal
tunable.rule_fit <- function(x, ...) {
  tibble::tibble(
    name = c('mtry', 'trees', 'min_n', 'tree_depth', 'learn_rate',
             'loss_reduction', 'sample_size', 'penalty'),
    call_info = list(
      list(pkg = "rules", fun = "mtry_prop"),
      list(pkg = "dials", fun = "trees", range = c(5, 100)),
      list(pkg = "dials", fun = "min_n"),
      list(pkg = "dials", fun = "tree_depth", range = c(1, 10)),
      list(pkg = "dials", fun = "learn_rate"),
      list(pkg = "dials", fun = "loss_reduction"),
      list(pkg = "dials", fun = "sample_prop", range = c(0.50, 0.95)),
      list(pkg = "dials", fun = "penalty")
    ),
    source = "model_spec",
    component = class(x)[class(x) != "model_spec"][1],
    component_id =  "main"
  )
}

#' Proportion of Randomly Selected Predictors
#'
#' @inheritParams committees
#' @return A `dials` with classes "quant_param" and "param". The `range` element
#' of the object is always converted to a list with elements "lower" and "upper".
#' @export
mtry_prop <- function(range = c(0.1, 1), trans = NULL)  {
  dials::new_quant_param(
    type = "double",
    range = range,
    inclusive = c(TRUE, TRUE),
    trans = trans,
    label = c(mtry_prop = "Proportion Randomly Selected Predictors"),
    finalize = NULL
  )
}

