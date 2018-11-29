#!/bin/bash
# Test each plugin

enable_plugin() {
  local PLUGIN="$1"
  # Enable plugin usage
  if ! grep -qP '^USEPLUGINS="?yes"?' /etc/recap.conf; then
    sed -i 's/^#\(USEPLUGINS\)=.*$/\1="yes"/' /etc/recap.conf
  fi

  # Enable the plugin
  ln -fs \
    ${PREFIX}/lib/recap/plugins-available/${PLUGIN} \
    ${PREFIX}/lib/recap/plugins-enabled/${PLUGIN}
}

disable_plugin() {
  local PLUGIN="$1"
  # Disable the plugin
  rm -f ${PREFIX}/lib/recap/plugins-enabled/${PLUGIN}

  # Disable plugin usage
  if grep -qP '^USEPLUGINS="?yes"?' /etc/recap.conf; then
    sed -i 's/^\(USEPLUGINS=.*\)$/#\1/' /etc/recap.conf
  fi
}


test_plugins() {
  local -a plugins
  # Find tests available for a plugin
  plugins=( $( ls tests |
                 awk '
                   /test_plugin_/ { gsub("test_plugin_", plg);
                   print $plg}
                 '
             )
          )

  # Return if there are no plugin tests
  if [[ ${#plugins[@]} < 0 ]]; then
    return 0
  fi

  # Get full path to recap
  recap_path=$(type -p recap)
  
  # Remove 'set -e' on line 2 of recap
  sed -i "/^set -e$/d" "${recap_path}";

  for plugin in ${plugins[@]}; do
    enable_plugin ${plugin}
    
    # Run the test

    bash test/test_plugin_${plugin}
    
    # Save debugging info and record the status of the recap run
    ## debug_info=$(bash -x "${recap_path}" 2>&1)
    ## stat=$?
    ## 
    ## # Show the info that triggered the cleanup function if there was an error
    ## if [[ ${stat} -ne 0 ]]; then
    ##   echo "An error occurred while doing the following:"
    ##   grep -P "^\+\s+cleanup" -B 20 <<<"${debug_info}"
    ## fi
    ## 
    ## # Return if there was an error
    ## if [[ ${stat} -ne 0 ]]; then
    ##   return ${stat}
    ## fi
    ##
    ## ls -tr /var/log/recap/*log | xargs tail -v -n+0

    disable_plugin ${plugin}
  done
}

# Test each plugin found
test_plugins
exit $?
