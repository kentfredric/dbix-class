# Note: None of these can actually call exit, for
# reasons explained below ...

function warn() {
  echo " * Warning: $@" >&2
  return;
}
function info() {
  echo " * Info: $@" >&2
  return;
}
function fatal() {
  echo " * Fatal Error: $@" >&2
  return;
}

# Bash sucks and "sourced" documents need to use "return"
# to abort remaining flow control in the sourced document without aborting the whole process.
#
# But if its not sourced, "return" is *invalid*, so exit 0 is appropriate.
#
# EXTRA IMPORTANT:
#
# Bash really sucks, and 'exit' inside a function call will *also* kill the parent shell
# but "return" only returns control from the *current* function!.
#
# ... So aborting flow control of an entire sourced document within a single function in that
# sourced document is impossible without killing the parent shell.
# GLHF.

safe_exit="exit 0";
fatal_exit="exit 1";

if [ "X$(basename -- "$0")" != "Xexpand_opts.bash" ]; then
  safe_exit="return";
  if [[  "$TRAVIS" != "true"  ]]; then
    # This prevents testing the code with 'source' resulting in
    # the enclosing shell being destroyed when you are simply testing
    # the logic, not using travis.
    fatal_exit="return";
  fi
fi


if [[ -z "$OPTS" ]]; then
  info "No OPTS defined. expand_opts.bash not used" && ${safe_exit};
fi


for opt in $OPTS; do
  info "Dispatching opt ${opt}...";
  case "$opt" in
    devreldeps)
      export DEVREL_DEPS=true
      info "enabled DEVREL_DEPS"
      ;;
    no-devreldeps)
      export DEVREL_DEPS=false
      info "disabled DEVREL_DEPS";
      ;;
    singlethreaded)
      export VCPU_USE=1
      info "forcing single-threaded tests"
      ;;
    no-singlethreaded)
      unset VCPU_USE;
      info "allowing multi-threaded tests"
      ;;
    cleantest)
      export CLEANTEST=true
      info "enabled CLEANTEST"
      ;;
    no-cleantest)
      export CLEANTEST=false
      info "disabled CLEANTEST"
      ;;
    poisonenv)
      export POISON_ENV=true
      info "enabled POISON_ENV"
      ;;
    no-poisonenv)
      export POISON_ENV=false
      info "disabled POISON_ENV"
      ;;
    *)
      fatal "Unknown opt $opt" && ${fatal_exit};
      ;;
  esac
done
