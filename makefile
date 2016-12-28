STATE = RS
WIDTH = 420
HEIGHT = 420
clear: reset run
	rm $(STATE)_*.dbf
	rm $(STATE)_*.ndjson
	rm $(STATE)_*.prj
	rm $(STATE)_*.shp
	rm $(STATE)_*.shx
	rm $(STATE)_*.geo.json
	rm $(STATE)_*_simple.topo.json
	rm $(STATE)_face.topo.json
	rm $(STATE)_*_transformed.topo.json
	rm $(STATE)_subdistrito_quant.topo.json
	rm -r $(STATE)

run: transform
	geoproject 'd3.geoMercator().rotate([0, 0]).fitSize([$(WIDTH), $(HEIGHT)], d)' < $(STATE)_face.geo.json > $(STATE)_face_transformed.geo.json
	geoproject 'd3.geoMercator().rotate([0, 0]).fitSize([$(WIDTH), $(HEIGHT)], d)' < $(STATE)_setor.geo.json > $(STATE)_setor_transformed.geo.json
	geoproject 'd3.geoMercator().rotate([0, 0]).fitSize([$(WIDTH), $(HEIGHT)], d)' < $(STATE)_subdistrito.geo.json > $(STATE)_subdistrito_transformed.geo.json

	ndjson-split 'd.features' \
	< $(STATE)_face_transformed.geo.json \
	> $(STATE)_face.ndjson

	ndjson-split 'd.features' \
  	< $(STATE)_setor_transformed.geo.json \
  	> $(STATE)_setor.ndjson

	ndjson-map 'd.properties = {setor: d.properties.CD_SETOR, population: d.properties.TOT_GERAL},d' \
	< $(STATE)_face.ndjson \
	> $(STATE)_face_pop.ndjson

	ndjson-map 'd.setor= d.properties.CD_GEOCODI,d' \
	< $(STATE)_setor.ndjson \
	> $(STATE)_setor_clean.ndjson

	node group-by.js $(STATE)_face_pop.ndjson > $(STATE)_setor_with_pop.ndjson
	node area.js $(STATE)_setor.ndjson > $(STATE)_setor_area.ndjson

	ndjson-join 'd.setor' \
	$(STATE)_setor_with_pop.ndjson \
	$(STATE)_setor_area.ndjson \
	> $(STATE)_setor_joinA.ndjson

	ndjson-map 'd[1].properties = {setor: d[0].setor, population: d[0].population, area:d[1].area}' \
	< $(STATE)_setor_joinA.ndjson \
	> $(STATE)_setor_joinB.ndjson

	ndjson-join 'd.setor' \
	$(STATE)_setor_clean.ndjson \
	$(STATE)_setor_joinB.ndjson \
	> $(STATE)_setor_join.ndjson

	ndjson-map 'd[0].properties = {population: d[1].population, area:d[1].area, density: d[1].population/d[1].area}, d[0]' \
	< $(STATE)_setor_join.ndjson \
	> $(STATE)_setor_pop.ndjson

	ndjson-reduce < $(STATE)_setor_pop.ndjson \
	| ndjson-map '{type: "FeatureCollection", features: d}' \
	> $(STATE)_setor_color.geo.json

	geo2topo color=$(STATE)_setor_color.geo.json > $(STATE)_setor_color.topo.json
	toposimplify -p 1 -f < $(STATE)_setor_color.topo.json > $(STATE)_setor_color_simple.topo.json
	topoquantize 1e5 $(STATE)_setor_color_simple.topo.json > $(STATE)_setor_color.topo.json
	
	geo2topo setor=$(STATE)_setor_transformed.geo.json > $(STATE)_setor_transformed.topo.json
	toposimplify -p 1 -f < $(STATE)_setor_transformed.topo.json > $(STATE)_setor_simple.topo.json
	topoquantize 1e5 $(STATE)_setor_simple.topo.json > $(STATE)_setor.topo.json

	geo2topo subdistrito=$(STATE)_subdistrito_transformed.geo.json > $(STATE)_subdistrito_transformed.topo.json
	toposimplify -p 1 -f < $(STATE)_subdistrito_transformed.topo.json > $(STATE)_subdistrito_simple.topo.json
	topoquantize 1e5 $(STATE)_subdistrito_simple.topo.json > $(STATE)_subdistrito_quant.topo.json
	topomerge --mesh -f 'a !== b' subdistrito=subdistrito < $(STATE)_subdistrito_quant.topo.json > $(STATE)_subdistrito.topo.json
	topomerge --mesh -f 'a == b' subdistrito=subdistrito < $(STATE)_subdistrito_quant.topo.json > $(STATE)_subdistrito.back.topo.json

reset:
	# rm $(STATE)_*

transform: merge
	ogr2ogr -f "GeoJSON" -t_srs crs:84 $(STATE)_setor.geo.json $(STATE)_setor.shp

	ogr2ogr -sql "select CD_SETOR, TOT_GERAL from $(STATE)_face" -f "GeoJSON" -t_srs crs:84 $(STATE)_face.geo.json $(STATE)_face.shp
	geo2topo face=$(STATE)_face.geo.json > $(STATE)_face.topo.json
	toposimplify -p 1 -f < $(STATE)_face.topo.json > $(STATE)_face_simple.topo.json
	topoquantize 1e5 $(STATE)_face_simple.topo.json > $(STATE)_face.topo.json
	topo2geo face=$(STATE)_face.geo.json < $(STATE)_face.topo.json
	
	ogr2ogr  -f "GeoJSON" -t_srs crs:84 $(STATE)_subdistrito.geo.json $(STATE)_subdistrito.shp
	
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