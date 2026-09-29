from django.contrib.gis.forms.widgets import OpenLayersWidget


class CartoOSMWidget(OpenLayersWidget):
    """
    Widget de mapa de GeoDjango que usa CARTO como capa base,
    en vez de la capa por defecto de Django 6 o de los tiles
    públicos de OpenStreetMap (bloqueados por política de uso).
    """
    base_layer = "carto"
    default_lon = -79.2005
    default_lat = -3.9973
    default_zoom = 13

    class Media:
        extend = False
        css = {
            "all": (
                "https://cdn.jsdelivr.net/npm/ol@v7.2.2/ol.css",
                "gis/css/ol3.css",
            )
        }
        js = (
            "https://cdn.jsdelivr.net/npm/ol@v7.2.2/dist/ol.js",
            "gis/js/OLMapWidget.js",
            "gis/js/carto_layer.js",
        )