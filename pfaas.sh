#!/bin/bash

PFAAS_PORT=1805
PFAAS_PIPE="PFAAS"
PFAAS_FACTS="facts"


[[ -p "${PFAAS_PIPE}" ]] && rm "${PFAAS_PIPE}"
mkfifo "${PFAAS_PIPE}"
trap "{
        rm -f ${PFAAS_PIPE}
        echo ' listen no more \o/'
        exit
      }" 1 2 15

FACTS=()
IFS=,$'\n' read -d '' -a FACTS < ${PFAAS_FACTS}


return_random_fact() {
  id=$RANDOM
  let "id %= ${#FACTS[@]}"
  fact="${FACTS[${id}]}"

  echo "{\"id\": \"${id}\", \"fact\": \"${fact}\"}" > "${PFAAS_PIPE}"
}

return_specific_fact() {
  [[ "${FACTS[${1}]}" == "" ]] && return_random_fact || echo "{\"id\": \"${1}\", \"fact\": \"${FACTS[${1}]}\"}" > "${PFAAS_PIPE}" > "${PFAAS_PIPE}"
}

return_404() {
  echo -e "HTTP/1.1 404 Not Found\n\n404" > "${PFAAS_PIPE}"
}


while true; do
  cat "${PFAAS_PIPE}" | nc -lv ${PFAAS_PORT} > >(
    while read l; do
      l=$(echo "$l" | tr -d '[\r\n]')

      if echo "$l" | grep -qE '^GET /'; then
        req=$(echo "$l" | cut -d ' ' -f2)
        if echo $req | grep -qE '^/api/fact'; then

          id=$(echo $(echo $req | awk -F "/" '{print $NF}' | tr -cd [:digit:]))
          [[ ${id} != "" ]] && return_specific_fact ${id} || return_random_fact


        else
          return_404

        fi
      fi
    done
  )

done
