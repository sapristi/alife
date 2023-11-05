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
from experiment.utils import yaac

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
        res = yaac.run("from-mol", mol=data.get('mol', ''))
        return JsonResponse(
            res, safe=False
        )

class SnapshotSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.BactSnapshot
        fields = ('data', 'nb_reactions', 'timestamp')

class ExperimentSerializer(serializers.ModelSerializer):
    last_snapshot = SnapshotSerializer()
    class Meta:
        model = models.Experiment
        fields = ('id', 'name', 'description', 'last_snapshot')

class ExperimentView(viewsets.ViewSet):
    """Experiment API"""
    authentication_classes = []

    def retrieve(self, request, pk=None):
        exp = models.Experiment.objects.get(pk=pk)
        serializer = ExperimentSerializer(exp)
        return Response(serializer.data)

    @action(detail=False, methods=("POST",))
    def next_state(self, request):
        body = request.body.decode()
        print("RECEIVED", body)
        data = json.loads(body)
        state = data["state"]
        res = yaac.run(
            "eval",
            initial_state=json.dumps(state),
            nb_steps=1,
            use_dump="true"
        )
        print("GOT", res)
        if res is None:
            return JsonResponse({"error": "problem"}, status=401)
        return JsonResponse(
            res, safe=False
        )
