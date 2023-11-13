# Generated by Django 4.2.7 on 2023-11-13 21:23

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('experiment', '0002_rename_bact_snapshot_bactsnapshot_data'),
    ]

    operations = [
        migrations.CreateModel(
            name='Log',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('data', models.JSONField()),
                ('experiment', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='experiment.experiment')),
            ],
        ),
    ]
