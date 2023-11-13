from django.db import models

class TSModel(models.Model):
    timestamp = models.DateTimeField(auto_now=True)
    class Meta:
        abstract = True


class Experiment(TSModel):
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    # Not using foreign key to InitialState:
    # - more flexible
    # - wouldn't make sense since computation is deterministic
    # - could use foreign key for bact and env though ???
    initial_state = models.JSONField()

    @property
    def snapshots(self):
        return BactSnapshot.objects.filter(experiment=self)

    @property
    def last_snapshot(self):
        return self.snapshots.last()

class Log(models.Model):
    experiment = models.ForeignKey(Experiment, on_delete=models.CASCADE)
    data = models.JSONField()

class BactSnapshot(TSModel):
    experiment = models.ForeignKey(Experiment, on_delete=models.CASCADE)
    data = models.JSONField()
    nb_reactions = models.IntegerField()


class InitialState(TSModel):
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)

    seed = models.BigIntegerField(default=0)
    env = models.JSONField()
    mols = models.JSONField()

    def __str__(self):
        return f"{self.name} [{self.pk}]"
