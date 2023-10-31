from django.db import models

class TSModel(models.Model):
    timestamp = models.DateTimeField(auto_now=True)
    class Meta:
        abstract = True


class Experiment(TSModel):
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    # Not using InitialState:
    # - more flexible
    # - wouldn't make sense since computation is deterministic
    # - could use foreign key for bact and env though ???
    initial_state = models.JSONField()


class BactSnapshot(TSModel):
    bact_snapshot = models.JSONField()
    nb_reactions = models.IntegerField()
    experiment = models.ForeignKey(Experiment, on_delete=models.CASCADE)


class InitialState(TSModel):
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)

    seed = models.BigIntegerField(default=0)
    env = models.JSONField()
    molecules = models.JSONField()

    def __str__(self):
        return f"{self.name} [{self.pk}]"
