import sys
from django.contrib import admin
from admin_extra_buttons.api import ExtraButtonsMixin, button
from django.db.models import Model
from django.http import HttpResponseRedirect
from django.contrib import admin
from django.urls import reverse
import random
from django.utils.safestring import mark_safe
from .models import InitialState, BactSnapshot, Experiment

def make_admin_redirect_url(obj: Model):
    return reverse(
        f"admin:{obj._meta.app_label}_{obj._meta.model_name}_change", args=(obj.pk,)
    )
class InitialStateAdmin(ExtraButtonsMixin, admin.ModelAdmin):
    list_display = ('id', 'name')

    @button(
        html_attrs={'style': 'background-color:#88FF88;color:black'}
    )
    def create_experiment(self, request, pk):
        initial_state = InitialState.objects.get(pk=pk)
        new_experiment = Experiment(
            initial_state={
                "mols":initial_state.mols,
                "env":initial_state.env
            }
        )
        new_experiment.save()
        self.message_user(request, 'created experiment')
        return HttpResponseRedirect(make_admin_redirect_url(new_experiment))

class BactSnapshotAdmin(admin.ModelAdmin):
    readonly_fields = ["experiment", "nb_reactions", "data"]

class ExperimentAdmin(ExtraButtonsMixin, admin.ModelAdmin):
    list_display = ('id', 'name', 'description')
    readonly_fields = ["snapshots"]

    @button(
        html_attrs={'style': 'background-color:#88FF88;color:black'}
    )
    def duplicate(self, request, pk):
        exp = Experiment.objects.get(pk=pk)
        new_exp = Experiment(
            name=f"{exp.name} - Copy",
            description=exp.description,
            initial_state=exp.initial_state
        )
        new_exp.save()
        return HttpResponseRedirect(make_admin_redirect_url(new_exp))

    @button(
        html_attrs={'style': 'background-color:#88FF88;color:black'}
    )
    def randomize_seed(self, request, pk):
        exp = Experiment.objects.get(pk=pk)
        if "randstate" in exp.initial_state:
            exp.initial_state["randstate"]["seed"] = str(random.randint(-sys.maxsize, sys.maxsize))
        else:
            exp.initial_state["randstate"] =  {
                "seed": str(random.randint(-sys.maxsize, sys.maxsize)), "gamma": "-7046029254386353131"
            }
        exp.save()

        return HttpResponseRedirect(make_admin_redirect_url(exp))

    @admin.display(ordering=None, description='snapshots')
    def snapshots(self, obj: Experiment):
        def format_snapshot(snapshot):
            return f'<li><a href="{make_admin_redirect_url(snapshot)}">{snapshot}</a></li>'

        return mark_safe("<ul>" + "".join(format_snapshot(s) for s in obj.snapshots) + "</ul>")

admin.site.register(
    InitialState, InitialStateAdmin
)
admin.site.register(
    BactSnapshot, BactSnapshotAdmin
)
admin.site.register(
    Experiment, ExperimentAdmin
)
