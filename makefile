STATE = AC
REPO=estados

AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR RJ RN RO RR RS SC SE SP TO:
	$(eval STATE=$@)
	# $@ $(STATE)


clear: reset createSubDistritoLines createSetor
	rm $(STATE)_*.dbf
	rm $(STATE)_*.ndjson
	rm $(STATE)_*.prj
	rm $(STATE)_*.shp
	rm $(STATE)_*.shx
	rm $(STATE)_*.geo.json
	rm $(STATE)_estado_setor.topo.json
	rm $(STATE)_setor.topo.json
	rm $(STATE)_subdistrito_init.topo.json
	rm $(STATE)_*_simple.topo.json
	rm $(STATE)_estado_merged.topo.json
	rm $(STATE)_*_mesh.topo.json
	rm $(STATE)_subdistrito.topo.json
	rm $(STATE)_subdistrito_quant.topo.json
	rm -r $(STATE)

createSubDistritoLines: toTopoGeo

	geo2topo setor=$(STATE)_setor.geo.json > $(STATE)_estado_setor.topo.json
	topomerge setor=setor < $(STATE)_estado_setor.topo.json > $(STATE)_estado_merged.topo.json
	toposimplify -S 0.1 -f < $(STATE)_estado_merged.topo.json > $(STATE)_estado_simple.topo.json
	topoquantize 1e5 $(STATE)_estado_simple.topo.json > $(STATE)_estado_silhueta.topo.json

	geo2topo subdistrito=$(STATE)_subdistrito.geo.json > $(STATE)_subdistrito_init.topo.json
	topomerge --mesh -f 'a !== b' subdistrito=subdistrito < $(STATE)_subdistrito_init.topo.json > $(STATE)_subdistrito_mesh.topo.json
	toposimplify -S 0.1 -f < $(STATE)_subdistrito_mesh.topo.json > $(STATE)_subdistrito_quant.topo.json
	topoquantize 1e5 $(STATE)_subdistrito_quant.topo.json > $(STATE)_subdistrito_linhas.topo.json
	
createSetor: toTopoGeo

	node face-geo-group-by-setor.js \
	$(STATE)_face.geo.json \
	> $(STATE)_setor_with_pop.ndjson

	node face-geo-group-by-subdistrito \
	$(STATE)_face.geo.json \
	> $(STATE)_subdistrito_with_pop.ndjson
	
	tr -d '\n' < $(STATE)_setor.geo.json > $(STATE)_setor_newlineless.geo.json
	tr -d '\n' < $(STATE)_subdistrito.geo.json > $(STATE)_subdistrito_newlineless.geo.json

	ndjson-split 'd.features' \
	< $(STATE)_setor_newlineless.geo.json \
	> $(STATE)_setor.ndjson

	ndjson-map 'd.setor= d.properties.CD_GEOCODI,d' \
	< $(STATE)_setor.ndjson \
	> $(STATE)_setor_renamed.ndjson

	rm $(STATE)_setor.ndjson
	mv $(STATE)_setor_renamed.ndjson $(STATE)_setor.ndjson

	ndjson-split 'd.features' \
	< $(STATE)_subdistrito_newlineless.geo.json \
	> $(STATE)_subdistrito.ndjson

	ndjson-map 'd.subdistrito= d.properties.CD_GEOCODS,d' \
	< $(STATE)_subdistrito.ndjson \
	> $(STATE)_subdistrito_renamed.ndjson

	rm $(STATE)_subdistrito.ndjson
	mv $(STATE)_subdistrito_renamed.ndjson $(STATE)_subdistrito.ndjson

	node area.js CD_GEOCODI setor $(STATE)_setor.ndjson > $(STATE)_setor_with_area.ndjson
	node area.js CD_GEOCODS subdistrito $(STATE)_subdistrito.ndjson > $(STATE)_subdistrito_with_area.ndjson

	ndjson-join 'd.setor' \
	$(STATE)_setor_with_pop.ndjson \
	$(STATE)_setor_with_area.ndjson \
	> $(STATE)_setor_with_area_pop.ndjson

	ndjson-map 'd[1].properties = {setor: d[0].setor, population: d[0].population, area:d[1].area}' \
	< $(STATE)_setor_with_area_pop.ndjson \
	> $(STATE)_setor_with_area_pop_2.ndjson

	rm $(STATE)_setor_with_area_pop.ndjson
	mv $(STATE)_setor_with_area_pop_2.ndjson $(STATE)_setor_with_area_pop.ndjson

	ndjson-join 'd.subdistrito' \
	$(STATE)_subdistrito_with_pop.ndjson \
	$(STATE)_subdistrito_with_area.ndjson \
	> $(STATE)_subdistrito_with_area_pop.ndjson

	ndjson-map 'd[1].properties = {subdistrito: d[0].subdistrito, population: d[0].population, area:d[1].area}' \
	< $(STATE)_subdistrito_with_area_pop.ndjson \
	> $(STATE)_subdistrito_with_area_pop_2.ndjson

	rm $(STATE)_subdistrito_with_area_pop.ndjson
	mv $(STATE)_subdistrito_with_area_pop_2.ndjson $(STATE)_subdistrito_with_area_pop.ndjson

	ndjson-join 'd.setor' \
	$(STATE)_setor.ndjson \
	$(STATE)_setor_with_area_pop.ndjson \
	> $(STATE)_setor_with_area_pop_geometry.ndjson

	ndjson-map 'd[0].properties = {population: d[1].population, area:d[1].area, density: d[1].population/d[1].area}, d[0]' \
	< $(STATE)_setor_with_area_pop_geometry.ndjson \
	> $(STATE)_setor_final.ndjson

	ndjson-reduce < $(STATE)_setor_final.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> $(STATE)_setor_final.geo.json

	ndjson-join 'd.subdistrito' \
	$(STATE)_subdistrito.ndjson \
	$(STATE)_subdistrito_with_area_pop.ndjson \
	> $(STATE)_subdistrito_with_area_pop_geometry.ndjson

	ndjson-map 'd[0].properties = {population: d[1].population, area:d[1].area, density: d[1].population/d[1].area}, d[0]' \
	< $(STATE)_subdistrito_with_area_pop_geometry.ndjson \
	> $(STATE)_subdistrito_final.ndjson

	ndjson-reduce < $(STATE)_subdistrito_final.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> $(STATE)_subdistrito_final.geo.json

	geo2topo color=$(STATE)_setor_final.geo.json > $(STATE)_setor.topo.json
	toposimplify -S 0.1 -f < $(STATE)_setor.topo.json > $(STATE)_setor_simple.topo.json
	topoquantize 1e5 $(STATE)_setor_simple.topo.json > $(STATE)_setor_valores.topo.json

	geo2topo color=$(STATE)_subdistrito_final.geo.json > $(STATE)_subdistrito.topo.json
	toposimplify -S 0.1 -f < $(STATE)_subdistrito.topo.json > $(STATE)_subdistrito_simple.topo.json
	topoquantize 1e5 $(STATE)_subdistrito_simple.topo.json > $(STATE)_subdistrito_valores.topo.json

reset:
	# rm $(STATE)_*

toTopoGeo: merge
	ogr2ogr -sql "select CD_GEOCODI,CD_GEOCODS from $(STATE)_setor" -f "GeoJSON" -t_srs crs:84 $(STATE)_setor.geo.json $(STATE)_setor.shp
	ogr2ogr -sql "select CD_GEO, TOT_GERAL from $(STATE)_face" -f "GeoJSON" -t_srs crs:84 $(STATE)_face.geo.json $(STATE)_face.shp
	ogr2ogr -sql "select CD_GEOCODS from $(STATE)_subdistrito" -f "GeoJSON" -t_srs crs:84 $(STATE)_subdistrito.geo.json $(STATE)_subdistrito.shp

merge: copy 
	$(foreach f,$(shell ls $(STATE)/*_setor.shp), ogr2ogr -append -update $(STATE)_setor.shp $(f) -f "Esri Shapefile" ;)
	
	$(foreach f,$(shell ls $(STATE)/*_face.shp), ogr2ogr -append -update $(STATE)_face.shp $(f) -f "Esri Shapefile" ;)
	
	$(foreach f,$(shell ls $(STATE)/*_subdistrito.shp), ogr2ogr -append -update $(STATE)_subdistrito.shp $(f) -f "Esri Shapefile" ;)

copy: download
	cp -r geoftp.ibge.gov.br/recortes_para_fins_estatisticos/malha_de_setores_censitarios/censo_2010/base_de_faces_de_logradouros/$(STATE)/ $(STATE)
	unzip $(STATE)/\*.zip -d $(STATE)
	chmod -R 777 $(STATE)
	rm -r $(STATE)/*.zip

download:
	# wget -r ftp://geoftp.ibge.gov.br/recortes_para_fins_estatisticos/malha_de_setores_censitarios/censo_2010/base_de_faces_de_logradouros/$(STATE)/
