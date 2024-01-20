from django.urls import path
from rest_framework.routers import SimpleRouter

from . import views


router = SimpleRouter()
router.register(r'pages', views.PagesViewSet, basename='pages')
router.register(r'experiment', views.ExperimentView, basename='experiment')
router.register(r'snapshot', views.SnapshotView, basename='snapshot')


urlpatterns = [
    path("", views.home),
    path("mol/", views.MoleculeView.as_view()),
    path('dnd/', views.DnDView.as_view()),
    *router.urls
]
