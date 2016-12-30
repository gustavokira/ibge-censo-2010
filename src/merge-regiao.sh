#!/bin/bash

REGIAO=$1

touch ${REGIAO}_setor_valores.geo.ndjson
touch ${REGIAO}_subdistrito_valores.geo.ndjson
touch ${REGIAO}_estado_silhueta.geo.ndjson
touch ${REGIAO}_subdistrito_linhas.geo.njson

case $REGIAO in
	SUL)      
		ESTADOS=(PR SC RS)
		;;
	SUDESTE)	
		ESTADOS=(ES SP RJ MG)
		;;
	CENTROOESTE)
		ESTADOS=(DF GO MT MS)
		;;
	NORTE)
		ESTADOS=(AC AP AM PA RO RR TO)
		;;
	NORDESTE)
		ESTADOS=(AL BA CE MA PB PE PI RN SE)
esac

for i in "${ESTADOS[@]}"
do
	echo "processando estado ${i}"
	topo2geo color=${i}_setor_valores.geo.json \
		< ${i}_setor_valores.topo.json

	topo2geo color=${i}_subdistrito_valores.geo.json \
		< ${i}_subdistrito_valores.topo.json
	
	topo2geo setor=${i}_estado_silhueta.geo.json \
		< ${i}_estado_silhueta.topo.json

	topo2geo subdistrito=${i}_subdistrito_linhas.geo.json \
		< ${i}_subdistrito_linhas.topo.json
	
	#tranforma geo para ndjson PR
	ndjson-split 'd.features' \
		< ${i}_setor_valores.geo.json \
		> ${i}_setor_valores.geo.ndjson

	ndjson-split 'd.features' \
		< ${i}_subdistrito_valores.geo.json \
		> ${i}_subdistrito_valores.geo.ndjson

	ndjson-split 'd.features' \
		< ${i}_estado_silhueta.geo.json \
		> ${i}_estado_silhueta.geo.ndjson

	ndjson-split 'd.features' \
		< ${i}_subdistrito_linhas.geo.json \
		> ${i}_subdistrito_linhas.geo.ndjson

	#remove primeiro geo
	rm 	${i}_setor_valores.geo.json \
		${i}_subdistrito_valores.geo.json \
		${i}_estado_silhueta.geo.json \
		${i}_subdistrito_linhas.geo.json

	cat ${i}_setor_valores.geo.ndjson >> ${REGIAO}_setor_valores.geo.ndjson
	rm ${i}_setor_valores.geo.ndjson

	cat ${i}_subdistrito_valores.geo.ndjson >> ${REGIAO}_subdistrito_valores.geo.ndjson
	rm ${i}_subdistrito_valores.geo.ndjson

	cat ${i}_estado_silhueta.geo.ndjson >> ${REGIAO}_estado_silhueta.geo.ndjson
	rm ${i}_estado_silhueta.geo.ndjson

	cat ${i}_subdistrito_linhas.geo.ndjson >> ${REGIAO}_subdistrito_linhas.geo.ndjson
	rm ${i}_subdistrito_linhas.geo.ndjson
	
done

echo "coloca denovo os valores no geo"
ndjson-reduce < ${REGIAO}_setor_valores.geo.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> ${REGIAO}_setor_valores.geo.json

ndjson-reduce < ${REGIAO}_subdistrito_valores.geo.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> ${REGIAO}_subdistrito_valores.geo.json	

ndjson-reduce < ${REGIAO}_estado_silhueta.geo.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> ${REGIAO}_estado_silhueta.geo.json

ndjson-reduce < ${REGIAO}_subdistrito_linhas.geo.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> ${REGIAO}_subdistrito_linhas.geo.json

#remove ndjson
rm 	${REGIAO}_setor_valores.geo.ndjson \
	${REGIAO}_subdistrito_valores.geo.ndjson \
	${REGIAO}_estado_silhueta.geo.ndjson \
	${REGIAO}_subdistrito_linhas.geo.ndjson \

geo2topo color=${REGIAO}_setor_valores.geo.json > ${REGIAO}_setor.topo.json
toposimplify -S 0.1 -f < ${REGIAO}_setor.topo.json > ${REGIAO}_setor_simple.topo.json
topoquantize 1e5 ${REGIAO}_setor_simple.topo.json > ${REGIAO}_setor_valores.topo.json

rm 	${REGIAO}_setor.topo.json \
	${REGIAO}_setor_simple.topo.json \
	${REGIAO}_setor_valores.geo.json

geo2topo color=${REGIAO}_subdistrito_valores.geo.json > ${REGIAO}_subdistrito.topo.json
toposimplify -S 0.1 -f < ${REGIAO}_subdistrito.topo.json > ${REGIAO}_subdistrito_simple.topo.json
topoquantize 1e5 ${REGIAO}_subdistrito_simple.topo.json > ${REGIAO}_subdistrito_valores.topo.json

rm 	${REGIAO}_subdistrito.topo.json \
	${REGIAO}_subdistrito_simple.topo.json \
	${REGIAO}_subdistrito_valores.geo.json	

geo2topo setor=${REGIAO}_estado_silhueta.geo.json > ${REGIAO}_estado_setor.topo.json
topomerge setor=setor < ${REGIAO}_estado_setor.topo.json > ${REGIAO}_estado_merged.topo.json
toposimplify -S 0.1 -f < ${REGIAO}_estado_merged.topo.json > ${REGIAO}_estado_simple.topo.json
topoquantize 1e5 ${REGIAO}_estado_simple.topo.json > ${REGIAO}_estado_silhueta.topo.json

rm 	${REGIAO}_estado_silhueta.geo.json \
	${REGIAO}_estado_setor.topo.json \
	${REGIAO}_estado_merged.topo.json \
	${REGIAO}_estado_simple.topo.json

geo2topo subdistrito=${REGIAO}_subdistrito_linhas.geo.json > ${REGIAO}_subdistrito_init.topo.json
topomerge --mesh -f 'a !== b' subdistrito=subdistrito < ${REGIAO}_subdistrito_init.topo.json > ${REGIAO}_subdistrito_mesh.topo.json
toposimplify -S 0.1 -f < ${REGIAO}_subdistrito_mesh.topo.json > ${REGIAO}_subdistrito_quant.topo.json
topoquantize 1e5 ${REGIAO}_subdistrito_quant.topo.json > ${REGIAO}_subdistrito_linhas.topo.json

rm 	${REGIAO}_subdistrito_linhas.geo.json \
	${REGIAO}_subdistrito_init.topo.json \
	${REGIAO}_subdistrito_mesh.topo.json \
	${REGIAO}_subdistrito_quant.topo.json