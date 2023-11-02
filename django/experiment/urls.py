from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views


router = DefaultRouter()
router.register(r'pages', views.PagesViewSet, basename='pages')
router.register(r'experiment', views.ExperimentView, basename='experiment')


urlpatterns = [
    path("", views.home),
    path("mol/", views.MoleculeView.as_view()),
    *router.urls
]
