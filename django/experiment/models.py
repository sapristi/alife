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
        return BactSnapshot.objects.filter(experiment=self).values("id", "nb_reactions")

    @property
    def last_snapshot(self):
        return self.snapshots.last()

    def __repr__(self):
        return f"EXP: {self.name}[{self.id}]"

class Log(models.Model):
    experiment = models.ForeignKey(Experiment, on_delete=models.CASCADE)
    reac_count = models.BigIntegerField()
    data = models.JSONField()

class BactSnapshot(TSModel):
    experiment = models.ForeignKey(Experiment, on_delete=models.CASCADE)
    data = models.JSONField()
    nb_reactions = models.IntegerField()

    def __str__(self):
        return f"Snapshot for {self.experiment.name}[{self.experiment.id}] - {self.nb_reactions} reacs"

    def save(self):
        if self.nb_reactions is None:
            self.nb_reactions = self.data["reac_counter"]
        super().save()

class InitialState(TSModel):
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)

    seed = models.BigIntegerField(default=0)
    env = models.JSONField()
    mols = models.JSONField()

    def __str__(self):
        return f"{self.name} [{self.pk}]"
