from django.urls import path

from . import views

app_name = "polls"
urlpatterns = [
    path("", views.home),
    path("mol/", views.Molecule.as_view()),
]
