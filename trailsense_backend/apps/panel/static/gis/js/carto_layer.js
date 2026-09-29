MapWidget.layerBuilder.carto = function () {
    const cartoKey = window.CARTO_API_KEY || '';
    const tileUrl = cartoKey
        ? `https://{1-4}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${cartoKey}`
        : `https://{1-4}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png`;

    return new ol.layer.Tile({
        source: new ol.source.XYZ({
            url: tileUrl,
            attributions: '&copy; OpenStreetMap contributors &copy; CARTO'
        })
    });
};