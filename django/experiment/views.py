import json
from django.http import HttpResponse, JsonResponse
import subprocess as sp
import json

from django.template import loader
from django.views.generic import View
from rest_framework import viewsets, serializers
from rest_framework.decorators import action
from rest_framework.response import Response

from . import models

def home(request):
    """Home page"""
    template = loader.get_template("home.html")
    return HttpResponse(
        template.render()
    )

class PagesViewSet(viewsets.ViewSet):
    """Other pages"""
    @action(detail=False)
    def molecule(self, *args, **kwargs):
        template = loader.get_template("bacterie_view.html")
        return HttpResponse(
            template.render()
        )

    @action(detail=False)
    def experiment(self,*args, **kwargs):
        template = loader.get_template("experiment_view.html")
        return HttpResponse(
            template.render(
                context={"experiments": models.Experiment.objects.all()}
            )
        )


class MoleculeView(View):

    def get(self, *args, **kwargs):
        template = loader.get_template("bacterie_view.html")
        return HttpResponse(
            template.render()
        )

    def post(self, request, *args, **kwargs):
        data = json.loads(request.body)
        p = sp.run(
            ["./yaac", "from-mol", f"--mol={data.get('mol', '')}"],
            capture_output=True
        )
        res = json.loads(p.stdout)
        print(res)
        return JsonResponse(
            res, safe=False
        )

class SnapshotSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.BactSnapshot
        fields = ('data', 'nb_reactions')

class ExperimentSerializer(serializers.ModelSerializer):
    last_snapshot = SnapshotSerializer()
    class Meta:
        model = models.Experiment
        fields = ('id', 'name', 'description', 'last_snapshot')

class ExperimentView(viewsets.ViewSet):
    """Experiment API"""
    def retrieve(self, request, pk=None):
        exp = models.Experiment.objects.get(pk=pk)
        serializer = ExperimentSerializer(exp)
        return Response(serializer.data)
