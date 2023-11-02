from django.contrib import admin
from admin_extra_buttons.api import ExtraButtonsMixin, button
from admin_extra_buttons.utils import HttpResponseRedirectToReferrer
from django.db.models import Model
from django.http import HttpResponseRedirect
from django.contrib import admin
from django.urls import reverse


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
    pass

class BactSnapshotAdmin(admin.ModelAdmin):
    pass

class ExperimentAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'description')
 
admin.site.register(
    InitialState, InitialStateAdmin
)
admin.site.register(
    BactSnapshot, BactSnapshotAdmin
)
admin.site.register(
    Experiment, ExperimentAdmin
)
