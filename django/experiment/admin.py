from django.contrib import admin
from .models import InitialState, Dump, Experiment
# Register your models here.


class InitialStateAdmin(admin.ModelAdmin):
    pass

class DumpAdmin(admin.ModelAdmin):
    pass

class ExperimentAdmin(admin.ModelAdmin):
    pass

admin.site.register(
    InitialState, InitialStateAdmin
)
admin.site.register(
    Dump, DumpAdmin
)
admin.site.register(
    Experiment, ExperimentAdmin 
)
