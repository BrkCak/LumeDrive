from ultralytics import YOLO

# Durchlaufe alle YOLOv8-Größen (n, s, m, l, x)
for size in ("n", "s", "m", "l", "x"):
    # Lade das YOLOv8 PyTorch-Modell
    model = YOLO(f"yolov8{size}.pt")

    # Exportiere das PyTorch-Modell ins CoreML INT8-Format mit NMS-Schichten
    model.export(format="coreml", int8=True, nms=True, imgsz=[640, 384])
