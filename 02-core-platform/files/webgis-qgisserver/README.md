# QGIS Server Docker Image

Please note, that you have to

+ use your own QGIS project file, instead of the file `qgis-sample.conf`.
+ update the line 39 in the file `Dockerfile` accordingly.

```docker
...
COPY qgis-sample.qgs /data/qgis/project.qgs
...
```

**NOTE**
Your QGIS project file **must** be copied into `/data/qgis` with the name `project.qgs`!
