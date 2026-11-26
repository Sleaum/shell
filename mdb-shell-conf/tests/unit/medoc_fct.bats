setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'
  load '../test_helper/bats-file/load'

  LIB="$BATS_TEST_DIRNAME/../../lib"
  source "$LIB/medoc_var.sh"
  source "$LIB/medoc_log.sh"
  source "$LIB/medoc_fct.sh"
}

@test "exemple : une fonction de medoc_fct" {
  run nom_fonction "arg"
  assert_success
  assert_output --partial "attendu"
}
