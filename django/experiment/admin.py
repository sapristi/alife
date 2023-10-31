from django.contrib import admin
from .models import InitialState, BactSnapshot, Experiment


class InitialStateAdmin(admin.ModelAdmin):
    pass

class BactSnapshotAdmin(admin.ModelAdmin):
    pass

class ExperimentAdmin(admin.ModelAdmin):
    pass

admin.site.register(
    InitialState, InitialStateAdmin
)
admin.site.register(
    BactSnapshot, BactSnapshotAdmin
)
admin.site.register(
    Experiment, ExperimentAdmin
)
