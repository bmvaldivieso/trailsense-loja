from django.conf import settings


def carto_api_key(request):
    return {"CARTO_BASEMAPS_API_KEY": settings.CARTO_BASEMAPS_API_KEY}