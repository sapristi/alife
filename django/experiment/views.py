from os import truncate
import json
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render
from django.template import loader
from django.views.generic import View
import subprocess as sp
import json

class Molecule(View):

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
